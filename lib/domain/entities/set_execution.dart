import 'package:flutter/foundation.dart';

import '../../core/time/week_stamp.dart';
import 'set_outcome.dart';

@immutable
final class SetExecution {
  const SetExecution({
    required this.exerciseId,
    required this.setIndex,
    required this.weekStamp,
    required this.outcome,
    required this.recordedAt,
  }) : assert(setIndex >= 0, 'setIndex is zero-based');

  final String exerciseId;
  final int setIndex;
  final WeekStamp weekStamp;
  final SetOutcome outcome;
  final DateTime recordedAt;

  SetExecutionKey get key =>
      (exerciseId: exerciseId, setIndex: setIndex, weekToken: weekStamp.token);

  SetExecution copyWith({SetOutcome? outcome, DateTime? recordedAt}) =>
      SetExecution(
        exerciseId: exerciseId,
        setIndex: setIndex,
        weekStamp: weekStamp,
        outcome: outcome ?? this.outcome,
        recordedAt: recordedAt ?? this.recordedAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SetExecution &&
          other.exerciseId == exerciseId &&
          other.setIndex == setIndex &&
          other.weekStamp == weekStamp;

  @override
  int get hashCode => Object.hash(exerciseId, setIndex, weekStamp);
}

typedef SetExecutionKey = ({String exerciseId, int setIndex, String weekToken});
