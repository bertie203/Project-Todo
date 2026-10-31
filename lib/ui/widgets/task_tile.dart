import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../providers.dart';
import '../format.dart';
import '../task_editor.dart';

class TaskTile extends ConsumerWidget {
  const TaskTile({
    super.key,
    required this.task,
    this.projectName,
    this.showDate = false,
  });

  final Task task;
  final String? projectName;
  final bool showDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(taskServiceProvider);
    final theme = Theme.of(context);
    final details = <String>[
      if (showDate && task.dueDate != null)
        shortDayFormat.format(task.dueDate!),
      if (task.dueTime != null) formatMinutes(task.dueTime!),
      ?projectName,
    ];
    return InkWell(
      onTap: () => openTaskEditor(context, existing: task),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 6, color: priorityColor(task.priority)),
            Checkbox(
              value: task.done,
              onChanged: (v) {
                if (v == true) {
                  service.complete(task);
                } else {
                  service.uncomplete(task);
                }
              },
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      task.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        decoration: task.done
                            ? TextDecoration.lineThrough
                            : null,
                        color: task.done ? theme.disabledColor : null,
                      ),
                    ),
                    if (details.isNotEmpty)
                      Text(
                        details.join(' · '),
                        style: theme.textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            ),
            if (task.alarm)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.alarm, size: 18),
              ),
            if (task.recurrence != Recurrence.none)
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(Icons.repeat, size: 18),
              ),
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.text, {super.key, this.color});
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleSmall
          ?.copyWith(color: color ?? Theme.of(context).colorScheme.primary),
    ),
  );
}
