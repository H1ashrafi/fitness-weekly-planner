import 'package:flutter/foundation.dart';

import '../core/time/week_stamp.dart';
import '../domain/entities/completion_tally.dart';
import '../domain/entities/exercise.dart';
import '../domain/entities/muscle_group.dart';
import '../domain/entities/set_execution.dart';
import '../domain/entities/set_outcome.dart';
import '../domain/entities/weekday.dart';

@immutable
final class ExecutionSnapshot {
  const ExecutionSnapshot({
    required this.weekday,
    required this.week,
    required this.exercises,
    required this.outcomes,
  });

  const ExecutionSnapshot.restDay({required this.weekday, required this.week})
      : exercises = const <Exercise>[],
        outcomes = const <SetExecutionKey, SetOutcome>{};

  final Weekday weekday;
  final WeekStamp week;
  final List<Exercise> exercises;
  final Map<SetExecutionKey, SetOutcome> outcomes;

  bool get isRestDay => exercises.isEmpty;

  SetOutcome outcomeFor(String exerciseId, int setIndex) =>
      outcomes[(
        exerciseId: exerciseId,
        setIndex: setIndex,
        weekToken: week.token,
      )] ??
      SetOutcome.pending;

  CompletionTally tallyFor(Exercise exercise) => CompletionTally.fromOutcomes(
        exercise.setIndices
            .map((int setIndex) => outcomeFor(exercise.id, setIndex)),
      );

  CompletionTally get dayTally =>
      CompletionTally.sum(exercises.map(tallyFor));

  bool get isPerfectDay => dayTally.isPerfect;

  Iterable<MuscleGroup> get engagedMuscleGroups => exercises
      .where((Exercise exercise) => tallyFor(exercise).completed > 0)
      .expand((Exercise exercise) => exercise.muscleGroups)
      .toSet();

  ExecutionSnapshot withOutcome(
    String exerciseId,
    int setIndex,
    SetOutcome outcome,
  ) {
    final SetExecutionKey key = (
      exerciseId: exerciseId,
      setIndex: setIndex,
      weekToken: week.token,
    );
    final Map<SetExecutionKey, SetOutcome> revised =
        Map<SetExecutionKey, SetOutcome>.of(outcomes);
    if (outcome == SetOutcome.pending) {
      revised.remove(key);
    } else {
      revised[key] = outcome;
    }
    return ExecutionSnapshot(
      weekday: weekday,
      week: week,
      exercises: exercises,
      outcomes: revised,
    );
  }
}
