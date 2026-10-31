import 'package:intl/intl.dart';

final _gbp = NumberFormat.currency(
  locale: 'en_GB',
  symbol: '£',
  decimalDigits: 2,
);

/// 123456 -> £1,234.56. Negative values get a leading minus sign.
String formatPence(int pence) {
  final s = _gbp.format(pence.abs() / 100);
  return pence < 0 ? '−$s' : s;
}

/// Parses user input such as "12", "12.5", "£1,234.56" into pence.
/// Returns null if the text is not a valid non-negative amount.
int? parsePence(String input) {
  final s = input.replaceAll(RegExp(r'[£,\s]'), '');
  final m = RegExp(r'^(\d+)(?:\.(\d{0,2}))?$').firstMatch(s);
  if (m == null) return null;
  final pounds = int.parse(m.group(1)!);
  final frac = (m.group(2) ?? '').padRight(2, '0');
  return pounds * 100 + int.parse(frac);
}

/// Pence as plain text for an edit field: 123456 -> "1234.56".
String penceToInput(int pence) =>
    '${pence ~/ 100}.${(pence % 100).toString().padLeft(2, '0')}';
