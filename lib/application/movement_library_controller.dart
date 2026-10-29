import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../domain/entities/exercise_video.dart';
import '../domain/entities/movement.dart';
import '../domain/entities/muscle_group.dart';
import '../domain/repositories/movement_repository.dart';
import 'providers.dart';
import 'routine_controller.dart';

final class MovementLibraryController extends AsyncNotifier<List<Movement>> {
  static const Uuid _ids = Uuid();

  @override
  Future<List<Movement>> build() => ref.watch(movementRepositoryProvider).all();

  MovementRepository get _movements => ref.read(movementRepositoryProvider);

  Future<String?> createMovement({
    required String name,
    String? summary,
    String? description,
    List<MuscleGroup> muscleGroups = const <MuscleGroup>[],
  }) async {
    final String trimmed = name.trim();
    if (trimmed.isEmpty) return null;

    final String id = 'mv:${_ids.v4()}';
    await _movements.save(
      Movement(
        id: id,
        name: trimmed,
        summary: _clean(summary),
        description: _clean(description),
        muscleGroups: muscleGroups,
      ),
    );
    ref.invalidateSelf();
    ref.invalidate(routineControllerProvider);
    return id;
  }

  Future<void> updateDetails(
    Movement movement, {
    required String name,
    String? summary,
    String? description,
    required List<MuscleGroup> muscleGroups,
  }) async {
    final String trimmed = name.trim();
    if (trimmed.isEmpty) return;

    await _movements.save(
      movement.copyWith(
        name: trimmed,
        summary: _clean(summary),
        description: _clean(description),
        muscleGroups: muscleGroups,
      ),
    );
    ref.invalidateSelf();
    ref.invalidate(routineControllerProvider);
  }

  Future<void> deleteMovement(String movementId) async {
    await _movements.delete(movementId);
    ref.invalidateSelf();
    ref.invalidate(routineControllerProvider);
  }

  Future<void> attachVideo(String movementId, String sourcePath, {String? label}) async {
    final Movement? movement = await _movements.byId(movementId);
    if (movement == null) return;

    final String videoId = _ids.v4();
    final String storedUri =
        await ref.read(videoStoreProvider).import(sourcePath, videoId);
    await _movements.attachVideo(
      ExerciseVideo(
        id: videoId,
        movementId: movementId,
        localUri: storedUri,
        orderIndex: movement.videos.length,
        label: label,
      ),
    );
    ref.invalidateSelf();
    ref.invalidate(routineControllerProvider);
  }

  Future<void> detachVideo(ExerciseVideo video) async {
    await _movements.detachVideo(video.id);
    await ref.read(videoStoreProvider).discard(video.localUri);
    ref.invalidateSelf();
    ref.invalidate(routineControllerProvider);
  }

  Future<void> updateVideoNote(String videoId, String note) async {
    final String trimmed = note.trim();
    await _movements.updateVideoNote(videoId, trimmed.isEmpty ? null : trimmed);
    ref.invalidateSelf();
    ref.invalidate(routineControllerProvider);
  }

  static String? _clean(String? value) {
    final String? trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}

final AsyncNotifierProvider<MovementLibraryController, List<Movement>>
    movementLibraryProvider =
    AsyncNotifierProvider<MovementLibraryController, List<Movement>>(
  MovementLibraryController.new,
);

final movementByIdProvider = Provider.family<Movement?, String>(
  (Ref ref, String movementId) {
    final List<Movement> library =
        ref.watch(movementLibraryProvider).value ?? const <Movement>[];
    for (final Movement movement in library) {
      if (movement.id == movementId) return movement;
    }
    return null;
  },
);
