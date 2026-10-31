import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../logic/sorting.dart';
import '../providers.dart';
import 'task_editor.dart';
import 'widgets/task_tile.dart';

Future<String?> askProjectName(
  BuildContext context, {
  String initial = '',
  required String title,
}) {
  final c = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: c,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(labelText: 'Name'),
        onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, c.text.trim()),
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key});

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  bool _showArchived = false;

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectsProvider);
    final open = ref.watch(openTasksProvider).value ?? const <Task>[];
    final openCount = <int, int>{};
    final redCount = <int, int>{};
    for (final t in open) {
      final p = t.projectId;
      if (p == null) continue;
      openCount[p] = (openCount[p] ?? 0) + 1;
      if (t.priority == Priority.red) redCount[p] = (redCount[p] ?? 0) + 1;
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        actions: [
          IconButton(
            tooltip: _showArchived ? 'Hide archived' : 'Show archived',
            icon: Icon(
              _showArchived ? Icons.inventory_2 : Icons.inventory_2_outlined,
            ),
            onPressed: () => setState(() => _showArchived = !_showArchived),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () async {
          final name = await askProjectName(context, title: 'New project');
          if (name != null && name.isNotEmpty) {
            await ref.read(dbProvider).insertProject(name);
          }
        },
        child: const Icon(Icons.add),
      ),
      body: projects.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          final active = list.where((p) => !p.archived).toList();
          final archived = list.where((p) => p.archived).toList();
          if (active.isEmpty && (!_showArchived || archived.isEmpty)) {
            return const Center(child: Text('No projects'));
          }
          Widget tile(Project p) {
            final n = openCount[p.id] ?? 0;
            final r = redCount[p.id] ?? 0;
            return ListTile(
              title: Text(p.name),
              subtitle: Text('$n open'),
              trailing: r == 0
                  ? null
                  : Chip(
                      label: Text('$r'),
                      backgroundColor: Colors.red,
                      labelStyle: const TextStyle(color: Colors.white),
                    ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProjectScreen(projectId: p.id),
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.only(bottom: 88),
            children: [
              for (final p in active) tile(p),
              if (_showArchived && archived.isNotEmpty) ...[
                const SectionHeader('Archived'),
                for (final p in archived) tile(p),
              ],
            ],
          );
        },
      ),
    );
  }
}

enum _ProjectAction { rename, archive, delete }

class ProjectScreen extends ConsumerStatefulWidget {
  const ProjectScreen({super.key, required this.projectId});
  final int projectId;

  @override
  ConsumerState<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends ConsumerState<ProjectScreen> {
  bool _showDone = false;

  Future<void> _onAction(_ProjectAction a, Project p) async {
    final db = ref.read(dbProvider);
    final service = ref.read(taskServiceProvider);
    switch (a) {
      case _ProjectAction.rename:
        final name = await askProjectName(
          context,
          initial: p.name,
          title: 'Rename project',
        );
        if (name != null && name.isNotEmpty) await db.renameProject(p.id, name);
      case _ProjectAction.archive:
        await service.setProjectArchived(p.id, !p.archived);
      case _ProjectAction.delete:
        final choice = await showDialog<String>(
          context: context,
          builder: (c) => AlertDialog(
            title: Text('Delete "${p.name}"?'),
            content: const Text('What should happen to its tasks?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(c, 'keep'),
                child: const Text('Make standalone'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(c, 'delete'),
                child: const Text('Delete tasks'),
              ),
            ],
          ),
        );
        if (choice == null) return;
        await service.deleteProject(p.id, deleteTasks: choice == 'delete');
        if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectsProvider).value ?? const <Project>[];
    final project = projects.where((p) => p.id == widget.projectId).firstOrNull;
    final tasks =
        ref.watch(projectTasksProvider(widget.projectId)).value ??
        const <Task>[];
    if (project == null) {
      return Scaffold(appBar: AppBar());
    }
    final open = tasks.where((t) => !t.done).toList()
      ..sort(compareByPriorityThenDate);
    final done = tasks.where((t) => t.done).toList()
      ..sort(
        (a, b) => (b.doneAt ?? b.createdAt).compareTo(a.doneAt ?? a.createdAt),
      );
    return Scaffold(
      appBar: AppBar(
        title: Text(
          project.archived ? '${project.name} (archived)' : project.name,
        ),
        actions: [
          PopupMenuButton<_ProjectAction>(
            onSelected: (a) => _onAction(a, project),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: _ProjectAction.rename,
                child: Text('Rename'),
              ),
              PopupMenuItem(
                value: _ProjectAction.archive,
                child: Text(project.archived ? 'Unarchive' : 'Archive'),
              ),
              const PopupMenuItem(
                value: _ProjectAction.delete,
                child: Text('Delete'),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () => openTaskEditor(context, projectId: project.id),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 88),
        children: [
          if (open.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('No open tasks')),
            ),
          for (final t in open) TaskTile(task: t, showDate: true),
          if (done.isNotEmpty) ...[
            ListTile(
              title: Text('Completed (${done.length})'),
              trailing: Icon(_showDone ? Icons.expand_less : Icons.expand_more),
              onTap: () => setState(() => _showDone = !_showDone),
            ),
            if (_showDone)
              for (final t in done) TaskTile(task: t, showDate: true),
          ],
        ],
      ),
    );
  }
}
