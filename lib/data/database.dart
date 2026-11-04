import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../logic/dates.dart';
import 'enums.dart';

export 'enums.dart';

part 'database.g.dart';

class Projects extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get projectId => integer().nullable().references(Projects, #id)();
  TextColumn get title => text()();
  TextColumn get notes => text().withDefault(const Constant(''))();
  IntColumn get priority =>
      intEnum<Priority>().withDefault(Constant(Priority.green.index))();

  /// Local date at midnight. Null means undated.
  DateTimeColumn get dueDate => dateTime().nullable()();

  /// Minutes after midnight. Null means no time.
  IntColumn get dueTime => integer().nullable()();
  BoolColumn get alarm => boolean().withDefault(const Constant(false))();
  IntColumn get recurrence =>
      intEnum<Recurrence>().withDefault(Constant(Recurrence.none.index))();

  /// Day of month that a monthly task repeats on. Needed so that a task on
  /// the 31st goes 31 Jan -> 28 Feb -> 31 Mar instead of staying on the 28th.
  IntColumn get recurrenceDay => integer().nullable()();
  BoolColumn get done => boolean().withDefault(const Constant(false))();
  DateTimeColumn get doneAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class LedgerEntries extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Local date at midnight.
  DateTimeColumn get date => dateTime()();
  IntColumn get amountPence => integer()();
  IntColumn get direction => intEnum<Direction>()();
  IntColumn get category => intEnum<LedgerCategory>()();
  TextColumn get note => text().withDefault(const Constant(''))();
}

/// A task together with the name of its project, if any.
class TaskWithProject {
  TaskWithProject(this.task, this.projectName);
  final Task task;
  final String? projectName;
}

