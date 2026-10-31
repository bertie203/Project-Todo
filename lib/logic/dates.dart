DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Combines a date and minutes after midnight into a local DateTime.
DateTime atMinutes(DateTime date, int minutes) =>
    DateTime(date.year, date.month, date.day, minutes ~/ 60, minutes % 60);

int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;
