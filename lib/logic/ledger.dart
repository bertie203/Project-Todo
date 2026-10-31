import '../data/database.dart';

class LedgerTotals {
  const LedgerTotals(this.personal, this.business);
  final int personal;
  final int business;
  int get all => personal + business;
}

int signedPence(LedgerEntry e) =>
    e.direction == Direction.moneyIn ? e.amountPence : -e.amountPence;

LedgerTotals ledgerTotals(Iterable<LedgerEntry> entries) {
  var personal = 0;
  var business = 0;
  for (final e in entries) {
    if (e.category == LedgerCategory.personal) {
      personal += signedPence(e);
    } else {
      business += signedPence(e);
    }
  }
  return LedgerTotals(personal, business);
}

/// A month, or null for all time.
List<LedgerEntry> filterByMonth(List<LedgerEntry> entries, DateTime? month) {
  if (month == null) return entries;
  return entries
      .where((e) => e.date.year == month.year && e.date.month == month.month)
      .toList();
}
