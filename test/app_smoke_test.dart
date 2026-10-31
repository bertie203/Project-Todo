import 'package:drift/drift.dart' show driftRuntimeOptions, Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:project_todo/app.dart';
import 'package:project_todo/data/database.dart';
import 'package:project_todo/logic/dates.dart';
import 'package:project_todo/providers.dart';

void main() {
  late AppDatabase db;

  setUpAll(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    await initializeDateFormatting('en_GB');
  });

  setUp(() => db = AppDatabase(NativeDatabase.memory()));

  /// Lets drift queries finish on real time, then advances frames.
  /// pumpAndSettle is not used because a loading spinner never settles.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dbProvider.overrideWithValue(db)],
        child: const ProjectTodoApp(),
      ),
    );
    await settle(tester);
  }

  /// Unmounts the app so drift stream timers finish. The in-memory
  /// database is not closed: closing it inside a widget test hangs.
  Future<void> closeDb(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await settle(tester);
  }

  testWidgets(
    'shows all four tabs and today tasks',
    timeout: const Timeout(Duration(seconds: 60)),
    (tester) async {
      await tester.runAsync(() async {
        final p = await db.insertProject('House');
        await db.insertTask(
          TasksCompanion.insert(
            title: 'Fix tap',
            projectId: Value(p),
            priority: const Value(Priority.red),
            dueDate: Value(dateOnly(DateTime.now())),
            dueTime: const Value(9 * 60),
          ),
        );
        await db.insertLedgerEntry(
          LedgerEntriesCompanion.insert(
            date: dateOnly(DateTime.now()),
            amountPence: 123456,
            direction: Direction.moneyIn,
            category: LedgerCategory.business,
          ),
        );
      });
      await pumpApp(tester);

      expect(find.text('Fix tap'), findsOneWidget);
      expect(find.text('1 task left today'), findsOneWidget);
      expect(find.text('09:00 · House'), findsOneWidget);

      await tester.tap(find.text('Calendar'));
      await settle(tester);
      expect(find.text('Fix tap'), findsOneWidget);

      await tester.tap(find.text('Projects'));
      await settle(tester);
      expect(find.text('House'), findsOneWidget);
      expect(find.text('1 open'), findsOneWidget);

      await tester.tap(find.text('Ledger'));
      await settle(tester);
      expect(find.text('+£1,234.56'), findsOneWidget);

      await closeDb(tester);
    },
  );

  testWidgets(
    'task and ledger editors open',
    timeout: const Timeout(Duration(seconds: 60)),
    (tester) async {
      await pumpApp(tester);
      await tester.tap(find.byType(FloatingActionButton).first);
      await settle(tester);
      expect(find.text('New task'), findsOneWidget);
      expect(find.text('Alarm'), findsOneWidget);
      await tester.pageBack();
      await settle(tester);

      await tester.tap(find.text('Ledger'));
      await settle(tester);
      await tester.tap(find.byType(FloatingActionButton).last);
      await settle(tester);
      expect(find.text('New entry'), findsOneWidget);
      await tester.pageBack();
      await settle(tester);

      await tester.tap(find.text('Today'));
      await settle(tester);
      await closeDb(tester);
    },
  );
}
