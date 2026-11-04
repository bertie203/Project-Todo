import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_todo/data/database.dart';
import 'package:project_todo/services/alarms.dart';
import 'package:project_todo/services/backup.dart';
import 'package:project_todo/services/task_service.dart';

/// Records alarm calls so tests can check them.
class FakeAlarms implements AlarmScheduler {
  final scheduled = <int>[];
  final cancelled = <int>[];
  final snoozed = <int>[];

  @override
  Future<void> scheduleFor(Task task, {String? projectName}) async {
    if (alarmTime(task) != null) scheduled.add(task.id);
  }

  @override
  Future<void> cancelFor(int taskId) async => cancelled.add(taskId);

  @override
  Future<void> snooze(Task task, {String? projectName}) async =>
      snoozed.add(task.id);

  @override
  Future<void> rescheduleAll(AppDatabase db) async {}
}

Task draft(
  String title, {
  DateTime? due,
  int? time,
  bool alarm = false,
  Recurrence r = Recurrence.none,
  int? projectId,
}) => Task(
  id: 0,
  projectId: projectId,
  title: title,
  notes: '',
  priority: Priority.green,
  dueDate: due,
  dueTime: time,
  alarm: alarm,
  recurrence: r,
  done: false,
  createdAt: DateTime(2026, 10, 1),
);

