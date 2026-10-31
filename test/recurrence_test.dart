import 'package:flutter_test/flutter_test.dart';
import 'package:project_todo/data/enums.dart';
import 'package:project_todo/logic/recurrence.dart';

void main() {
  group('stepRecurrence', () {
    test('daily adds one day', () {
      expect(
        stepRecurrence(DateTime(2026, 2, 28), Recurrence.daily),
        DateTime(2026, 3, 1),
      );
    });

    test('daily across the clock change stays at midnight', () {
      // UK clocks go forward on 29 March 2026.
      expect(
        stepRecurrence(DateTime(2026, 3, 28), Recurrence.daily),
        DateTime(2026, 3, 29),
      );
      expect(
        stepRecurrence(DateTime(2026, 3, 29), Recurrence.daily),
        DateTime(2026, 3, 30),
      );
    });

    test('weekly keeps the weekday', () {
      final next = stepRecurrence(DateTime(2026, 10, 30), Recurrence.weekly);
      expect(next, DateTime(2026, 11, 6));
      expect(next.weekday, DateTime.friday);
    });

    test('monthly keeps the day of month', () {
      expect(
        stepRecurrence(DateTime(2026, 1, 15), Recurrence.monthly),
        DateTime(2026, 2, 15),
      );
    });

    test('monthly rolls over the year', () {
      expect(
        stepRecurrence(DateTime(2026, 12, 10), Recurrence.monthly),
        DateTime(2027, 1, 10),
      );
    });

    test('monthly on the 31st falls back to the last day', () {
      expect(
        stepRecurrence(DateTime(2026, 1, 31), Recurrence.monthly, monthDay: 31),
        DateTime(2026, 2, 28),
      );
      expect(
        stepRecurrence(DateTime(2026, 3, 31), Recurrence.monthly, monthDay: 31),
        DateTime(2026, 4, 30),
      );
    });

    test('monthly returns to the 31st after a short month', () {
      expect(
        stepRecurrence(DateTime(2026, 2, 28), Recurrence.monthly, monthDay: 31),
        DateTime(2026, 3, 31),
      );
    });

    test('monthly on the 29th in a leap year', () {
      expect(
        stepRecurrence(DateTime(2028, 1, 29), Recurrence.monthly, monthDay: 29),
        DateTime(2028, 2, 29),
      );
      expect(
        stepRecurrence(DateTime(2027, 1, 29), Recurrence.monthly, monthDay: 29),
        DateTime(2027, 2, 28),
      );
    });

    test('none throws', () {
      expect(
        () => stepRecurrence(DateTime(2026, 1, 1), Recurrence.none),
        throwsArgumentError,
      );
    });
  });

  group('nextDueDate', () {
    test('completed on time gives the next step', () {
      expect(
        nextDueDate(
          DateTime(2026, 10, 31),
          Recurrence.daily,
          today: DateTime(2026, 10, 31),
        ),
        DateTime(2026, 11, 1),
      );
    });

    test('completed early gives the step after the due date', () {
      expect(
        nextDueDate(
          DateTime(2026, 11, 5),
          Recurrence.weekly,
          today: DateTime(2026, 10, 31),
        ),
        DateTime(2026, 11, 12),
      );
    });

    test('overdue daily task skips to tomorrow', () {
      expect(
        nextDueDate(
          DateTime(2026, 10, 25),
          Recurrence.daily,
          today: DateTime(2026, 10, 31, 15),
        ),
        DateTime(2026, 11, 1),
      );
    });

    test('overdue weekly task keeps its weekday', () {
      // Due Monday 19 Oct, completed Saturday 31 Oct.
      final next = nextDueDate(
        DateTime(2026, 10, 19),
        Recurrence.weekly,
        today: DateTime(2026, 10, 31),
      );
      expect(next, DateTime(2026, 11, 2));
      expect(next.weekday, DateTime.monday);
    });

    test('overdue monthly task keeps its anchor day', () {
      expect(
        nextDueDate(
          DateTime(2026, 1, 31),
          Recurrence.monthly,
          today: DateTime(2026, 3, 5),
          monthDay: 31,
        ),
        DateTime(2026, 3, 31),
      );
    });
  });
}
