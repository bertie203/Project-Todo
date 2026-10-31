import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/enums.dart';

Color priorityColor(Priority p) => switch (p) {
  Priority.red => Colors.red,
  Priority.orange => Colors.orange,
  Priority.green => Colors.green,
};

String priorityLabel(Priority p) => switch (p) {
  Priority.red => 'Red',
  Priority.orange => 'Orange',
  Priority.green => 'Green',
};

String recurrenceLabel(Recurrence r) => switch (r) {
  Recurrence.none => 'Does not repeat',
  Recurrence.daily => 'Daily',
  Recurrence.weekly => 'Weekly',
  Recurrence.monthly => 'Monthly',
};

String formatMinutes(int minutes) =>
    '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';

final dayFormat = DateFormat('EEE d MMM yyyy', 'en_GB');
final shortDayFormat = DateFormat('d MMM', 'en_GB');
final monthFormat = DateFormat('MMMM yyyy', 'en_GB');
final headerDayFormat = DateFormat('EEEE d MMMM', 'en_GB');
