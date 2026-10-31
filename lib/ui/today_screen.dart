import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logic/sorting.dart';
import '../providers.dart';
import 'format.dart';
import 'settings_screen.dart';
import 'task_editor.dart';
import 'widgets/task_tile.dart';

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  bool _showDone = false;

  @override
  Widget build(BuildContext context) {
    final day = ref.watch(dayProvider);
    final rows = ref.watch(todayTasksProvider);
    final sections = rows.whenData(
      (r) => buildTodaySections(r, DateTime.now()),
    );
    final left = sections.value?.leftToday;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(headerDayFormat.format(day)),
            if (left != null)
              Text(
                left == 1 ? '1 task left today' : '$left tasks left today',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () => openTaskEditor(context, dueDate: day),
        child: const Icon(Icons.add),
      ),
      body: sections.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (s) {
          if (s.overdue.isEmpty && s.today.isEmpty && s.doneToday.isEmpty) {
            return const Center(child: Text('Nothing due today'));
          }
          return ListView(
            padding: const EdgeInsets.only(bottom: 88),
            children: [
              if (s.overdue.isNotEmpty) ...[
                SectionHeader('Overdue', color: Colors.red),
                for (final r in s.overdue)
                  TaskTile(
                    task: r.task,
                    projectName: r.projectName,
                    showDate: true,
                  ),
              ],
              if (s.today.isNotEmpty) ...[
                const SectionHeader('Today'),
                for (final r in s.today)
                  TaskTile(task: r.task, projectName: r.projectName),
              ],
              if (s.doneToday.isNotEmpty) ...[
                ListTile(
                  title: Text('Done today (${s.doneToday.length})'),
                  trailing: Icon(
                    _showDone ? Icons.expand_less : Icons.expand_more,
                  ),
                  onTap: () => setState(() => _showDone = !_showDone),
                ),
                if (_showDone)
                  for (final r in s.doneToday)
                    TaskTile(task: r.task, projectName: r.projectName),
              ],
            ],
          );
        },
      ),
    );
  }
}
