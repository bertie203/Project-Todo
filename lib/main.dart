import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    show NotificationResponse;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'app.dart';
import 'data/database.dart';
import 'providers.dart';
import 'services/alarms.dart';
import 'services/sync.dart';
import 'services/task_service.dart';
import 'ui/task_editor.dart';

late final AppDatabase _db;
late final TaskService _service;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('en_GB');

  _db = AppDatabase();
  final alarms = NotificationAlarms.instance;
  _service = TaskService(_db, alarms);

  await alarms.init(
    onResponse: _onNotificationResponse,
    onBackground: onBackgroundNotificationResponse,
  );
  // Safety net after reboot or app update.
  await alarms.rescheduleAll(_db);

  final support = (await getApplicationSupportDirectory()).path;
  final flag = File('$support/first_run_done');
  final firstRun = !await flag.exists();

  final sync = SyncService(
    _db,
    alarms: alarms,
    store: FileSyncStore(File('$support/sync.json')),
  );
  await sync.load();

  runApp(
    ProviderScope(
      overrides: [
        dbProvider.overrideWithValue(_db),
        alarmsProvider.overrideWithValue(alarms),
        syncProvider.overrideWithValue(sync),
      ],
      child: ProjectTodoApp(
        firstRun: firstRun,
        onFirstRunDone: () => flag.writeAsString('1'),
      ),
    ),
  );

  sync.start();

  if (firstRun) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Permission.notification.request();
    });
  }

  // App opened by tapping an alarm.
  final launch = await alarms.plugin.getNotificationAppLaunchDetails();
  if (launch?.didNotificationLaunchApp ?? false) {
    final r = launch!.notificationResponse;
    if (r != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _onNotificationResponse(r),
      );
    }
  }
}

Future<void> _onNotificationResponse(NotificationResponse r) async {
  final id = taskIdFromPayload(r.payload);
  if (id == null) return;
  switch (r.actionId) {
    case actionDone:
      await _service.completeById(id);
    case actionSnooze:
      await _service.snooze(id);
    default:
      final ctx = navigatorKey.currentContext;
      if (ctx != null) await openTaskEditorById(ctx, _db, id);
  }
}

/// Runs in a background isolate when Done or Snooze is pressed while the
/// app is not in the foreground.
@pragma('vm:entry-point')
Future<void> onBackgroundNotificationResponse(NotificationResponse r) async {
  final id = taskIdFromPayload(r.payload);
  if (id == null) return;
  final alarms = NotificationAlarms.instance;
  await alarms.initBackground();
  final db = AppDatabase();
  try {
    final service = TaskService(db, alarms);
    if (r.actionId == actionDone) {
      await service.completeById(id);
    } else if (r.actionId == actionSnooze) {
      await service.snooze(id);
    }
  } finally {
    await db.close();
  }
}
