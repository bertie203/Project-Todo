import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../logic/dates.dart';
import '../logic/uid.dart';
import 'enums.dart';
import 'subtasks.dart';

export 'enums.dart';
export 'subtasks.dart';

part 'database.g.dart';

class Projects extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Same id on the phone and in the cloud.
  TextColumn get uid => text().clientDefault(newUid)();

  /// Epoch ms of the last change. The newer change wins when syncing.
  IntColumn get updatedAt => integer().clientDefault(nowMs)();

  /// Changed on the phone and not yet uploaded.
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();
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

  /// Ordered steps, stored as JSON.
  TextColumn get subtasks =>
      text().map(const SubtasksConverter()).withDefault(const Constant('[]'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get uid => text().clientDefault(newUid)();
  IntColumn get updatedAt => integer().clientDefault(nowMs)();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();
}

/// Rows deleted on the phone, waiting to be deleted in the cloud.
class Tombstones extends Table {
  /// 'task' or 'project'.
  TextColumn get kind => text()();
  TextColumn get uid => text()();
  IntColumn get deletedAt => integer()();

  @override
  Set<Column> get primaryKey => {kind, uid};
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

@DriftDatabase(tables: [Projects, Tasks, LedgerEntries, Tombstones])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _open());

  static QueryExecutor _open() => driftDatabase(
    name: 'project_todo',
    native: const DriftNativeOptions(shareAcrossIsolates: true),
  );

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // Sync columns. Existing rows get a uid and are marked for upload.
        for (final table in ['projects', 'tasks']) {
          await customStatement(
            "ALTER TABLE $table ADD COLUMN uid TEXT NOT NULL DEFAULT ''",
          );
          await customStatement(
            'ALTER TABLE $table ADD COLUMN updated_at INTEGER NOT NULL DEFAULT 0',
          );
          await customStatement(
            'ALTER TABLE $table ADD COLUMN dirty INTEGER NOT NULL DEFAULT 1 '
            'CHECK (dirty IN (0, 1))',
          );
          final ids = await customSelect('SELECT id FROM $table').get();
          for (final r in ids) {
            await customStatement(
              'UPDATE $table SET uid = ?, updated_at = ? WHERE id = ?',
              [newUid(), nowMs(), r.read<int>('id')],
            );
          }
        }
        await m.createTable(tombstones);
      }
      if (from < 3) {
        await m.addColumn(tasks, tasks.subtasks);
      }
    },
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

  /// Saves a task and marks it for upload.
  Future<void> updateTask(Task task) =>
      update(tasks).replace(task.copyWith(updatedAt: nowMs(), dirty: true));

  Future<void> deleteTask(int id) => transaction(() async {
    final t = await getTask(id);
    if (t == null) return;
    await _tombstone('task', t.uid);
    await (delete(tasks)..where((t) => t.id.equals(id))).go();
  });

  Future<void> _tombstone(String kind, String uid) => into(tombstones)
      .insertOnConflictUpdate(
        TombstonesCompanion.insert(kind: kind, uid: uid, deletedAt: nowMs()),
      );

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

  Future<void> renameProject(int id, String name) =>
      (update(projects)..where((p) => p.id.equals(id))).write(
        ProjectsCompanion(
          name: Value(name),
          updatedAt: Value(nowMs()),
          dirty: const Value(true),
        ),
      );

  Future<void> setProjectArchived(int id, bool archived) =>
      (update(projects)..where((p) => p.id.equals(id))).write(
        ProjectsCompanion(
          archived: Value(archived),
          updatedAt: Value(nowMs()),
          dirty: const Value(true),
        ),
      );

  /// Deletes a project. If [deleteTasks] is false its tasks become standalone.
  /// Returns the ids of the tasks that were deleted.
  Future<List<int>> deleteProject(int id, {required bool deleteTasks}) {
    return transaction(() async {
      final rows = await (select(
        tasks,
      )..where((t) => t.projectId.equals(id))).get();
      final ids = rows.map((t) => t.id).toList();
      if (deleteTasks) {
        for (final t in rows) {
          await _tombstone('task', t.uid);
        }
        await (delete(tasks)..where((t) => t.projectId.equals(id))).go();
      } else {
        await (update(tasks)..where((t) => t.projectId.equals(id))).write(
          TasksCompanion(
            projectId: const Value(null),
            updatedAt: Value(nowMs()),
            dirty: const Value(true),
          ),
        );
      }
      final p = await getProject(id);
      if (p != null) await _tombstone('project', p.uid);
      await (delete(projects)..where((p) => p.id.equals(id))).go();
      return deleteTasks ? ids : <int>[];
    });
  }

  // ---------- Sync ----------

  Future<List<Project>> dirtyProjects() =>
      (select(projects)..where((p) => p.dirty.equals(true))).get();

  Future<List<Task>> dirtyTasks() =>
      (select(tasks)..where((t) => t.dirty.equals(true))).get();

  Future<List<Tombstone>> allTombstones() => select(tombstones).get();

  Future<List<Project>> allProjects() => select(projects).get();

  /// Clears the dirty flag only if the row was not changed again since
  /// it was uploaded.
  Future<void> markUploaded(
    List<Project> ps,
    List<Task> ts,
    List<Tombstone> gone,
  ) => transaction(() async {
    for (final p in ps) {
      await (update(projects)
            ..where((x) => x.id.equals(p.id) & x.updatedAt.equals(p.updatedAt)))
          .write(const ProjectsCompanion(dirty: Value(false)));
    }
    for (final t in ts) {
      await (update(tasks)
            ..where((x) => x.id.equals(t.id) & x.updatedAt.equals(t.updatedAt)))
          .write(const TasksCompanion(dirty: Value(false)));
    }
    for (final g in gone) {
      await (delete(tombstones)..where(
            (x) =>
                x.kind.equals(g.kind) &
                x.uid.equals(g.uid) &
                x.deletedAt.equals(g.deletedAt),
          ))
          .go();
    }
  });

  Future<Project?> projectByUid(String uid) =>
      (select(projects)..where((p) => p.uid.equals(uid))).getSingleOrNull();

  Future<Task?> taskByUid(String uid) =>
      (select(tasks)..where((t) => t.uid.equals(uid))).getSingleOrNull();

  /// Writes a project from the cloud. Local unsent changes that are newer
  /// win. [row] has no meaningful id.
  Future<void> applyRemoteProject(Project row, {required bool deleted}) async {
    final local = await projectByUid(row.uid);
    if (local != null && local.dirty && local.updatedAt > row.updatedAt) return;
    if (deleted) {
      if (local != null) {
        await (update(tasks)..where((t) => t.projectId.equals(local.id))).write(
          const TasksCompanion(projectId: Value(null)),
        );
        await (delete(projects)..where((p) => p.id.equals(local.id))).go();
      }
      return;
    }
    final companion = row
        .toCompanion(false)
        .copyWith(dirty: const Value(false));
    if (local == null) {
      await into(projects).insert(companion.copyWith(id: const Value.absent()));
    } else {
      await (update(projects)..where((p) => p.id.equals(local.id))).write(
        companion.copyWith(id: const Value.absent()),
      );
    }
  }

  /// Writes a task from the cloud. [row.projectId] must already be local.
  /// Returns the local task id, or null if it was skipped or deleted.
  Future<int?> applyRemoteTask(Task row, {required bool deleted}) async {
    final local = await taskByUid(row.uid);
    if (local != null && local.dirty && local.updatedAt > row.updatedAt) {
      return null;
    }
    if (deleted) {
      if (local != null) {
        await (delete(tasks)..where((t) => t.id.equals(local.id))).go();
      }
      return null;
    }
    final companion = row
        .toCompanion(false)
        .copyWith(dirty: const Value(false));
    if (local == null) {
      return into(tasks).insert(companion.copyWith(id: const Value.absent()));
    }
    await (update(tasks)..where((t) => t.id.equals(local.id))).write(
      companion.copyWith(id: const Value.absent()),
    );
    return local.id;
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
      // Rows not in the backup are deleted in the cloud too.
      final keep = {
        ...projectRows.map((p) => 'project:${p.uid}'),
        ...taskRows.map((t) => 'task:${t.uid}'),
      };
      for (final p in await select(projects).get()) {
        if (!keep.contains('project:${p.uid}')) {
          await _tombstone('project', p.uid);
        }
      }
      for (final t in await select(tasks).get()) {
        if (!keep.contains('task:${t.uid}')) await _tombstone('task', t.uid);
      }
      await delete(tasks).go();
      await delete(projects).go();
      await delete(ledgerEntries).go();
      await batch((b) {
        b.insertAll(
          projects,
          projectRows.map((p) => p.copyWith(updatedAt: nowMs(), dirty: true)),
        );
        b.insertAll(
          tasks,
          taskRows.map((t) => t.copyWith(updatedAt: nowMs(), dirty: true)),
        );
        b.insertAll(ledgerEntries, ledgerRows);
      });
    });
  }
}
