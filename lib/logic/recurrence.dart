import '../data/enums.dart';
import 'dates.dart';

/// One step forward from [from].
/// [monthDay] is the day of month a monthly task repeats on. If the target
/// month is shorter, the last day of that month is used.
DateTime stepRecurrence(DateTime from, Recurrence r, {int? monthDay}) {
  final d = dateOnly(from);
  switch (r) {
    case Recurrence.none:
      throw ArgumentError('Task does not repeat');
    case Recurrence.daily:
      return DateTime(d.year, d.month, d.day + 1);
    case Recurrence.weekly:
      return DateTime(d.year, d.month, d.day + 7);
    case Recurrence.monthly:
      final day = monthDay ?? d.day;
      final y = d.month == 12 ? d.year + 1 : d.year;
      final m = d.month == 12 ? 1 : d.month + 1;
      final last = daysInMonth(y, m);
      return DateTime(y, m, day > last ? last : day);
  }
}

/// Due date of the next instance after a recurring task is completed.
/// Steps forward from [due] until the date is after [today], so a task that
/// was overdue does not create another overdue instance.
DateTime nextDueDate(
  DateTime due,
  Recurrence r, {
  required DateTime today,
  int? monthDay,
}) {
  final t = dateOnly(today);
  var next = stepRecurrence(due, r, monthDay: monthDay);
  while (!next.isAfter(t)) {
    next = stepRecurrence(next, r, monthDay: monthDay);
  }
  return next;
}
