import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    hide Priority;
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as fln
    show Priority;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../data/database.dart';
import '../logic/dates.dart';

/// Schedules and cancels task alarms. An interface so tests can use a fake.
abstract class AlarmScheduler {
  Future<void> scheduleFor(Task task, {String? projectName});
  Future<void> cancelFor(int taskId);
  Future<void> snooze(Task task, {String? projectName});
  Future<void> rescheduleAll(AppDatabase db);
}

class NoopAlarms implements AlarmScheduler {
  @override
  Future<void> scheduleFor(Task task, {String? projectName}) async {}
  @override
  Future<void> cancelFor(int taskId) async {}
  @override
  Future<void> snooze(Task task, {String? projectName}) async {}
  @override
  Future<void> rescheduleAll(AppDatabase db) async {}
}

const actionDone = 'done';
const actionSnooze = 'snooze';
const snoozeDuration = Duration(minutes: 10);

String taskPayload(int taskId) => 'task:$taskId';

int? taskIdFromPayload(String? payload) {
  if (payload == null || !payload.startsWith('task:')) return null;
  return int.tryParse(payload.substring(5));
}

/// The time an alarm should fire, or null if the task has no valid alarm.
DateTime? alarmTime(Task t) {
  if (!t.alarm || t.done || t.dueDate == null || t.dueTime == null) return null;
  return atMinutes(t.dueDate!, t.dueTime!);
}

class NotificationAlarms implements AlarmScheduler {
  NotificationAlarms._();
  static final NotificationAlarms instance = NotificationAlarms._();

  final plugin = FlutterLocalNotificationsPlugin();
  bool _tzReady = false;

  /// Snooze notifications use a separate id so that rescheduling the main
  /// alarm does not remove a pending snooze.
  static int snoozeId(int taskId) => taskId + 1000000000;

  static const _channel = AndroidNotificationDetails(
    'task_alarms',
    'Task alarms',
    channelDescription: 'Alarms for tasks with a due time',
    importance: Importance.max,
    priority: fln.Priority.max,
    playSound: true,
    enableVibration: true,
    visibility: NotificationVisibility.public,
    category: AndroidNotificationCategory.alarm,
    audioAttributesUsage: AudioAttributesUsage.alarm,
    actions: [
      AndroidNotificationAction(actionDone, 'Done'),
      AndroidNotificationAction(actionSnooze, 'Snooze 10 min'),
    ],
  );

  Future<void> initTimeZone() async {
    if (_tzReady) return;
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Europe/London'));
    }
    _tzReady = true;
  }

  Future<void> init({
    required DidReceiveNotificationResponseCallback onResponse,
    required DidReceiveBackgroundNotificationResponseCallback onBackground,
  }) async {
    await initTimeZone();
    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: onResponse,
      onDidReceiveBackgroundNotificationResponse: onBackground,
    );
  }

  /// Init for the background isolate that handles notification actions.
  Future<void> initBackground() async {
    WidgetsFlutterBinding.ensureInitialized();
    await initTimeZone();
    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
  }

  AndroidFlutterLocalNotificationsPlugin? get android => plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  Future<void> _schedule(int id, Task t, DateTime when, String? projectName) {
    final parts = <String>[
      if (t.dueTime != null) _hhmm(t.dueTime!),
      ?projectName,
    ];
    return plugin.zonedSchedule(
      id: id,
      scheduledDate: tz.TZDateTime.from(when, tz.local),
      notificationDetails: const NotificationDetails(android: _channel),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      title: t.title,
      body: parts.join(' · '),
      payload: taskPayload(t.id),
    );
  }

  @override
  Future<void> scheduleFor(Task task, {String? projectName}) async {
    await initTimeZone();
    await plugin.cancel(id: task.id);
    final when = alarmTime(task);
    if (when == null) {
      await plugin.cancel(id: snoozeId(task.id));
      return;
    }
    if (!when.isAfter(DateTime.now())) return;
    await _schedule(task.id, task, when, projectName);
  }

  @override
  Future<void> cancelFor(int taskId) async {
    await plugin.cancel(id: taskId);
    await plugin.cancel(id: snoozeId(taskId));
  }

  @override
  Future<void> snooze(Task task, {String? projectName}) async {
    await initTimeZone();
    final when = DateTime.now().add(snoozeDuration);
    await _schedule(snoozeId(task.id), task, when, projectName);
  }

  /// Schedules every future alarm from the database and cancels pending
  /// alarms that no longer match a task. Pending snoozes are kept.
  @override
  Future<void> rescheduleAll(AppDatabase db) async {
    await initTimeZone();
    final tasks = await db.alarmTasks();
    final projects = {for (final p in await db.activeProjects()) p.id: p.name};
    final now = DateTime.now();
    final wanted = <int>{};
    for (final t in tasks) {
      final when = alarmTime(t);
      if (when != null && when.isAfter(now)) wanted.add(t.id);
    }
    final pending = await plugin.pendingNotificationRequests();
    final openIds = tasks.map((t) => t.id).toSet();
    for (final p in pending) {
      if (p.id >= 1000000000) {
        if (!openIds.contains(p.id - 1000000000)) await plugin.cancel(id: p.id);
      } else if (!wanted.contains(p.id)) {
        await plugin.cancel(id: p.id);
      }
    }
    for (final t in tasks) {
      if (wanted.contains(t.id)) {
        await _schedule(t.id, t, alarmTime(t)!, projects[t.projectId]);
      }
    }
  }
}

String _hhmm(int minutes) =>
    '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';
