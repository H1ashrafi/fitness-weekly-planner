import '../entities/exercise_video.dart';
import '../entities/movement.dart';

abstract interface class MovementRepository {
  Future<List<Movement>> all();

  Future<Movement?> byId(String id);

  Future<void> save(Movement movement);

  Future<void> delete(String movementId);

  Future<void> attachVideo(ExerciseVideo video);

  Future<void> detachVideo(String videoId);

  Future<void> updateVideoNote(String videoId, String? note);

  Future<void> reorderVideos(String movementId, List<String> orderedIds);
}
