import 'package:flutter/foundation.dart';

import 'exercise_video.dart';
import 'movement.dart';
import 'muscle_group.dart';
import 'weekday.dart';

@immutable
final class Exercise {
  const Exercise({
    required this.id,
    required this.movement,
    required this.weekday,
    required this.orderIndex,
    required this.targetSets,
    required this.targetReps,
    this.loadNote,
  })  : assert(targetSets > 0, 'An exercise needs at least one set'),
        assert(targetReps > 0, 'An exercise needs at least one rep');

  final String id;
  final Movement movement;
  final Weekday weekday;
  final int orderIndex;
  final int targetSets;
  final int targetReps;
  final String? loadNote;

  String get movementId => movement.id;

  String get name => movement.name;

  List<MuscleGroup> get muscleGroups => movement.muscleGroups;

  List<ExerciseVideo> get videos => movement.videos;

  bool get hasVideos => movement.hasVideos;

  int get videoCount => movement.videoCount;

  String get prescription => '$targetSets × $targetReps';

  String get prescriptionSummary => switch (loadNote) {
        final String note when note.trim().isNotEmpty => '$prescription · $note',
        _ => prescription,
      };

  Iterable<int> get setIndices => Iterable<int>.generate(targetSets);

  Exercise copyWith({
    Movement? movement,
    Weekday? weekday,
    int? orderIndex,
    int? targetSets,
    int? targetReps,
    String? loadNote,
  }) =>
      Exercise(
        id: id,
        movement: movement ?? this.movement,
        weekday: weekday ?? this.weekday,
        orderIndex: orderIndex ?? this.orderIndex,
        targetSets: targetSets ?? this.targetSets,
        targetReps: targetReps ?? this.targetReps,
        loadNote: loadNote ?? this.loadNote,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Exercise && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Exercise($id, ${movement.name}, ${weekday.fullName}, $prescription)';
}
