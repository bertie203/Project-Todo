import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../logic/dates.dart';
import '../../providers.dart';
import '../format.dart';
import '../task_editor.dart';

/// A large task card. Tap to show its notes and numbered subtasks;
/// the pencil reschedules.
class TaskCard extends ConsumerStatefulWidget {
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
  ConsumerState<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends ConsumerState<TaskCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final service = ref.read(taskServiceProvider);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final steps = task.subtasks;
    final stepsDone = steps.where((s) => s.done).length;
    final when = <String>[
      if (widget.showDate && task.dueDate != null)
        shortDayFormat.format(task.dueDate!),
      if (task.dueTime != null) formatMinutes(task.dueTime!),
    ];

    final header = InkWell(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Row(
        children: [
          Transform.scale(
            scale: 1.25,
            child: Checkbox(
              value: task.done,
              onChanged: (v) =>
                  v == true ? service.complete(task) : service.uncomplete(task),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      decoration: task.done ? TextDecoration.lineThrough : null,
                      color: task.done ? theme.disabledColor : null,
                    ),
                  ),
                  if (widget.projectName != null) ...[
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
                            widget.projectName!,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (when.isNotEmpty)
                        _Meta(Icons.schedule, when.join(' · '), muted),
                      if (steps.isNotEmpty)
                        _Meta(
                          Icons.checklist,
                          '$stepsDone/${steps.length}',
                          stepsDone == steps.length ? Colors.green : muted,
                        ),
                      if (task.alarm) Icon(Icons.alarm, size: 16, color: muted),
                      if (task.recurrence != Recurrence.none)
                        Icon(Icons.repeat, size: 16, color: muted),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Only tasks with steps show the arrow; all cards still open on tap.
          if (steps.isNotEmpty)
            Icon(
              _expanded ? Icons.expand_less : Icons.expand_more,
              color: Colors.green,
            ),
          if (!task.done)
            IconButton(
              tooltip: 'Reschedule',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => showRescheduleSheet(context, ref, task),
            )
          else
            const SizedBox(width: 12),
        ],
      ),
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 8, color: priorityColor(task.priority)),
            Expanded(
              child: Column(
                children: [header, if (_expanded) _details(context, task)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _details(BuildContext context, Task task) {
    final theme = Theme.of(context);
    final service = ref.read(taskServiceProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          if (task.notes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(task.notes, style: theme.textTheme.bodyMedium),
            ),
          if (task.subtasks.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'No subtasks',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            for (var i = 0; i < task.subtasks.length; i++)
              InkWell(
                onTap: () =>
                    service.setSubtaskDone(task.id, i, !task.subtasks[i].done),
                child: Row(
                  children: [
                    SizedBox(
                      width: 26,
                      child: Text(
                        '${i + 1}.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Checkbox(
                      value: task.subtasks[i].done,
                      onChanged: (v) =>
                          service.setSubtaskDone(task.id, i, v ?? false),
                    ),
                    Expanded(
                      child: Text(
                        task.subtasks[i].title,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          decoration: task.subtasks[i].done
                              ? TextDecoration.lineThrough
                              : null,
                          color: task.subtasks[i].done
                              ? theme.disabledColor
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.edit_note),
              label: Text(task.subtasks.isEmpty ? 'Add subtasks' : 'Edit task'),
              onPressed: () => openTaskEditor(context, existing: task),
            ),
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta(this.icon, this.text, this.color);
  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 4),
      Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color),
      ),
    ],
  );
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
