import '../data/database.dart';
import 'dates.dart';

/// Priority (red, orange, green), then due time, untimed last.
int compareByPriorityThenTime(Task a, Task b) {
  final p = a.priority.index.compareTo(b.priority.index);
  if (p != 0) return p;
  return _compareNullableLast(a.dueTime, b.dueTime);
}

/// Priority, then due date, then due time. Undated and untimed last.
int compareByPriorityThenDate(Task a, Task b) {
  final p = a.priority.index.compareTo(b.priority.index);
  if (p != 0) return p;
  final d = _compareNullableLast(a.dueDate, b.dueDate);
  if (d != 0) return d;
  return _compareNullableLast(a.dueTime, b.dueTime);
}

int _compareNullableLast<T extends Comparable<Object>>(T? a, T? b) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  return a.compareTo(b);
}

class TodaySections {
  TodaySections(this.overdue, this.today, this.doneToday);
  final List<TaskWithProject> overdue;
  final List<TaskWithProject> today;
  final List<TaskWithProject> doneToday;

  int get leftToday => today.length;
}

TodaySections buildTodaySections(List<TaskWithProject> rows, DateTime now) {
  final day = dateOnly(now);
  final overdue = <TaskWithProject>[];
  final today = <TaskWithProject>[];
  final done = <TaskWithProject>[];
  for (final r in rows) {
    final t = r.task;
    if (t.done) {
      if (t.doneAt != null && sameDay(t.doneAt!, day)) done.add(r);
      continue;
    }
    final due = t.dueDate;
    if (due == null) continue;
    if (dateOnly(due).isBefore(day)) {
      overdue.add(r);
    } else if (sameDay(due, day)) {
      today.add(r);
    }
  }
  int cmp(TaskWithProject a, TaskWithProject b) =>
      compareByPriorityThenTime(a.task, b.task);
  overdue.sort(cmp);
  today.sort(cmp);
  done.sort(cmp);
  return TodaySections(overdue, today, done);
}

/// Tasks due on a day other than today: still open, and done.
class DaySections {
  DaySections(this.open, this.done);
  final List<TaskWithProject> open;
  final List<TaskWithProject> done;
}

DaySections buildDaySections(List<TaskWithProject> rows, DateTime day) {
  final open = <TaskWithProject>[];
  final done = <TaskWithProject>[];
  for (final r in rows) {
    final due = r.task.dueDate;
    if (due == null || !sameDay(due, day)) continue;
    (r.task.done ? done : open).add(r);
  }
  int cmp(TaskWithProject a, TaskWithProject b) =>
      compareByPriorityThenTime(a.task, b.task);
  open.sort(cmp);
  done.sort(cmp);
  return DaySections(open, done);
}

/// Late tasks for one past day.
class LateDay {
  LateDay(this.day, this.tasks);
  final DateTime day;
  final List<TaskWithProject> tasks;
}

/// Groups undone past tasks by due day, most recent day first.
/// Within a day: priority, then time.
List<LateDay> groupLateTasks(List<TaskWithProject> rows, DateTime now) {
  final today = dateOnly(now);
  final byDay = <DateTime, List<TaskWithProject>>{};
  for (final r in rows) {
    final due = r.task.dueDate;
    if (r.task.done || due == null || !dateOnly(due).isBefore(today)) continue;
    byDay.putIfAbsent(dateOnly(due), () => []).add(r);
  }
  final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
  return [
    for (final d in days)
      LateDay(
        d,
        byDay[d]!..sort((a, b) => compareByPriorityThenTime(a.task, b.task)),
      ),
  ];
}
