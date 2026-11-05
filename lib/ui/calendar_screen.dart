import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../data/database.dart';
import '../logic/dates.dart';
import '../logic/sorting.dart';
import '../providers.dart';
import 'format.dart';
import 'task_editor.dart';
import 'widgets/task_card.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _focused;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    _focused = dateOnly(DateTime.now());
    _selected = _focused;
  }

  @override
  Widget build(BuildContext context) {
    final month = DateTime(_focused.year, _focused.month);
    final rows =
        ref.watch(monthTasksProvider(month)).value ?? const <TaskWithProject>[];
    final byDay = <DateTime, List<TaskWithProject>>{};
    for (final r in rows) {
      byDay.putIfAbsent(dateOnly(r.task.dueDate!), () => []).add(r);
    }
    for (final l in byDay.values) {
      l.sort((a, b) {
        if (a.task.done != b.task.done) return a.task.done ? 1 : -1;
        return compareByPriorityThenTime(a.task, b.task);
      });
    }
    final selectedRows =
        byDay[dateOnly(_selected)] ?? const <TaskWithProject>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () => openTaskEditor(context, dueDate: _selected),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          TableCalendar<TaskWithProject>(
            locale: 'en_GB',
            firstDay: DateTime(2000),
            lastDay: DateTime(2100),
            focusedDay: _focused,
            startingDayOfWeek: StartingDayOfWeek.monday,
            availableCalendarFormats: const {CalendarFormat.month: 'Month'},
            selectedDayPredicate: (d) => isSameDay(d, _selected),
            eventLoader: (d) => (byDay[dateOnly(d)] ?? const [])
                .where((r) => !r.task.done)
                .toList(),
            onDaySelected: (sel, foc) => setState(() {
              _selected = dateOnly(sel);
              _focused = dateOnly(foc);
            }),
            onPageChanged: (foc) => setState(() => _focused = dateOnly(foc)),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                if (events.isEmpty) return null;
                return Positioned(
                  bottom: 4,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final e in events.take(3))
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: priorityColor(e.task.priority),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                dayFormat.format(_selected),
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          ),
          Expanded(
            child: selectedRows.isEmpty
                ? const Center(child: Text('No tasks'))
                : ListView(
                    padding: const EdgeInsets.only(bottom: 88),
                    children: [
                      for (final r in selectedRows)
                        TaskCard(task: r.task, projectName: r.projectName),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
