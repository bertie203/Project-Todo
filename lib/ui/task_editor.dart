import 'package:flutter/material.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../logic/dates.dart';
import '../providers.dart';
import 'format.dart';

Future<void> openTaskEditor(
  BuildContext context, {
  Task? existing,
  DateTime? dueDate,
  int? projectId,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => TaskEditor(
        existing: existing,
        dueDate: dueDate,
        projectId: projectId,
      ),
    ),
  );
}

Future<void> openTaskEditorById(
  BuildContext context,
  AppDatabase db,
  int id,
) async {
  final t = await db.getTask(id);
  if (t != null && context.mounted) await openTaskEditor(context, existing: t);
}

class TaskEditor extends ConsumerStatefulWidget {
  const TaskEditor({super.key, this.existing, this.dueDate, this.projectId});
  final Task? existing;
  final DateTime? dueDate;
  final int? projectId;

  @override
  ConsumerState<TaskEditor> createState() => _TaskEditorState();
}

class _TaskEditorState extends ConsumerState<TaskEditor> {
  late final TextEditingController _title;
  late final TextEditingController _notes;
  late Priority _priority;
  int? _projectId;
  DateTime? _date;
  TimeOfDay? _time;
  late bool _alarm;
  late Recurrence _recurrence;

  bool get _isNew => widget.existing == null;

  @override
  void initState() {
    super.initState();
    final t = widget.existing;
    _title = TextEditingController(text: t?.title ?? '');
    _notes = TextEditingController(text: t?.notes ?? '');
    _priority = t?.priority ?? Priority.green;
    _projectId = t?.projectId ?? widget.projectId;
    _date = t?.dueDate ?? widget.dueDate;
    _time = t?.dueTime == null
        ? null
        : TimeOfDay(hour: t!.dueTime! ~/ 60, minute: t.dueTime! % 60);
    _alarm = t?.alarm ?? false;
    _recurrence = t?.recurrence ?? Recurrence.none;
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Title is required')));
      return;
    }
    final service = ref.read(taskServiceProvider);
    final minutes = _time == null ? null : _time!.hour * 60 + _time!.minute;
    final old = widget.existing;
    final base =
        old ??
        Task(
          id: 0,
          title: title,
          notes: '',
          priority: Priority.green,
          alarm: false,
          recurrence: Recurrence.none,
          done: false,
          createdAt: DateTime.now(),
        );
    // Keep the monthly repeat day unless the date or recurrence changed.
    final keepDay =
        old != null &&
        old.recurrence == _recurrence &&
        old.dueDate != null &&
        _date != null &&
        sameDay(old.dueDate!, _date!);
    final task = base.copyWith(
      title: title,
      notes: _notes.text.trim(),
      priority: _priority,
      projectId: Value(_projectId),
      dueDate: Value(_date == null ? null : dateOnly(_date!)),
      dueTime: Value(_date == null ? null : minutes),
      alarm: _alarm && _date != null && minutes != null,
      recurrence: _date == null ? Recurrence.none : _recurrence,
      recurrenceDay: Value(keepDay ? old.recurrenceDay : null),
    );
    if (_isNew) {
      await service.create(task);
    } else {
      await service.save(task);
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(taskServiceProvider).delete(widget.existing!.id);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 10),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (t != null) setState(() => _time = t);
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectsProvider).value ?? const <Project>[];
    final selectable = projects
        .where((p) => !p.archived || p.id == _projectId)
        .toList();
    final canAlarm = _date != null && _time != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'New task' : 'Edit task'),
        actions: [
          if (!_isNew)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
          IconButton(icon: const Icon(Icons.check), onPressed: _save),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _title,
            autofocus: _isNew,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notes,
            minLines: 2,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Notes'),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              for (final p in Priority.values)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _PriorityButton(
                      priority: p,
                      selected: p == _priority,
                      onTap: () => setState(() => _priority = p),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<int?>(
            initialValue: _projectId,
            decoration: const InputDecoration(labelText: 'Project'),
            items: [
              const DropdownMenuItem(value: null, child: Text('None')),
              for (final p in selectable)
                DropdownMenuItem(value: p.id, child: Text(p.name)),
            ],
            onChanged: (v) => setState(() => _projectId = v),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event),
            title: Text(_date == null ? 'No date' : dayFormat.format(_date!)),
            onTap: _pickDate,
            trailing: _date == null
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() {
                      _date = null;
                      _time = null;
                      _alarm = false;
                      _recurrence = Recurrence.none;
                    }),
                  ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            enabled: _date != null,
            leading: const Icon(Icons.schedule),
            title: Text(
              _time == null
                  ? 'No time'
                  : formatMinutes(_time!.hour * 60 + _time!.minute),
            ),
            onTap: _date == null ? null : _pickTime,
            trailing: _time == null
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() {
                      _time = null;
                      _alarm = false;
                    }),
                  ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.alarm),
            title: const Text('Alarm'),
            subtitle: canAlarm ? null : const Text('Needs a date and time'),
            value: _alarm && canAlarm,
            onChanged: canAlarm ? (v) => setState(() => _alarm = v) : null,
          ),
          DropdownButtonFormField<Recurrence>(
            initialValue: _recurrence,
            decoration: InputDecoration(
              labelText: 'Repeat',
              helperText: _date == null ? 'Needs a date' : null,
            ),
            items: [
              for (final r in Recurrence.values)
                DropdownMenuItem(value: r, child: Text(recurrenceLabel(r))),
            ],
            onChanged: _date == null
                ? null
                : (v) => setState(() => _recurrence = v!),
          ),
        ],
      ),
    );
  }
}

class _PriorityButton extends StatelessWidget {
  const _PriorityButton({
    required this.priority,
    required this.selected,
    required this.onTap,
  });
  final Priority priority;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = priorityColor(priority);
    return Material(
      color: selected ? c : c.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: SizedBox(
          height: 44,
          child: Center(
            child: Text(
              priorityLabel(priority),
              style: TextStyle(
                color: selected ? Colors.white : c,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
