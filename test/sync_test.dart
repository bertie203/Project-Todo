import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_todo/data/database.dart';
import 'package:project_todo/services/alarms.dart';
import 'package:project_todo/services/sync.dart';

/// In-memory copy of the cloud sync endpoint (cloud/src/db.ts Store.sync).
class FakeServer {
  final projects = <String, Map<String, dynamic>>{};
  final tasks = <String, Map<String, dynamic>>{};
  int rev = 0;
  bool reject401 = false;
  int calls = 0;

  void _put(Map<String, Map<String, dynamic>> table, Map<String, dynamic> row) {
    final old = table[row['uid']];
    if (old != null &&
        (old['updated_at'] as int) >= (row['updated_at'] as int)) {
      return;
    }
    table[row['uid'] as String] = {
      'created_at': row['updated_at'],
      ...row,
      'rev': ++rev,
    };
  }

  /// Simulates an edit made by Claude in the cloud.
  void edit(String uid, Map<String, dynamic> changes) {
    tasks[uid] = {
      ...tasks[uid]!,
      ...changes,
      'updated_at': DateTime.now().millisecondsSinceEpoch + 1000,
      'rev': ++rev,
    };
  }

  Future<Map<String, dynamic>> post(
    Uri url,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    calls++;
    if (url.path == '/api/login') {
      if (body['password'] != 'pw') throw SyncException('Wrong', status: 401);
      return {'token': 'tok'};
    }
    if (reject401 || token != 'tok') {
      throw SyncException('Not signed in', status: 401);
    }
    final since = body['since'] as int;
    for (final p in (body['projects'] as List).cast<Map<String, dynamic>>()) {
      _put(projects, p);
    }
    for (final t in (body['tasks'] as List).cast<Map<String, dynamic>>()) {
      _put(tasks, t);
    }
    return {
      'rev': rev,
      'projects': projects.values
          .where((p) => (p['rev'] as int) > since)
          .toList(),
      'tasks': tasks.values.where((t) => (t['rev'] as int) > since).toList(),
    };
  }
}

class CountingAlarms extends NoopAlarms {
  int reschedules = 0;
  @override
  Future<void> rescheduleAll(AppDatabase db) async => reschedules++;
}

