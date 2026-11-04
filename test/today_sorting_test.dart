import 'package:flutter_test/flutter_test.dart';
import 'package:project_todo/data/database.dart';
import 'package:project_todo/logic/sorting.dart';

var _id = 0;

TaskWithProject t(
  String title, {
  Priority p = Priority.green,
  DateTime? due,
  int? time,
  bool done = false,
  DateTime? doneAt,
}) => TaskWithProject(
  Task(
    id: ++_id,
    title: title,
    notes: '',
    priority: p,
    dueDate: due,
    dueTime: time,
    alarm: false,
    recurrence: Recurrence.none,
    done: done,
    doneAt: doneAt,
    createdAt: DateTime(2026, 1, 1),
  ),
  null,
);

List<String> titles(List<TaskWithProject> l) =>
    l.map((r) => r.task.title).toList();

void main() {
  final now = DateTime(2026, 10, 31, 14, 0);
  final today = DateTime(2026, 10, 31);
  final yesterday = DateTime(2026, 10, 30);
  final tomorrow = DateTime(2026, 11, 1);

  test('splits tasks into sections', () {
    final s = buildTodaySections([
      t('overdue', due: yesterday),
      t('today', due: today),
      t('tomorrow', due: tomorrow),
      t('undated'),
      t(
        'done today',
        due: today,
        done: true,
        doneAt: DateTime(2026, 10, 31, 9),
      ),
      t(
        'done yesterday',
        due: yesterday,
        done: true,
        doneAt: DateTime(2026, 10, 30, 9),
      ),
      t(
        'done early',
        due: tomorrow,
        done: true,
        doneAt: DateTime(2026, 10, 31, 10),
      ),
    ], now);
    expect(titles(s.overdue), ['overdue']);
    expect(titles(s.today), ['today']);
    expect(titles(s.doneToday), unorderedEquals(['done today', 'done early']));
    expect(s.leftToday, 1);
  });

  test('sorts by priority, then time, untimed last', () {
    final s = buildTodaySections([
      t('green 08:00', p: Priority.green, due: today, time: 480),
      t('red untimed', p: Priority.red, due: today),
      t('orange 09:00', p: Priority.orange, due: today, time: 540),
      t('red 10:00', p: Priority.red, due: today, time: 600),
      t('red 07:30', p: Priority.red, due: today, time: 450),
      t('green untimed', p: Priority.green, due: today),
    ], now);
    expect(titles(s.today), [
      'red 07:30',
      'red 10:00',
      'red untimed',
      'orange 09:00',
      'green 08:00',
      'green untimed',
    ]);
  });

  test('overdue sorted the same way', () {
    final s = buildTodaySections([
      t('green', due: DateTime(2026, 10, 1)),
      t('red', p: Priority.red, due: yesterday),
    ], now);
    expect(titles(s.overdue), ['red', 'green']);
  });

  test('project sort: priority then due date, undated last', () {
    final list = [
      t('green soon', due: tomorrow),
      t('red undated', p: Priority.red),
      t('red later', p: Priority.red, due: DateTime(2026, 12, 1)),
      t('red sooner', p: Priority.red, due: tomorrow),
    ].map((r) => r.task).toList()..sort(compareByPriorityThenDate);
    expect(list.map((x) => x.title), [
      'red sooner',
      'red later',
      'red undated',
      'green soon',
    ]);
  });

  test('other day: open and done tasks due that day', () {
    final s = buildDaySections([
      t('missed green', due: yesterday),
      t('missed red', p: Priority.red, due: yesterday),
      t('done', due: yesterday, done: true, doneAt: yesterday),
      t('other day', due: today),
      t('undated'),
    ], yesterday);
    expect(titles(s.open), ['missed red', 'missed green']);
    expect(titles(s.done), ['done']);
  });

  test('late tasks grouped by day, most recent first', () {
    final twoDaysAgo = DateTime(2026, 10, 29);
    final groups = groupLateTasks([
      t('old green', due: twoDaysAgo),
      t('old red', p: Priority.red, due: twoDaysAgo),
      t('yesterday', due: yesterday),
      t('done late', due: yesterday, done: true, doneAt: today),
      t('today', due: today),
      t('undated'),
    ], now);
    expect(groups.map((g) => g.day), [yesterday, twoDaysAgo]);
    expect(titles(groups[0].tasks), ['yesterday']);
    expect(titles(groups[1].tasks), ['old red', 'old green']);
  });
}
