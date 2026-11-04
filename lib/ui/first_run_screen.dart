import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/permissions.dart';

class FirstRunScreen extends StatelessWidget {
  const FirstRunScreen({super.key, required this.onDone});
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('Project Todo', style: t.headlineMedium),
            const SizedBox(height: 16),
            const Text(
              'Alarms need three things from Android:\n\n'
              '1. Permission to show notifications.\n'
              '2. Permission to schedule exact alarms.\n'
              '3. No battery optimisation for this app. Without this, '
              'Android may delay alarms when the phone is idle.',
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () async {
                await Permission.notification.request();
                if (await permissionStatus(Permission.scheduleExactAlarm) !=
                    PermissionStatus.granted) {
                  await fixPermission(Permission.scheduleExactAlarm);
                }
              },
              child: const Text('Allow notifications and alarms'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () =>
                  fixPermission(Permission.ignoreBatteryOptimizations),
              child: const Text('Open battery optimisation settings'),
            ),
            const SizedBox(height: 32),
            TextButton(onPressed: onDone, child: const Text('Continue')),
            const SizedBox(height: 8),
            Text(
              'You can check these later in Settings (gear icon on the Today tab).',
              style: t.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
