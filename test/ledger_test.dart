import 'package:flutter_test/flutter_test.dart';
import 'package:project_todo/data/database.dart';
import 'package:project_todo/logic/ledger.dart';
import 'package:project_todo/logic/money.dart';

LedgerEntry e(
  int id,
  DateTime date,
  int pence,
  Direction d,
  LedgerCategory c,
) => LedgerEntry(
  id: id,
  date: date,
  amountPence: pence,
  direction: d,
  category: c,
  note: '',
);

void main() {
  final entries = [
    e(
      1,
      DateTime(2026, 9, 3),
      100000,
      Direction.moneyIn,
      LedgerCategory.business,
    ),
    e(
      2,
      DateTime(2026, 9, 10),
      2550,
      Direction.moneyOut,
      LedgerCategory.business,
    ),
    e(
      3,
      DateTime(2026, 10, 1),
      1999,
      Direction.moneyOut,
      LedgerCategory.personal,
    ),
    e(
      4,
      DateTime(2026, 10, 15),
      5000,
      Direction.moneyIn,
      LedgerCategory.personal,
    ),
    e(
      5,
      DateTime(2026, 10, 20),
      12345,
      Direction.moneyOut,
      LedgerCategory.business,
    ),
  ];

  test('totals over all time', () {
    final t = ledgerTotals(entries);
    expect(t.personal, 5000 - 1999);
    expect(t.business, 100000 - 2550 - 12345);
    expect(t.all, t.personal + t.business);
  });

  test('totals for one month', () {
    final t = ledgerTotals(filterByMonth(entries, DateTime(2026, 10)));
    expect(t.personal, 3001);
    expect(t.business, -12345);
    expect(t.all, -9344);
  });

  test('empty month totals zero', () {
    final t = ledgerTotals(filterByMonth(entries, DateTime(2025, 1)));
    expect([t.personal, t.business, t.all], [0, 0, 0]);
  });

  test('null month means all time', () {
    expect(filterByMonth(entries, null).length, entries.length);
  });

  group('money', () {
    test('formats GBP', () {
      expect(formatPence(123456), '£1,234.56');
      expect(formatPence(5), '£0.05');
      expect(formatPence(0), '£0.00');
      expect(formatPence(-9344), '−£93.44');
    });

    test('parses input', () {
      expect(parsePence('12'), 1200);
      expect(parsePence('12.5'), 1250);
      expect(parsePence('12.05'), 1205);
      expect(parsePence('£1,234.56'), 123456);
      expect(parsePence(' 3. '), 300);
      expect(parsePence('1.234'), isNull);
      expect(parsePence('-5'), isNull);
      expect(parsePence('abc'), isNull);
      expect(parsePence(''), isNull);
    });

    test('round trips edit text', () {
      expect(penceToInput(123456), '1234.56');
      expect(penceToInput(5), '0.05');
      expect(parsePence(penceToInput(98765)), 98765);
    });
  });
}
