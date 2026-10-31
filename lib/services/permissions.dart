import 'package:permission_handler/permission_handler.dart';

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

/// Asks for a permission. If Android will not show a prompt any more,
/// opens the app's settings page instead.
Future<void> fixPermission(Permission p) async {
  final status = await p.request();
  if (status.isPermanentlyDenied) await openAppSettings();
}
