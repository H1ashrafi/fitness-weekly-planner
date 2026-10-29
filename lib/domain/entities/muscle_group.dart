import 'package:flutter/foundation.dart';

import 'anatomy_region.dart';

@immutable
final class MuscleGroup {
  const MuscleGroup({
    required this.id,
    required this.displayName,
    this.region,
  });

  final String id;
  final String displayName;
  final AnatomyRegion? region;

  bool get isAnatomyBacked => region != null;

  bool get isUserDefined => region == null;

  MuscleGroup copyWith({String? displayName, AnatomyRegion? region}) =>
      MuscleGroup(
        id: id,
        displayName: displayName ?? this.displayName,
        region: region ?? this.region,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is MuscleGroup && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'MuscleGroup($id, $displayName)';
}
