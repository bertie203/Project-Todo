import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../logic/dates.dart';
import '../../providers.dart';
import '../format.dart';
import '../task_editor.dart';

/// A large task card for the Today tab, with a pencil to reschedule.
class TaskCard extends ConsumerWidget {
  const TaskCard({
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
    final muted = theme.colorScheme.onSurfaceVariant;
    final when = <String>[
      if (showDate && task.dueDate != null)
        shortDayFormat.format(task.dueDate!),
      if (task.dueTime != null) formatMinutes(task.dueTime!),
    ];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: () => openTaskEditor(context, existing: task),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 8, color: priorityColor(task.priority)),
              Center(
                child: Transform.scale(
                  scale: 1.25,
                  child: Checkbox(
                    value: task.done,
                    onChanged: (v) => v == true
                        ? service.complete(task)
                        : service.uncomplete(task),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        task.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration: task.done
                              ? TextDecoration.lineThrough
                              : null,
                          color: task.done ? theme.disabledColor : null,
                        ),
                      ),
                      if (projectName != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.folder_outlined,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                projectName!,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (when.isNotEmpty ||
                          task.alarm ||
                          task.recurrence != Recurrence.none) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (when.isNotEmpty) ...[
                              Icon(Icons.schedule, size: 16, color: muted),
                              const SizedBox(width: 4),
                              Text(
                                when.join(' · '),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: muted,
                                ),
                              ),
                              const SizedBox(width: 10),
                            ],
                            if (task.alarm)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Icon(
                                  Icons.alarm,
                                  size: 16,
                                  color: muted,
                                ),
                              ),
                            if (task.recurrence != Recurrence.none)
                              Icon(Icons.repeat, size: 16, color: muted),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (!task.done)
                Center(
                  child: IconButton(
                    tooltip: 'Reschedule',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => showRescheduleSheet(context, ref, task),
                  ),
                )
              else
                const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }
}

/// Quick ways to move a task, with an Undo snackbar.
Future<void> showRescheduleSheet(
  BuildContext context,
  WidgetRef ref,
  Task task,
) async {
  final service = ref.read(taskServiceProvider);
  final messenger = ScaffoldMessenger.of(context);
  final today = dateOnly(DateTime.now());
  final tomorrow = DateTime(today.year, today.month, today.day + 1);
  final nextWeek = DateTime(today.year, today.month, today.day + 7);

  Future<void> move(DateTime date, int? minutes) async {
    final before = task;
    await service.reschedule(task, date, minutes);
    final at = minutes == null ? '' : ' at ${formatMinutes(minutes)}';
    messenger.showSnackBar(
      SnackBar(
        content: Text('Moved to ${dayFormat.format(date)}$at'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => service.save(before),
        ),
      ),
    );
  }

  final choice = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (c) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(
              task.title,
              style: Theme.of(c).textTheme.titleMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.wb_sunny_outlined),
            title: const Text('Tomorrow'),
            subtitle: Text(dayFormat.format(tomorrow)),
            onTap: () => Navigator.pop(c, 'tomorrow'),
          ),
          ListTile(
            leading: const Icon(Icons.date_range),
            title: const Text('Next week'),
            subtitle: Text(dayFormat.format(nextWeek)),
            onTap: () => Navigator.pop(c, 'week'),
          ),
          ListTile(
            leading: const Icon(Icons.edit_calendar),
            title: const Text('Pick date and time'),
            onTap: () => Navigator.pop(c, 'pick'),
          ),
          ListTile(
            leading: const Icon(Icons.edit_note),
            title: const Text('Edit task'),
            onTap: () => Navigator.pop(c, 'edit'),
          ),
        ],
      ),
    ),
  );
  if (!context.mounted) return;

  switch (choice) {
    case 'tomorrow':
      await move(tomorrow, task.dueTime);
    case 'week':
      await move(nextWeek, task.dueTime);
    case 'edit':
      await openTaskEditor(context, existing: task);
    case 'pick':
      final start = task.dueDate == null || task.dueDate!.isBefore(today)
          ? today
          : task.dueDate!;
      final date = await showDatePicker(
        context: context,
        initialDate: start,
        firstDate: DateTime(today.year - 1),
        lastDate: DateTime(today.year + 10),
        helpText: 'Move to date',
      );
      if (date == null || !context.mounted) return;
      final current = task.dueTime;
      final time = await showTimePicker(
        context: context,
        helpText: 'Time (Cancel keeps current)',
        initialTime: current == null
            ? const TimeOfDay(hour: 9, minute: 0)
            : TimeOfDay(hour: current ~/ 60, minute: current % 60),
      );
      await move(date, time == null ? current : time.hour * 60 + time.minute);
  }
}
