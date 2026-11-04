import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show TableUpdate;
import 'package:flutter/widgets.dart';

import '../data/database.dart';
import 'alarms.dart';

const defaultServerUrl = 'https://project-todo.bertiek203.workers.dev';

/// Sends JSON to the server and returns the decoded reply.
/// Throws [SyncException] on HTTP errors.
typedef PostJson = Future<Map<String, dynamic>> Function(
  Uri url,
  Map<String, dynamic> body, {
  String? token,
});

class SyncException implements Exception {
  SyncException(this.message, {this.status});
  final String message;
  final int? status;
  @override
  String toString() => message;
}

/// Where the server address, token and cursor are kept.
abstract class SyncStore {
  Future<Map<String, dynamic>> load();
  Future<void> save(Map<String, dynamic> data);
}

class FileSyncStore implements SyncStore {
  FileSyncStore(this.file);
  final File file;

  @override
  Future<Map<String, dynamic>> load() async {
    try {
      return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  @override
  Future<void> save(Map<String, dynamic> data) =>
      file.writeAsString(jsonEncode(data));
}

class MemorySyncStore implements SyncStore {
  Map<String, dynamic> data = {};
  @override
  Future<Map<String, dynamic>> load() async => Map.of(data);
  @override
  Future<void> save(Map<String, dynamic> d) async => data = Map.of(d);
}

Future<Map<String, dynamic>> httpPostJson(
  Uri url,
  Map<String, dynamic> body, {
  String? token,
}) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
  try {
    final req = await client.postUrl(url);
    req.headers.contentType = ContentType.json;
    if (token != null) req.headers.set('Authorization', 'Bearer $token');
    req.add(utf8.encode(jsonEncode(body)));
    final res = await req.close().timeout(const Duration(seconds: 30));
    final text = await res.transform(utf8.decoder).join();
    Map<String, dynamic> json;
    try {
      json = jsonDecode(text) as Map<String, dynamic>;
    } catch (_) {
      json = {};
    }
    if (res.statusCode != 200) {
      throw SyncException(
        json['error'] as String? ?? 'Server error ${res.statusCode}',
        status: res.statusCode,
      );
    }
    return json;
  } on SocketException {
    throw SyncException('No connection');
  } on TimeoutException {
    throw SyncException('Server did not answer');
  } finally {
    client.close();
  }
}

String _date(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime _parseDate(String s) {
  final p = s.split('-').map(int.parse).toList();
  return DateTime(p[0], p[1], p[2]);
}

/// Two-way sync of projects and tasks with the cloud service.
/// The ledger is not synced.
class SyncService extends ChangeNotifier with WidgetsBindingObserver {
  SyncService(
    this.db, {
    required this.alarms,
    required this.store,
    PostJson? post,
  }) : _post = post ?? httpPostJson;

  final AppDatabase db;
  final AlarmScheduler alarms;
  final SyncStore store;
  final PostJson _post;

  String? serverUrl;
  String? _token;
  int _since = 0;
  DateTime? lastSync;
  String? lastError;
  bool syncing = false;

  bool get connected => _token != null;

  Future<void>? _running;
  bool _again = false;
  Timer? _debounce;
  Timer? _periodic;
  StreamSubscription<Set<TableUpdate>>? _changes;

  Future<void> load() async {
    final d = await store.load();
    serverUrl = d['url'] as String?;
    _token = d['token'] as String?;
    _since = (d['since'] as int?) ?? 0;
    final last = d['lastSync'] as int?;
    lastSync = last == null ? null : DateTime.fromMillisecondsSinceEpoch(last);
    notifyListeners();
  }

  Future<void> _persist() => store.save({
    'url': serverUrl,
    'token': _token,
    'since': _since,
    'lastSync': lastSync?.millisecondsSinceEpoch,
  });

  /// Starts automatic syncing: on start, on resume, a few seconds after
  /// local changes, and every 2 minutes while the app is open.
  void start() {
    WidgetsBinding.instance.addObserver(this);
    _changes = db.tableUpdates().listen((_) => _scheduleIfChanged());
    _periodic = Timer.periodic(const Duration(minutes: 2), (_) => syncNow());
    syncNow();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _changes?.cancel();
    _periodic?.cancel();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) syncNow();
  }

  void _scheduleIfChanged() {
    if (!connected || syncing) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 3), () async {
      if (await _hasLocalChanges()) syncNow();
    });
  }

  Future<bool> _hasLocalChanges() async =>
      (await db.dirtyProjects()).isNotEmpty ||
      (await db.dirtyTasks()).isNotEmpty ||
      (await db.allTombstones()).isNotEmpty;

  /// Signs in with the password and runs a first sync.
  Future<void> connect(String url, String password) async {
    final base = url.trim().replaceAll(RegExp(r'/+$'), '');
    final reply = await _post(Uri.parse('$base/api/login'), {
      'password': password.trim(),
    });
    final token = reply['token'] as String?;
    if (token == null) throw SyncException('Server did not return a token');
    serverUrl = base;
    _token = token;
    _since = 0;
    lastError = null;
    await _persist();
    notifyListeners();
    await syncNow();
  }

  /// Stops syncing. Data on the phone stays as it is.
  Future<void> disconnect() async {
    _token = null;
    _since = 0;
    lastSync = null;
    lastError = null;
    await _persist();
    notifyListeners();
  }

  /// Runs a sync. If one is running, another runs straight after it.
  Future<void> syncNow() {
    if (!connected) return Future.value();
    if (_running != null) {
      _again = true;
      return _running!;
    }
    _running = _loop().whenComplete(() => _running = null);
    return _running!;
  }

  Future<void> _loop() async {
    do {
      _again = false;
      await _syncOnce();
    } while (_again && connected);
  }

  Future<void> _syncOnce() async {
    syncing = true;
    notifyListeners();
    try {
      final projects = await db.dirtyProjects();
      final tasks = await db.dirtyTasks();
      final gone = await db.allTombstones();
      final projectUid = {for (final p in await db.allProjects()) p.id: p.uid};

      final reply = await _post(Uri.parse('$serverUrl/api/sync'), {
        'since': _since,
        'projects': [
          for (final p in projects) _projectOut(p),
          for (final g in gone.where((g) => g.kind == 'project'))
            {'uid': g.uid, 'name': '', 'updated_at': g.deletedAt, 'deleted': 1},
        ],
        'tasks': [
          for (final t in tasks) _taskOut(t, projectUid),
          for (final g in gone.where((g) => g.kind == 'task'))
            {
              'uid': g.uid,
              'title': '',
              'updated_at': g.deletedAt,
              'deleted': 1,
            },
        ],
      }, token: _token);

      await db.markUploaded(projects, tasks, gone);
      await db.transaction(() async {
        for (final p
            in (reply['projects'] as List).cast<Map<String, dynamic>>()) {
          await db.applyRemoteProject(
            _projectIn(p),
            deleted: p['deleted'] == 1,
          );
        }
        for (final t in (reply['tasks'] as List).cast<Map<String, dynamic>>()) {
          final projectUid = t['project_uid'] as String?;
          final projectId = projectUid == null
              ? null
              : (await db.projectByUid(projectUid))?.id;
          await db.applyRemoteTask(
            _taskIn(t, projectId),
            deleted: t['deleted'] == 1,
          );
        }
      });

      _since = reply['rev'] as int;
      lastSync = DateTime.now();
      lastError = null;
      await _persist();
      await alarms.rescheduleAll(db);
    } on SyncException catch (e) {
      lastError = e.message;
      if (e.status == 401) {
        // Token no longer valid: ask the user to connect again.
        _token = null;
        lastError = 'Signed out. Connect again.';
        await _persist();
      }
    } catch (e) {
      lastError = 'Sync failed: $e';
    } finally {
      syncing = false;
      notifyListeners();
    }
  }

  Map<String, dynamic> _projectOut(Project p) => {
    'uid': p.uid,
    'name': p.name,
    'archived': p.archived ? 1 : 0,
    'created_at': p.createdAt.millisecondsSinceEpoch,
    'updated_at': p.updatedAt,
    'deleted': 0,
  };

  Map<String, dynamic> _taskOut(Task t, Map<int, String> projectUid) => {
    'uid': t.uid,
    'project_uid': t.projectId == null ? null : projectUid[t.projectId],
    'title': t.title,
    'notes': t.notes,
    'priority': t.priority.name,
    'due_date': t.dueDate == null ? null : _date(t.dueDate!),
    'due_time': t.dueTime,
    'alarm': t.alarm ? 1 : 0,
    'recurrence': t.recurrence.name,
    'recurrence_day': t.recurrenceDay,
    'done': t.done ? 1 : 0,
    'done_at': t.doneAt?.millisecondsSinceEpoch,
    'created_at': t.createdAt.millisecondsSinceEpoch,
    'updated_at': t.updatedAt,
    'deleted': 0,
  };

  Project _projectIn(Map<String, dynamic> p) => Project(
    id: 0,
    name: p['name'] as String,
    archived: p['archived'] == 1,
    createdAt: DateTime.fromMillisecondsSinceEpoch(p['created_at'] as int),
    uid: p['uid'] as String,
    updatedAt: p['updated_at'] as int,
    dirty: false,
  );

  Task _taskIn(Map<String, dynamic> t, int? projectId) => Task(
    id: 0,
    projectId: projectId,
    title: t['title'] as String,
    notes: t['notes'] as String? ?? '',
    priority: Priority.values.asNameMap()[t['priority']] ?? Priority.green,
    dueDate: t['due_date'] == null ? null : _parseDate(t['due_date'] as String),
    dueTime: t['due_time'] as int?,
    alarm: t['alarm'] == 1,
    recurrence:
        Recurrence.values.asNameMap()[t['recurrence']] ?? Recurrence.none,
    recurrenceDay: t['recurrence_day'] as int?,
    done: t['done'] == 1,
    doneAt: t['done_at'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(t['done_at'] as int),
    createdAt: DateTime.fromMillisecondsSinceEpoch(t['created_at'] as int),
    uid: t['uid'] as String,
    updatedAt: t['updated_at'] as int,
    dirty: false,
  );
}
