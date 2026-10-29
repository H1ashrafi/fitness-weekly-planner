import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hanimob2/application/providers.dart';
import 'package:hanimob2/core/design/app_theme.dart';
import 'package:hanimob2/core/time/clock.dart';
import 'package:hanimob2/presentation/home_shell.dart';
import 'package:hanimob2/presentation/widgets/set_outcome_control.dart';

import '../support/fake_repositories.dart';

void main() {
  late InMemoryMovementRepository movements;
  late InMemoryRoutineRepository routines;
  late InMemoryMuscleGroupRepository muscles;
  late InMemoryExecutionRepository executions;

  final DateTime wednesdayOfWeek29 = DateTime(2026, 7, 15, 9);

  setUp(() {
    movements = InMemoryMovementRepository();
    routines = InMemoryRoutineRepository(movements);
    muscles = InMemoryMuscleGroupRepository();
    executions = InMemoryExecutionRepository();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          routineRepositoryProvider.overrideWithValue(routines),
          movementRepositoryProvider.overrideWithValue(movements),
          muscleGroupRepositoryProvider.overrideWithValue(muscles),
          executionRepositoryProvider.overrideWithValue(executions),
          clockProvider.overrideWithValue(FixedClock(wednesdayOfWeek29)),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const HomeShell(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openPlanTab(WidgetTester tester) async {
    await tester.tap(find.text('Plan'));
    await tester.pumpAndSettle();
  }

  Future<void> openTodayTab(WidgetTester tester) async {
    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();
  }

  Future<void> composeExercise(
    WidgetTester tester, {
    required String name,
  }) async {
    await tester.tap(find.text('Add exercise'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create a new movement'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, name);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Create movement'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create movement'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Add to plan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to plan'));
    await tester.pumpAndSettle();
  }

  testWidgets('a fresh install opens on Today as a rest day', (tester) async {
    await pumpApp(tester);

    expect(find.text('Wednesday'), findsOneWidget);
    expect(find.text('Nothing scheduled today'), findsOneWidget);
  });

  testWidgets('planning an exercise makes it executable the same day',
      (tester) async {
    await pumpApp(tester);
    await openPlanTab(tester);

    expect(find.textContaining('is a rest day'), findsOneWidget);

    await composeExercise(tester, name: 'Barbell Bench Press');

    expect(find.text('Barbell Bench Press'), findsOneWidget);
    expect(find.text('4 × 15'), findsOneWidget);

    await openTodayTab(tester);

    expect(find.text('Barbell Bench Press'), findsOneWidget);
    expect(find.text('Set 1'), findsOneWidget);
    expect(find.text('Set 4'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);
  });

  testWidgets('ticking sets drives the completion dial', (tester) async {
    await pumpApp(tester);
    await openPlanTab(tester);
    await composeExercise(tester, name: 'Incline Press');
    await openTodayTab(tester);

    expect(find.text('0%'), findsOneWidget);

    final Finder completeButtons = find.descendant(
      of: find.byType(SetOutcomeControl),
      matching: find.byIcon(Icons.check_rounded),
    );
    expect(completeButtons, findsNWidgets(4));

    await tester.tap(completeButtons.first);
    await tester.pumpAndSettle();

    expect(find.text('25%'), findsOneWidget);
    expect(find.text('1 of 4 sets'), findsOneWidget);
  });

  testWidgets('a failed set counts as resolved but not completed',
      (tester) async {
    await pumpApp(tester);
    await openPlanTab(tester);
    await composeExercise(tester, name: 'Cable Fly');
    await openTodayTab(tester);

    final Finder failButtons = find.descendant(
      of: find.byType(SetOutcomeControl),
      matching: find.byIcon(Icons.close_rounded),
    );

    await tester.tap(failButtons.first);
    await tester.pumpAndSettle();

    expect(find.text('0%'), findsOneWidget);
    expect(find.text('0 of 4 sets'), findsOneWidget);
  });

  testWidgets('clearing every set celebrates a perfect day', (tester) async {
    await pumpApp(tester);
    await openPlanTab(tester);
    await composeExercise(tester, name: 'Dumbbell Press');
    await openTodayTab(tester);

    final Finder completeButtons = find.descendant(
      of: find.byType(SetOutcomeControl),
      matching: find.byIcon(Icons.check_rounded),
    );

    for (int index = 0; index < 4; index++) {
      await tester.ensureVisible(completeButtons.at(index));
      await tester.pumpAndSettle();
      await tester.tap(completeButtons.at(index));
      await tester.pumpAndSettle();
    }

    expect(find.text('100%'), findsOneWidget);
    expect(find.text('Every set cleared today'), findsOneWidget);
  });

  testWidgets('tapping a completed set again returns it to pending',
      (tester) async {
    await pumpApp(tester);
    await openPlanTab(tester);
    await composeExercise(tester, name: 'Chest Press');
    await openTodayTab(tester);

    final Finder completeButtons = find.descendant(
      of: find.byType(SetOutcomeControl),
      matching: find.byIcon(Icons.check_rounded),
    );

    await tester.tap(completeButtons.first);
    await tester.pumpAndSettle();
    expect(find.text('25%'), findsOneWidget);

    await tester.tap(completeButtons.first);
    await tester.pumpAndSettle();
    expect(find.text('0%'), findsOneWidget);
  });

  testWidgets('execution state survives a rebuild of the app', (tester) async {
    await pumpApp(tester);
    await openPlanTab(tester);
    await composeExercise(tester, name: 'Pec Deck');
    await openTodayTab(tester);

    await tester.tap(
      find
          .descendant(
            of: find.byType(SetOutcomeControl),
            matching: find.byIcon(Icons.check_rounded),
          )
          .first,
    );
    await tester.pumpAndSettle();
    expect(find.text('25%'), findsOneWidget);

    await pumpApp(tester);

    expect(find.text('Pec Deck'), findsOneWidget);
    expect(find.text('25%'), findsOneWidget);
  });
}
