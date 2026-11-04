import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/database.dart';
import 'logic/dates.dart';
import 'services/alarms.dart';
import 'services/sync.dart';
import 'services/task_service.dart';

/// Overridden in main() and in tests.
final dbProvider = Provider<AppDatabase>((ref) => throw UnimplementedError());

final alarmsProvider = Provider<AlarmScheduler>((ref) => NoopAlarms());

/// Cloud sync. Overridden in main(); tests get one that is not connected.
final syncProvider = Provider<SyncService>(
  (ref) => SyncService(
    ref.watch(dbProvider),
    alarms: ref.watch(alarmsProvider),
    store: MemorySyncStore(),
  ),
);

final taskServiceProvider = Provider<TaskService>(
  (ref) => TaskService(ref.watch(dbProvider), ref.watch(alarmsProvider)),
);

/// The current date. Refreshed when the app resumes so the Today tab
/// moves on after midnight.
class DayNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => dateOnly(DateTime.now());

  void refresh() {
    final d = dateOnly(DateTime.now());
    if (d != state) state = d;
  }
}

final dayProvider = NotifierProvider<DayNotifier, DateTime>(DayNotifier.new);

final todayTasksProvider = StreamProvider<List<TaskWithProject>>(
  (ref) => ref.watch(dbProvider).watchTodayTasks(ref.watch(dayProvider)),
);

/// Undone tasks whose due day has passed.
final lateTasksProvider = StreamProvider<List<TaskWithProject>>(
  (ref) => ref.watch(dbProvider).watchLateTasks(ref.watch(dayProvider)),
);

/// Tasks due on one day (local midnight). Used by the Today tab when
/// swiped to a day other than today.
final dayTasksProvider = StreamProvider.family<List<TaskWithProject>, DateTime>(
  (ref, day) {
    final next = DateTime(day.year, day.month, day.day + 1);
    return ref.watch(dbProvider).watchTasksBetween(day, next);
  },
);

/// Tasks in a calendar month, keyed by the first day of the month.
/// Also covers the days shown from the next and previous month.
final monthTasksProvider =
    StreamProvider.family<List<TaskWithProject>, DateTime>((ref, month) {
      final from = DateTime(month.year, month.month - 1, 20);
      final to = DateTime(month.year, month.month + 1, 15);
      return ref.watch(dbProvider).watchTasksBetween(from, to);
    });

final projectsProvider = StreamProvider<List<Project>>(
  (ref) => ref.watch(dbProvider).watchProjects(),
);

final openTasksProvider = StreamProvider<List<Task>>(
  (ref) => ref.watch(dbProvider).watchAllOpenTasks(),
);

final projectTasksProvider = StreamProvider.family<List<Task>, int>(
  (ref, projectId) => ref.watch(dbProvider).watchProjectTasks(projectId),
);

final ledgerProvider = StreamProvider<List<LedgerEntry>>(
  (ref) => ref.watch(dbProvider).watchLedger(),
);
