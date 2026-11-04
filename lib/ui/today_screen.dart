import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../logic/sorting.dart';
import '../providers.dart';
import 'format.dart';
import 'settings_screen.dart';
import 'task_editor.dart';
import 'widgets/task_card.dart';
import 'widgets/task_tile.dart';

/// Page index of today. Swiping left or right moves one day.
const _todayPage = 10000;

DateTime _dayFor(DateTime today, int page) =>
    DateTime(today.year, today.month, today.day + page - _todayPage);

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  final _pages = PageController(initialPage: _todayPage);
  int _page = _todayPage;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _goTo(int page) => _pages.animateToPage(
    page,
    duration: const Duration(milliseconds: 250),
    curve: Curves.easeOut,
  );

  String _countText(int n, String when) =>
      n == 1 ? '1 task left $when' : '$n tasks left $when';

  @override
  Widget build(BuildContext context) {
    final today = ref.watch(dayProvider);
    final day = _dayFor(today, _page);
    final offset = _page - _todayPage;

    int? left;
    String subtitle;
    if (offset == 0) {
      final rows = ref.watch(todayTasksProvider).value;
      left = rows == null
          ? null
          : buildTodaySections(rows, DateTime.now()).leftToday;
      subtitle = left == null ? '' : _countText(left, 'today');
    } else {
      final rows = ref.watch(dayTasksProvider(day)).value;
      left = rows == null ? null : buildDaySections(rows, day).open.length;
      final label = switch (offset) {
        -1 => 'Yesterday',
        1 => 'Tomorrow',
        _ => null,
      };
      final count = left == null
          ? ''
          : offset < 0
          ? (left == 1 ? '1 not done' : '$left not done')
          : (left == 1 ? '1 task' : '$left tasks');
      subtitle = [?label, if (count.isNotEmpty) count].join(' · ');
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(headerDayFormat.format(day)),
            if (subtitle.isNotEmpty)
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Previous day',
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _goTo(_page - 1),
          ),
          if (offset != 0)
            IconButton(
              tooltip: 'Back to today',
              icon: const Icon(Icons.today),
              onPressed: () => _goTo(_todayPage),
            ),
          IconButton(
            tooltip: 'Next day',
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _goTo(_page + 1),
          ),
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
      body: PageView.builder(
        controller: _pages,
        onPageChanged: (p) => setState(() => _page = p),
        itemBuilder: (_, page) {
          final offset = page - _todayPage;
          return offset == 0
              ? const _TodayPage()
              : _OtherDayPage(day: _dayFor(today, page), past: offset < 0);
        },
      ),
    );
  }
}

/// Today: overdue, due today, and done today.
class _TodayPage extends ConsumerStatefulWidget {
  const _TodayPage();

  @override
  ConsumerState<_TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends ConsumerState<_TodayPage> {
  bool _showDone = false;

  @override
  Widget build(BuildContext context) {
    final sections = ref
        .watch(todayTasksProvider)
        .whenData((r) => buildTodaySections(r, DateTime.now()));
    return sections.when(
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
                TaskCard(
                  task: r.task,
                  projectName: r.projectName,
                  showDate: true,
                ),
            ],
            if (s.today.isNotEmpty) ...[
              const SectionHeader('Today'),
              for (final r in s.today)
                TaskCard(task: r.task, projectName: r.projectName),
            ],
            ..._doneSection(
              'Done today',
              s.doneToday,
              _showDone,
              () => setState(() => _showDone = !_showDone),
            ),
          ],
        );
      },
    );
  }
}

/// Any other day: tasks due that day, open first, done below.
class _OtherDayPage extends ConsumerStatefulWidget {
  const _OtherDayPage({required this.day, required this.past});
  final DateTime day;
  final bool past;

  @override
  ConsumerState<_OtherDayPage> createState() => _OtherDayPageState();
}

class _OtherDayPageState extends ConsumerState<_OtherDayPage> {
  bool _showDone = false;

  @override
  Widget build(BuildContext context) {
    final sections = ref
        .watch(dayTasksProvider(widget.day))
        .whenData((r) => buildDaySections(r, widget.day));
    return sections.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (s) {
        if (s.open.isEmpty && s.done.isEmpty) {
          return const Center(child: Text('Nothing due this day'));
        }
        return ListView(
          padding: const EdgeInsets.only(bottom: 88),
          children: [
            if (s.open.isNotEmpty) ...[
              widget.past
                  ? SectionHeader('Not done', color: Colors.red)
                  : const SectionHeader('Due'),
              for (final r in s.open)
                TaskCard(task: r.task, projectName: r.projectName),
            ],
            ..._doneSection(
              'Done',
              s.done,
              _showDone,
              () => setState(() => _showDone = !_showDone),
            ),
          ],
        );
      },
    );
  }
}

List<Widget> _doneSection(
  String title,
  List<TaskWithProject> done,
  bool expanded,
  VoidCallback toggle,
) {
  if (done.isEmpty) return const [];
  return [
    ListTile(
      title: Text('$title (${done.length})'),
      trailing: Icon(expanded ? Icons.expand_less : Icons.expand_more),
      onTap: toggle,
    ),
    if (expanded)
      for (final r in done) TaskCard(task: r.task, projectName: r.projectName),
  ];
}
