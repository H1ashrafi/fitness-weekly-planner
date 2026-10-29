import 'package:flutter/material.dart';

import '../core/design/app_palette.dart';
import '../core/design/fibonacci_scale.dart';
import 'execute/execute_screen.dart';
import 'movement/movements_screen.dart';
import 'plan/plan_screen.dart';

enum HomeDestination {
  today(label: 'Today', icon: Icons.bolt_rounded),
  plan(label: 'Plan', icon: Icons.calendar_view_week_rounded),
  moves(label: 'Moves', icon: Icons.fitness_center_rounded);

  const HomeDestination({required this.label, required this.icon});

  final String label;
  final IconData icon;

  Widget get screen => switch (this) {
        HomeDestination.today => const ExecuteScreen(),
        HomeDestination.plan => const PlanScreen(),
        HomeDestination.moves => const MovementsScreen(),
      };
}

final class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

final class _HomeShellState extends State<HomeShell> {
  HomeDestination _active = HomeDestination.today;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Scaffold(
      body: IndexedStack(
        index: _active.index,
        children: <Widget>[
          for (final HomeDestination destination in HomeDestination.values)
            destination.screen,
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _active.index,
        backgroundColor: palette.surface,
        indicatorColor: palette.crimsonMuted,
        height: FibonacciSpace.expansive - FibonacciSpace.compact,
        onDestinationSelected: (int index) =>
            setState(() => _active = HomeDestination.values[index]),
        destinations: <Widget>[
          for (final HomeDestination destination in HomeDestination.values)
            NavigationDestination(
              icon: Icon(destination.icon),
              label: destination.label,
            ),
        ],
      ),
    );
  }
}
