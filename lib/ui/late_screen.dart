import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logic/dates.dart';
import '../logic/sorting.dart';
import '../providers.dart';
import 'format.dart';
import 'widgets/task_card.dart';
import 'widgets/task_tile.dart';

/// Tasks not done on the day they were due, grouped by that day.
class LateScreen extends ConsumerWidget {
  const LateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(dayProvider);
    final rows = ref.watch(lateTasksProvider);
    final count = rows.value?.length;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Late'),
            if (count != null && count > 0)
              Text(
                count == 1 ? '1 task not done' : '$count tasks not done',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
      body: rows.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (r) {
          final groups = groupLateTasks(r, DateTime.now());
          if (groups.isEmpty) {
            return const Center(child: Text('Nothing late'));
          }
          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              for (final g in groups) ...[
                SectionHeader(_dayLabel(g.day, today), color: Colors.red),
                for (final t in g.tasks)
                  TaskCard(task: t.task, projectName: t.projectName),
              ],
            ],
          );
        },
      ),
    );
  }
}

String _dayLabel(DateTime day, DateTime today) {
  // Rounded so a clock change (23 or 25 hour day) still counts as one day.
  final days = (dateOnly(today).difference(day).inHours / 24).round();
  final ago = switch (days) {
    <= 1 => 'Yesterday',
    _ => '$days days ago',
  };
  return '${dayFormat.format(day)} · $ago';
}
