import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/time/clock.dart';
import '../core/time/week_stamp.dart';
import '../domain/entities/exercise.dart';
import '../domain/entities/set_execution.dart';
import '../domain/entities/set_outcome.dart';
import '../domain/entities/weekday.dart';
import '../domain/repositories/execution_repository.dart';
import 'execution_snapshot.dart';
import 'providers.dart';
import 'routine_controller.dart';

final class ExecutionController extends AsyncNotifier<ExecutionSnapshot> {
  @override
  Future<ExecutionSnapshot> build() async {
    final Clock clock = ref.watch(clockProvider);
    final Weekday weekday = clock.today;
    final WeekStamp week = clock.currentWeek;

    final WeeklyRoutine routine = await ref.watch(routineControllerProvider.future);
    final List<Exercise> exercises = routine[weekday] ?? const <Exercise>[];
    if (exercises.isEmpty) {
      return ExecutionSnapshot.restDay(weekday: weekday, week: week);
    }

    final ExecutionRepository executions = ref.read(executionRepositoryProvider);
    return ExecutionSnapshot(
      weekday: weekday,
      week: week,
      exercises: exercises,
      outcomes: await executions.outcomesForWeek(week),
    );
  }

  Future<void> cycleOutcome(String exerciseId, int setIndex) async {
    final ExecutionSnapshot? snapshot = state.value;
    if (snapshot == null) return;

    final SetOutcome next =
        snapshot.outcomeFor(exerciseId, setIndex).toggledForward;
    await _commit(snapshot, exerciseId, setIndex, next);
  }

  Future<void> markOutcome(
    String exerciseId,
    int setIndex,
    SetOutcome outcome,
  ) async {
    final ExecutionSnapshot? snapshot = state.value;
    if (snapshot == null) return;
    if (snapshot.outcomeFor(exerciseId, setIndex) == outcome) return;

    await _commit(snapshot, exerciseId, setIndex, outcome);
  }

  Future<void> _commit(
    ExecutionSnapshot snapshot,
    String exerciseId,
    int setIndex,
    SetOutcome outcome,
  ) async {
    state = AsyncData<ExecutionSnapshot>(
      snapshot.withOutcome(exerciseId, setIndex, outcome),
    );

    final ExecutionRepository executions = ref.read(executionRepositoryProvider);
    await executions.record(
      SetExecution(
        exerciseId: exerciseId,
        setIndex: setIndex,
        weekStamp: snapshot.week,
        outcome: outcome,
        recordedAt: ref.read(clockProvider).now(),
      ),
    );
  }

  Future<void> resetExercise(String exerciseId) async {
    final ExecutionSnapshot? snapshot = state.value;
    if (snapshot == null) return;

    await ref
        .read(executionRepositoryProvider)
        .clearExercise(exerciseId, snapshot.week);
    ref.invalidateSelf();
  }
}

final AsyncNotifierProvider<ExecutionController, ExecutionSnapshot>
    executionControllerProvider =
    AsyncNotifierProvider<ExecutionController, ExecutionSnapshot>(
  ExecutionController.new,
);
