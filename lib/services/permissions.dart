import 'package:permission_handler/permission_handler.dart';

import 'alarms.dart';

class PermissionInfo {
  PermissionInfo(this.label, this.permission, this.help);
  final String label;
  final Permission permission;
  final String help;
}

final appPermissions = [
  PermissionInfo(
    'Notifications',
    Permission.notification,
    'Needed to show alarms.',
  ),
  PermissionInfo(
    'Exact alarms',
    Permission.scheduleExactAlarm,
    'Needed for alarms to fire at the exact time.',
  ),
  PermissionInfo(
    'Ignore battery optimisation',
    Permission.ignoreBatteryOptimizations,
    'Stops Android from delaying alarms to save battery.',
  ),
];

/// Current status of a permission.
///
/// Exact alarms are checked with Android's AlarmManager. On Android 13+ the
/// app holds USE_EXACT_ALARM, which permission_handler does not know about,
/// so it would report "denied" even though alarms work.
Future<PermissionStatus> permissionStatus(Permission p) async {
  if (p == Permission.scheduleExactAlarm) {
    final ok = await NotificationAlarms.instance.android
        ?.canScheduleExactNotifications();
    if (ok != null) {
      return ok ? PermissionStatus.granted : PermissionStatus.denied;
    }
  }
  return p.status;
}

/// Asks for a permission. If Android will not show a prompt any more,
/// opens the app's settings page instead.
Future<void> fixPermission(Permission p) async {
  if (p == Permission.scheduleExactAlarm) {
    await NotificationAlarms.instance.android?.requestExactAlarmsPermission();
    return;
  }
  final status = await p.request();
  if (status.isPermanentlyDenied) await openAppSettings();
}
