import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import '../providers.dart';
import '../services/backup.dart';
import '../services/permissions.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with WidgetsBindingObserver {
  Map<Permission, PermissionStatus> _status = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final m = <Permission, PermissionStatus>{};
    for (final p in appPermissions) {
      m[p.permission] = await permissionStatus(p.permission);
    }
    if (mounted) setState(() => _status = m);
  }

  void _snack(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _export() async {
    try {
      final json = await exportJson(ref.read(dbProvider));
      final dir = await getTemporaryDirectory();
      final now = DateTime.now();
      final stamp =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      final file = File('${dir.path}/project-todo-$stamp.json');
      await file.writeAsString(json);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/json')],
          subject: 'Project-Todo backup',
        ),
      );
    } catch (e) {
      _snack('Export failed: $e');
    }
  }

  Future<void> _import() async {
    final picked = await FilePicker.pickFile();
    if (picked == null) return;
    final BackupData data;
    try {
      data = parseBackup(await picked.xFile.readAsString());
    } on FormatException catch (e) {
      _snack(e.message);
      return;
    } catch (e) {
      _snack('Could not read file: $e');
      return;
    }
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Replace all data?'),
        content: Text(
          'This deletes everything in the app and loads '
          '${data.tasks.length} tasks, ${data.projects.length} projects and '
          '${data.ledger.length} ledger entries from the file.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Replace'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final db = ref.read(dbProvider);
    await importBackup(db, data);
    await ref.read(alarmsProvider).rescheduleAll(db);
    _snack('Import complete');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _Header('Backup'),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('Export'),
            subtitle: const Text('Save all data to a JSON file'),
            onTap: _export,
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Import'),
            subtitle: const Text('Replace all data from a JSON file'),
            onTap: _import,
          ),
          const _Header('Permissions'),
          for (final p in appPermissions) _permissionTile(p),
        ],
      ),
    );
  }

  Widget _permissionTile(PermissionInfo p) {
    final s = _status[p.permission];
    final granted = s?.isGranted ?? false;
    return ListTile(
      leading: Icon(
        granted ? Icons.check_circle : Icons.error_outline,
        color: granted ? Colors.green : Colors.red,
      ),
      title: Text(p.label),
      subtitle: Text(p.help),
      trailing: granted || s == null
          ? null
          : TextButton(
              onPressed: () async {
                await fixPermission(p.permission);
                await _refresh();
              },
              child: const Text('Fix'),
            ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleSmall
          ?.copyWith(color: Theme.of(context).colorScheme.primary),
    ),
  );
}
