import 'package:flutter/foundation.dart';

import 'exercise_video.dart';
import 'muscle_group.dart';

@immutable
final class Movement {
  const Movement({
    required this.id,
    required this.name,
    this.summary,
    this.description,
    this.muscleGroups = const <MuscleGroup>[],
    this.videos = const <ExerciseVideo>[],
  });

  final String id;
  final String name;
  final String? summary;
  final String? description;
  final List<MuscleGroup> muscleGroups;
  final List<ExerciseVideo> videos;

  bool get hasVideos => videos.isNotEmpty;

  int get videoCount => videos.length;

  bool get hasSummary => summary?.trim().isNotEmpty ?? false;

  bool get hasDescription => description?.trim().isNotEmpty ?? false;

  Movement copyWith({
    String? name,
    String? summary,
    String? description,
    List<MuscleGroup>? muscleGroups,
    List<ExerciseVideo>? videos,
  }) =>
      Movement(
        id: id,
        name: name ?? this.name,
        summary: summary ?? this.summary,
        description: description ?? this.description,
        muscleGroups: muscleGroups ?? this.muscleGroups,
        videos: videos ?? this.videos,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Movement && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Movement($id, $name)';
}
