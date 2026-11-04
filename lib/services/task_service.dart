import 'package:drift/drift.dart';

import '../data/database.dart';
import '../logic/recurrence.dart';
import 'alarms.dart';

/// Task changes that also keep alarms in step.
class TaskService {
  TaskService(this.db, this.alarms, {DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  final AppDatabase db;
  final AlarmScheduler alarms;
  final DateTime Function() _now;

  Future<String?> _projectName(int? projectId) async =>
      projectId == null ? null : (await db.getProject(projectId))?.name;

  /// Removes fields that are not allowed together, per the spec.
  Task normalise(Task t) {
    var out = t;
    if (out.dueDate == null) {
      out = out.copyWith(
        dueTime: const Value(null),
        recurrence: Recurrence.none,
        recurrenceDay: const Value(null),
      );
    }
    if (out.dueDate == null || out.dueTime == null) {
      out = out.copyWith(alarm: false);
    }
    if (out.recurrence == Recurrence.monthly) {
      out = out.copyWith(
        recurrenceDay: Value(out.recurrenceDay ?? out.dueDate!.day),
      );
    } else {
      out = out.copyWith(recurrenceDay: const Value(null));
    }
    return out;
  }

  /// Inserts a new task. [draft.id] is ignored.
  Future<Task> create(Task draft) async {
    final t = normalise(draft);
    final id = await db.insertTask(
      t.toCompanion(false).copyWith(id: const Value.absent()),
    );
    final saved = (await db.getTask(id))!;
    await alarms.scheduleFor(
      saved,
      projectName: await _projectName(saved.projectId),
    );
    return saved;
  }

  Future<Task> save(Task task) async {
    final t = normalise(task);
    await db.updateTask(t);
    await alarms.scheduleFor(t, projectName: await _projectName(t.projectId));
    return t;
  }

  /// Moves a task to [date] at [minutes] after midnight (null = no time).
  /// The alarm moves with it. A monthly task repeats on the new day.
  Future<Task> reschedule(Task task, DateTime date, int? minutes) {
    final sameDate =
        task.dueDate != null &&
        task.dueDate!.year == date.year &&
        task.dueDate!.month == date.month &&
        task.dueDate!.day == date.day;
    return save(
      task.copyWith(
        dueDate: Value(DateTime(date.year, date.month, date.day)),
        dueTime: Value(minutes),
        recurrenceDay: sameDate ? Value(task.recurrenceDay) : const Value(null),
      ),
    );
  }

  Future<void> delete(int taskId) async {
    await alarms.cancelFor(taskId);
    await db.deleteTask(taskId);
  }

  /// Marks a task done. For a recurring task this also creates the next
  /// instance and schedules its alarm. Returns the next instance, if any.
  Future<Task?> complete(Task task) async {
    final now = _now();
    final doneTask = task.copyWith(done: true, doneAt: Value(now));
    await alarms.cancelFor(task.id);
    Task? next;
    await db.transaction(() async {
      await db.updateTask(doneTask);
      if (task.recurrence != Recurrence.none && task.dueDate != null) {
        final due = nextDueDate(
          task.dueDate!,
          task.recurrence,
          today: now,
          monthDay: task.recurrenceDay,
        );
        final id = await db.insertTask(
          TasksCompanion.insert(
            projectId: Value(task.projectId),
            title: task.title,
            notes: Value(task.notes),
            priority: Value(task.priority),
            dueDate: Value(due),
            dueTime: Value(task.dueTime),
            alarm: Value(task.alarm),
            recurrence: Value(task.recurrence),
            recurrenceDay: Value(task.recurrenceDay),
            createdAt: Value(now),
          ),
        );
        next = await db.getTask(id);
      }
    });
    if (next != null) {
      await alarms.scheduleFor(
        next!,
        projectName: await _projectName(next!.projectId),
      );
    }
    return next;
  }

  /// Undoes a completion. A next instance already created is kept.
  Future<void> uncomplete(Task task) async {
    final t = task.copyWith(done: false, doneAt: const Value(null));
    await db.updateTask(t);
    await alarms.scheduleFor(t, projectName: await _projectName(t.projectId));
  }

  Future<void> snooze(int taskId) async {
    final t = await db.getTask(taskId);
    if (t == null || t.done) return;
    await alarms.snooze(t, projectName: await _projectName(t.projectId));
  }

  Future<void> completeById(int taskId) async {
    final t = await db.getTask(taskId);
    if (t == null || t.done) return;
    await complete(t);
  }

  /// Archiving hides a project's tasks, so their alarms are cancelled.
  Future<void> setProjectArchived(int projectId, bool archived) async {
    await db.setProjectArchived(projectId, archived);
    await alarms.rescheduleAll(db);
  }

  Future<void> deleteProject(int projectId, {required bool deleteTasks}) async {
    final removed = await db.deleteProject(projectId, deleteTasks: deleteTasks);
    for (final id in removed) {
      await alarms.cancelFor(id);
    }
    await alarms.rescheduleAll(db);
  }
}
