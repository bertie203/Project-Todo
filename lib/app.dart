import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';
import 'ui/calendar_screen.dart';
import 'ui/first_run_screen.dart';
import 'ui/ledger_screen.dart';
import 'ui/projects_screen.dart';
import 'ui/today_screen.dart';

final navigatorKey = GlobalKey<NavigatorState>();

class ProjectTodoApp extends StatelessWidget {
  const ProjectTodoApp({super.key, this.firstRun = false, this.onFirstRunDone});

  final bool firstRun;
  final Future<void> Function()? onFirstRunDone;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Project Todo',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: _Root(firstRun: firstRun, onFirstRunDone: onFirstRunDone),
    );
  }
}

class _Root extends StatefulWidget {
  const _Root({required this.firstRun, this.onFirstRunDone});
  final bool firstRun;
  final Future<void> Function()? onFirstRunDone;

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  late bool _firstRun = widget.firstRun;

  @override
  Widget build(BuildContext context) {
    if (_firstRun) {
      return FirstRunScreen(
        onDone: () async {
          await widget.onFirstRunDone?.call();
          setState(() => _firstRun = false);
        },
      );
    }
    return const HomeShell();
  }
}

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell>
    with WidgetsBindingObserver {
  int _tab = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Moves the Today tab on at midnight while the app is open.
    _timer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => ref.read(dayProvider.notifier).refresh(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(dayProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: const [
          TodayScreen(),
          CalendarScreen(),
          ProjectsScreen(),
          LedgerScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.today), label: 'Today'),
          NavigationDestination(
            icon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          NavigationDestination(icon: Icon(Icons.folder), label: 'Projects'),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Ledger',
          ),
        ],
      ),
    );
  }
}