@DriftDatabase(tables: [Projects, Tasks, LedgerEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _open());

  static QueryExecutor _open() => driftDatabase(
    name: 'project_todo',
    native: const DriftNativeOptions(shareAcrossIsolates: true),
  );

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  // ---------- Tasks ----------

  /// Tasks that are not in an archived project, joined with project name.
  JoinedSelectStatement<HasResultSet, dynamic> _visibleTasks() {
    final q = select(
      tasks,
    ).join([leftOuterJoin(projects, projects.id.equalsExp(tasks.projectId))]);
    q.where(projects.archived.isNull() | projects.archived.equals(false));
    return q;
  }

  List<TaskWithProject> _mapJoined(List<TypedResult> rows) => rows
      .map(
        (r) => TaskWithProject(
          r.readTable(tasks),
          r.readTableOrNull(projects)?.name,
        ),
      )
      .toList();

  /// Undone dated tasks due on or before [day], plus tasks done on [day].
  /// Used by the Today tab.
  Stream<List<TaskWithProject>> watchTodayTasks(DateTime day) {
    final start = dateOnly(day);
    final end = start.add(const Duration(days: 1));
    final q = _visibleTasks()
      ..where(
        (tasks.done.equals(false) & tasks.dueDate.isSmallerThanValue(end)) |
            (tasks.done.equals(true) &
                tasks.doneAt.isBiggerOrEqualValue(start) &
                tasks.doneAt.isSmallerThanValue(end)),
      );
    return q.watch().map(_mapJoined);
  }

  /// Undone tasks due before [today]. Used by the Late tab.
  Stream<List<TaskWithProject>> watchLateTasks(DateTime today) {
    final q = _visibleTasks()
      ..where(
        tasks.done.equals(false) &
            tasks.dueDate.isSmallerThanValue(dateOnly(today)),
      );
    return q.watch().map(_mapJoined);
  }

  /// Dated tasks with due date in [from, to). Used by the Calendar tab.
  Stream<List<TaskWithProject>> watchTasksBetween(DateTime from, DateTime to) {
    final q = _visibleTasks()
      ..where(
        tasks.dueDate.isBiggerOrEqualValue(from) &
            tasks.dueDate.isSmallerThanValue(to),
      );
    return q.watch().map(_mapJoined);
  }

  Stream<List<Task>> watchProjectTasks(int projectId) =>
      (select(tasks)..where((t) => t.projectId.equals(projectId))).watch();

  Future<Task?> getTask(int id) =>
      (select(tasks)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertTask(TasksCompanion entry) => into(tasks).insert(entry);

  Future<void> updateTask(Task task) => update(tasks).replace(task);

  Future<void> deleteTask(int id) =>
      (delete(tasks)..where((t) => t.id.equals(id))).go();

  /// Undone tasks with an alarm, not in an archived project.
  Future<List<Task>> alarmTasks() async {
    final q = _visibleTasks()
      ..where(tasks.done.equals(false) & tasks.alarm.equals(true));
    return (await q.get()).map((r) => r.readTable(tasks)).toList();
  }

  // ---------- Projects ----------

  Stream<List<Project>> watchProjects() =>
      (select(projects)..orderBy([(p) => OrderingTerm.asc(p.name)])).watch();

  Stream<List<Task>> watchAllOpenTasks() =>
      (select(tasks)..where((t) => t.done.equals(false))).watch();

  Future<List<Project>> activeProjects() =>
      (select(projects)
            ..where((p) => p.archived.equals(false))
            ..orderBy([(p) => OrderingTerm.asc(p.name)]))
          .get();

  Future<Project?> getProject(int id) =>
      (select(projects)..where((p) => p.id.equals(id))).getSingleOrNull();

  Future<int> insertProject(String name) =>
      into(projects).insert(ProjectsCompanion.insert(name: name));

  Future<void> renameProject(int id, String name) => (update(
    projects,
  )..where((p) => p.id.equals(id))).write(ProjectsCompanion(name: Value(name)));

  Future<void> setProjectArchived(int id, bool archived) =>
      (update(projects)..where((p) => p.id.equals(id))).write(
        ProjectsCompanion(archived: Value(archived)),
      );

  /// Deletes a project. If [deleteTasks] is false its tasks become standalone.
  /// Returns the ids of the tasks that were deleted.
  Future<List<int>> deleteProject(int id, {required bool deleteTasks}) {
    return transaction(() async {
      final ids =
          await (selectOnly(tasks)
                ..addColumns([tasks.id])
                ..where(tasks.projectId.equals(id)))
              .map((r) => r.read(tasks.id)!)
              .get();
      if (deleteTasks) {
        await (delete(tasks)..where((t) => t.projectId.equals(id))).go();
      } else {
        await (update(tasks)..where((t) => t.projectId.equals(id))).write(
          const TasksCompanion(projectId: Value(null)),
        );
      }
      await (delete(projects)..where((p) => p.id.equals(id))).go();
      return deleteTasks ? ids : <int>[];
    });
  }

  // ---------- Ledger ----------

  Stream<List<LedgerEntry>> watchLedger() =>
      (select(ledgerEntries)..orderBy([
            (e) => OrderingTerm.desc(e.date),
            (e) => OrderingTerm.desc(e.id),
          ]))
          .watch();

  Future<int> insertLedgerEntry(LedgerEntriesCompanion entry) =>
      into(ledgerEntries).insert(entry);

  Future<void> updateLedgerEntry(LedgerEntry entry) =>
      update(ledgerEntries).replace(entry);

  Future<void> deleteLedgerEntry(int id) =>
      (delete(ledgerEntries)..where((e) => e.id.equals(id))).go();

  // ---------- Backup ----------

  /// Replaces all data. Rows keep their ids.
  Future<void> replaceAll({
    required List<Project> projectRows,
    required List<Task> taskRows,
    required List<LedgerEntry> ledgerRows,
  }) {
    return transaction(() async {
      await delete(tasks).go();
      await delete(projects).go();
      await delete(ledgerEntries).go();
      await batch((b) {
        b.insertAll(projects, projectRows);
        b.insertAll(tasks, taskRows);
        b.insertAll(ledgerEntries, ledgerRows);
      });
    });
  }
}