void main() {
  late AppDatabase db;
  late FakeServer server;
  late CountingAlarms alarms;
  late SyncService sync;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    server = FakeServer();
    alarms = CountingAlarms();
    sync = SyncService(
      db,
      alarms: alarms,
      store: MemorySyncStore(),
      post: server.post,
    );
  });

  tearDown(() => db.close());

  Future<int> addTask(String title, {int? projectId, DateTime? due}) =>
      db.insertTask(
        TasksCompanion.insert(
          title: title,
          projectId: Value(projectId),
          dueDate: Value(due),
        ),
      );

  test('first sync uploads existing tasks and projects', () async {
    final p = await db.insertProject('Garden');
    await addTask('Mow lawn', projectId: p, due: DateTime(2026, 11, 4));
    await addTask('Standalone');

    await sync.connect('https://example.test/', 'pw');

    expect(sync.connected, isTrue);
    expect(sync.lastError, isNull);
    expect(server.projects.values.single['name'], 'Garden');
    final mow = server.tasks.values.firstWhere((t) => t['title'] == 'Mow lawn');
    expect(mow['project_uid'], server.projects.keys.single);
    expect(mow['due_date'], '2026-11-04');
    expect(await db.dirtyTasks(), isEmpty);
    expect(await db.dirtyProjects(), isEmpty);
    expect(alarms.reschedules, 1);
  });

  test('wrong password does not connect', () async {
    await expectLater(
      sync.connect('https://example.test', 'nope'),
      throwsA(isA<SyncException>()),
    );
    expect(sync.connected, isFalse);
  });

  test('change made in the cloud reaches the phone', () async {
    final id = await addTask('Pay invoice', due: DateTime(2026, 11, 2));
    await sync.connect('https://example.test', 'pw');
    final uid = (await db.getTask(id))!.uid;

    server.edit(uid, {'due_date': '2026-11-06', 'due_time': 540, 'done': 0});
    await sync.syncNow();

    final t = (await db.getTask(id))!;
    expect(t.dueDate, DateTime(2026, 11, 6));
    expect(t.dueTime, 540);
    expect(t.dirty, isFalse);
    expect(alarms.reschedules, 2);
  });

  test(
    'task added in the cloud is created on the phone in its project',
    () async {
      final p = await db.insertProject('Work');
      await sync.connect('https://example.test', 'pw');
      final projectUid = (await db.getProject(p))!.uid;
      server.tasks['new-uid'] = {
        'uid': 'new-uid',
        'project_uid': projectUid,
        'title': 'Added by Claude',
        'notes': '',
        'priority': 'red',
        'due_date': '2026-11-05',
        'due_time': null,
        'alarm': 0,
        'recurrence': 'none',
        'recurrence_day': null,
        'done': 0,
        'done_at': null,
        'created_at': 1,
        'updated_at': 1,
        'deleted': 0,
        'rev': ++server.rev,
      };
      await sync.syncNow();
      final t = (await db.taskByUid('new-uid'))!;
      expect(t.title, 'Added by Claude');
      expect(t.priority, Priority.red);
      expect(t.projectId, p);
    },
  );

  test('deleting on the phone deletes in the cloud', () async {
    final id = await addTask('Old');
    await sync.connect('https://example.test', 'pw');
    final uid = (await db.getTask(id))!.uid;

    await db.deleteTask(id);
    expect(await db.allTombstones(), hasLength(1));
    await sync.syncNow();

    expect(server.tasks[uid]!['deleted'], 1);
    expect(await db.allTombstones(), isEmpty);
  });

  test('deleting in the cloud deletes on the phone', () async {
    final id = await addTask('Gone soon');
    await sync.connect('https://example.test', 'pw');
    server.edit((await db.getTask(id))!.uid, {'deleted': 1});
    await sync.syncNow();
    expect(await db.getTask(id), isNull);
  });

  test('newer phone edit beats an older cloud edit', () async {
    final id = await addTask('Draft');
    await sync.connect('https://example.test', 'pw');
    final uid = (await db.getTask(id))!.uid;

    // Cloud edit first, then a later phone edit before the next sync.
    server.tasks[uid] = {
      ...server.tasks[uid]!,
      'title': 'Cloud title',
      'updated_at': DateTime.now().millisecondsSinceEpoch - 5000,
      'rev': ++server.rev,
    };
    await db.updateTask((await db.getTask(id))!.copyWith(title: 'Phone title'));
    await sync.syncNow();

    expect((await db.getTask(id))!.title, 'Phone title');
    expect(server.tasks[uid]!['title'], 'Phone title');
  });

  test('a revoked token signs the phone out', () async {
    await sync.connect('https://example.test', 'pw');
    server.reject401 = true;
    await sync.syncNow();
    expect(sync.connected, isFalse);
    expect(sync.lastError, contains('Connect again'));
  });

  test('not connected means no network calls', () async {
    await addTask('Local only');
    await sync.syncNow();
    expect(server.calls, 0);
  });

  test('upgrade from version 1 keeps data and marks it for upload', () async {
    final old = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw.execute('''
            CREATE TABLE projects (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              archived INTEGER NOT NULL DEFAULT 0 CHECK (archived IN (0, 1)),
              created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)));
            CREATE TABLE tasks (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              project_id INTEGER NULL REFERENCES projects (id),
              title TEXT NOT NULL,
              notes TEXT NOT NULL DEFAULT '',
              priority INTEGER NOT NULL DEFAULT 2,
              due_date INTEGER NULL,
              due_time INTEGER NULL,
              alarm INTEGER NOT NULL DEFAULT 0 CHECK (alarm IN (0, 1)),
              recurrence INTEGER NOT NULL DEFAULT 0,
              recurrence_day INTEGER NULL,
              done INTEGER NOT NULL DEFAULT 0 CHECK (done IN (0, 1)),
              done_at INTEGER NULL,
              created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)));
            CREATE TABLE ledger_entries (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              date INTEGER NOT NULL,
              amount_pence INTEGER NOT NULL,
              direction INTEGER NOT NULL,
              category INTEGER NOT NULL,
              note TEXT NOT NULL DEFAULT '');
            INSERT INTO projects (name) VALUES ('House');
            INSERT INTO tasks (project_id, title) VALUES (1, 'Fix tap');
            INSERT INTO tasks (title) VALUES ('Call mum');
            PRAGMA user_version = 1;
          ''');
        },
      ),
    );
    final tasks = await old.select(old.tasks).get();
    expect(tasks.map((t) => t.title), ['Fix tap', 'Call mum']);
    expect(tasks.every((t) => t.uid.length == 36 && t.dirty), isTrue);
    expect(tasks[0].uid, isNot(tasks[1].uid));
    expect((await old.select(old.projects).getSingle()).uid, hasLength(36));
    expect(await old.allTombstones(), isEmpty);
    await old.close();
  });
}
