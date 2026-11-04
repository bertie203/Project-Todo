import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers.dart';
import '../services/sync.dart';

final _timeFormat = DateFormat('d MMM, HH:mm', 'en_GB');

/// Cloud sync status and controls for the Settings screen.
class SyncSection extends ConsumerWidget {
  const SyncSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(syncProvider);
    return ListenableBuilder(
      listenable: sync,
      builder: (context, _) {
        if (!sync.connected) {
          return ListTile(
            leading: const Icon(Icons.cloud_off),
            title: const Text('Not connected'),
            subtitle: Text(
              sync.lastError ??
                  'Connect to share tasks and projects with Claude.',
            ),
            trailing: FilledButton(
              onPressed: () => _connect(context, sync),
              child: const Text('Connect'),
            ),
          );
        }
        final status = sync.syncing
            ? 'Syncing…'
            : sync.lastError != null
            ? sync.lastError!
            : sync.lastSync == null
            ? 'Not synced yet'
            : 'Last synced ${_timeFormat.format(sync.lastSync!)}';
        return Column(
          children: [
            ListTile(
              leading: Icon(
                sync.lastError != null ? Icons.cloud_off : Icons.cloud_done,
                color: sync.lastError != null ? Colors.red : Colors.green,
              ),
              title: const Text('Connected'),
              subtitle: Text(status),
              trailing: sync.syncing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      tooltip: 'Sync now',
                      icon: const Icon(Icons.sync),
                      onPressed: sync.syncNow,
                    ),
            ),
            ListTile(
              leading: const Icon(Icons.link_off),
              title: const Text('Disconnect'),
              subtitle: const Text('Tasks stay on this phone'),
              onTap: () => _disconnect(context, sync),
            ),
          ],
        );
      },
    );
  }

  Future<void> _connect(BuildContext context, SyncService sync) async {
    final url = TextEditingController(text: sync.serverUrl ?? defaultServerUrl);
    final password = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Connect to the cloud'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: url,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(labelText: 'Server'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: password,
              autofocus: true,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
              onSubmitted: (_) => Navigator.pop(c, true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Connect'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await sync.connect(url.text, password.text);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            sync.lastError == null
                ? 'Connected and synced'
                : 'Connected, but sync failed: ${sync.lastError}',
          ),
        ),
      );
    } on SyncException catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            e.status == 401 ? 'Wrong password' : 'Could not connect: $e',
          ),
        ),
      );
    } on FormatException {
      messenger.showSnackBar(
        const SnackBar(content: Text('That server address is not valid')),
      );
    }
  }

  Future<void> _disconnect(BuildContext context, SyncService sync) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Disconnect?'),
        content: const Text(
          'Changes will stop syncing. Your tasks stay on this phone and in '
          'the cloud.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
    if (ok == true) await sync.disconnect();
  }
}