void main() {
  late AppDatabase db;
  late FakeAlarms alarms;
  late TaskService service;
  final now = DateTime(2026, 10, 31, 12);

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    alarms = FakeAlarms();
    service = TaskService(db, alarms, clock: () => now);
  });

  tearDown(() => db.close());

  group('tasks', () {
    test('create, read, update, delete', () async {
      final t = await service.create(
        draft('Buy milk', due: DateTime(2026, 10, 31)),
      );
      expect(t.id, greaterThan(0));
      expect((await db.getTask(t.id))!.title, 'Buy milk');

      await service.save(
        t.copyWith(title: 'Buy oat milk', priority: Priority.red),
      );
      final u = (await db.getTask(t.id))!;
      expect(u.title, 'Buy oat milk');
      expect(u.priority, Priority.red);

      await service.delete(t.id);
      expect(await db.getTask(t.id), isNull);
      expect(alarms.cancelled, contains(t.id));
    });

    test('alarm is dropped without date and time', () async {
      final t = await service.create(
        draft('No time', due: DateTime(2026, 11, 1), alarm: true),
      );
      expect(t.alarm, isFalse);
      expect(alarms.scheduled, isEmpty);
    });

    test('alarm is scheduled with date and time', () async {
      final t = await service.create(
        draft('Call', due: DateTime(2026, 11, 1), time: 9 * 60, alarm: true),
      );
      expect(t.alarm, isTrue);
      expect(alarms.scheduled, [t.id]);
    });

    test('recurrence is dropped without a date', () async {
      final t = await service.create(draft('Undated', r: Recurrence.daily));
      expect(t.recurrence, Recurrence.none);
    });

    test('completing a normal task', () async {
      final t = await service.create(
        draft('One-off', due: DateTime(2026, 10, 31)),
      );
      final next = await service.complete(t);
      expect(next, isNull);
      final done = (await db.getTask(t.id))!;
      expect(done.done, isTrue);
      expect(done.doneAt, now);
    });

    test('completing a recurring task creates the next instance', () async {
      final t = await service.create(
        draft(
          'Bins',
          due: DateTime(2026, 10, 31),
          time: 7 * 60,
          alarm: true,
          r: Recurrence.weekly,
        ),
      );
      alarms.scheduled.clear();
      final next = (await service.complete(t))!;
      expect(next.id, isNot(t.id));
      expect(next.dueDate, DateTime(2026, 11, 7));
      expect(next.dueTime, 7 * 60);
      expect(next.done, isFalse);
      expect(next.recurrence, Recurrence.weekly);
      expect(alarms.cancelled, contains(t.id));
      expect(alarms.scheduled, [next.id]);
      expect((await db.getTask(t.id))!.done, isTrue);
    });

    test('monthly task keeps its day through a short month', () async {
      final t = await service.create(
        draft('Rent', due: DateTime(2026, 10, 31), r: Recurrence.monthly),
      );
      expect(t.recurrenceDay, 31);
      final nov = (await service.complete(t))!;
      expect(nov.dueDate, DateTime(2026, 11, 30));
      final s2 = TaskService(db, alarms, clock: () => DateTime(2026, 11, 30));
      final dec = (await s2.complete(nov))!;
      expect(dec.dueDate, DateTime(2026, 12, 31));
    });
  });

  group('reschedule', () {
    test('moves date and time and keeps the alarm', () async {
      final t = await service.create(
        draft('Dentist', due: DateTime(2026, 10, 31), time: 600, alarm: true),
      );
      alarms.scheduled.clear();
      final moved = await service.reschedule(t, DateTime(2026, 11, 3), 14 * 60);
      expect(moved.dueDate, DateTime(2026, 11, 3));
      expect(moved.dueTime, 14 * 60);
      expect(moved.alarm, isTrue);
      expect(alarms.scheduled, [t.id]);
      expect((await db.getTask(t.id))!.dueDate, DateTime(2026, 11, 3));
    });

    test('moving with no time drops the alarm', () async {
      final t = await service.create(
        draft('Call', due: DateTime(2026, 10, 31), time: 600, alarm: true),
      );
      final moved = await service.reschedule(t, DateTime(2026, 11, 1), null);
      expect(moved.dueTime, isNull);
      expect(moved.alarm, isFalse);
    });

    test('monthly task repeats on the new day', () async {
      final t = await service.create(
        draft('Rent', due: DateTime(2026, 10, 31), r: Recurrence.monthly),
      );
      final moved = await service.reschedule(t, DateTime(2026, 11, 5), null);
      expect(moved.recurrenceDay, 5);
    });
  });
  group('queries', () {
    test('today query returns overdue, today and done today', () async {
      await service.create(draft('overdue', due: DateTime(2026, 10, 20)));
      await service.create(draft('today', due: DateTime(2026, 10, 31)));
      await service.create(draft('tomorrow', due: DateTime(2026, 11, 1)));
      await service.create(draft('undated'));
      final d = await service.create(
        draft('finished', due: DateTime(2026, 10, 31)),
      );
      await service.complete(d);
      final rows = await db.watchTodayTasks(now).first;
      expect(
        rows.map((r) => r.task.title),
        unorderedEquals(['overdue', 'today', 'finished']),
      );
    });

    test('late query returns only undone past tasks', () async {
      await service.create(draft('missed', due: DateTime(2026, 10, 30)));
      final d = await service.create(
        draft('caught up', due: DateTime(2026, 10, 29)),
      );
      await service.complete(d);
      await service.create(draft('today', due: DateTime(2026, 10, 31)));
      await service.create(draft('undated'));
      final rows = await db.watchLateTasks(now).first;
      expect(rows.map((r) => r.task.title), ['missed']);
    });
    test('archived project tasks are hidden', () async {
      final p = await db.insertProject('Old');
      await service.create(
        draft('hidden', due: DateTime(2026, 10, 31), projectId: p),
      );
      await service.create(draft('shown', due: DateTime(2026, 10, 31)));
      await db.setProjectArchived(p, true);
      final rows = await db.watchTodayTasks(now).first;
      expect(rows.map((r) => r.task.title), ['shown']);
      final cal = await db
          .watchTasksBetween(DateTime(2026, 10, 1), DateTime(2026, 11, 1))
          .first;
      expect(cal.map((r) => r.task.title), ['shown']);
    });

    test('project name is joined', () async {
      final p = await db.insertProject('House');
      await service.create(
        draft('paint', due: DateTime(2026, 10, 31), projectId: p),
      );
      final rows = await db.watchTodayTasks(now).first;
      expect(rows.single.projectName, 'House');
    });
  });

  group('projects', () {
    test('create, rename, archive', () async {
      final id = await db.insertProject('Garden');
      await db.renameProject(id, 'Allotment');
      await db.setProjectArchived(id, true);
      final p = (await db.getProject(id))!;
      expect(p.name, 'Allotment');
      expect(p.archived, isTrue);
      expect(await db.activeProjects(), isEmpty);
    });

    test('delete project and keep tasks as standalone', () async {
      final id = await db.insertProject('Car');
      final t = await service.create(draft('MOT', projectId: id));
      await service.deleteProject(id, deleteTasks: false);
      expect(await db.getProject(id), isNull);
      expect((await db.getTask(t.id))!.projectId, isNull);
    });

    test('delete project with its tasks', () async {
      final id = await db.insertProject('Car');
      final t = await service.create(draft('MOT', projectId: id));
      final other = await service.create(draft('Standalone'));
      await service.deleteProject(id, deleteTasks: true);
      expect(await db.getTask(t.id), isNull);
      expect(await db.getTask(other.id), isNotNull);
      expect(alarms.cancelled, contains(t.id));
    });
  });

  group('ledger and backup', () {
    test('ledger CRUD', () async {
      final id = await db.insertLedgerEntry(
        LedgerEntriesCompanion.insert(
          date: DateTime(2026, 10, 31),
          amountPence: 1234,
          direction: Direction.moneyOut,
          category: LedgerCategory.personal,
        ),
      );
      var all = await db.watchLedger().first;
      expect(all.single.amountPence, 1234);
      await db.updateLedgerEntry(
        all.single.copyWith(amountPence: 999, note: 'Lunch'),
      );
      all = await db.watchLedger().first;
      expect(all.single.note, 'Lunch');
      await db.deleteLedgerEntry(id);
      expect(await db.watchLedger().first, isEmpty);
    });

    test('export then import gives the same data', () async {
      final p = await db.insertProject('Work');
      await service.create(
        draft(
          'Report',
          due: DateTime(2026, 11, 2),
          time: 600,
          alarm: true,
          r: Recurrence.monthly,
          projectId: p,
        ),
      );
      await db.insertLedgerEntry(
        LedgerEntriesCompanion.insert(
          date: DateTime(2026, 10, 31),
          amountPence: 50000,
          direction: Direction.moneyIn,
          category: LedgerCategory.business,
          note: const Value('Invoice 12'),
        ),
      );
      final json = await exportJson(db);

      final db2 = AppDatabase(NativeDatabase.memory());
      await db2.insertProject('Will be replaced');
      await importBackup(db2, parseBackup(json));
      expect(await exportJson(db2), isNot(isEmpty));
      expect((await db2.select(db2.projects).get()).map((x) => x.name), [
        'Work',
      ]);
      final task = (await db2.select(db2.tasks).get()).single;
      expect(task.title, 'Report');
      expect(task.dueDate, DateTime(2026, 11, 2));
      expect(task.recurrenceDay, 2);
      expect(task.projectId, p);
      final entry = (await db2.select(db2.ledgerEntries).get()).single;
      expect(entry.note, 'Invoice 12');
      expect(entry.direction, Direction.moneyIn);
      await db2.close();
    });

    test('bad backup is rejected', () {
      expect(() => parseBackup('not json'), throwsFormatException);
      expect(() => parseBackup('{"format":"other"}'), throwsFormatException);
    });
  });
}
