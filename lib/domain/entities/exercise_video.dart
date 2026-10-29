import 'package:flutter/foundation.dart';

@immutable
final class ExerciseVideo {
  const ExerciseVideo({
    required this.id,
    required this.movementId,
    required this.localUri,
    required this.orderIndex,
    this.label,
    this.note,
  });

  final String id;
  final String movementId;
  final String localUri;
  final int orderIndex;
  final String? label;
  final String? note;

  String get resolvedLabel => label ?? 'Angle ${orderIndex + 1}';

  bool get hasNote => note?.trim().isNotEmpty ?? false;

  ExerciseVideo copyWith({
    String? localUri,
    int? orderIndex,
    String? label,
    String? note,
  }) =>
      ExerciseVideo(
        id: id,
        movementId: movementId,
        localUri: localUri ?? this.localUri,
        orderIndex: orderIndex ?? this.orderIndex,
        label: label ?? this.label,
        note: note ?? this.note,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ExerciseVideo && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
