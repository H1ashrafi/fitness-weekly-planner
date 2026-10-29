import '../entities/exercise.dart';
import '../entities/muscle_group.dart';
import '../entities/weekday.dart';

abstract interface class RoutineRepository {
  Future<List<Exercise>> exercisesOn(Weekday weekday);

  Future<Map<Weekday, List<Exercise>>> fullWeek();

  Future<Exercise?> exerciseById(String id);

  Future<void> saveEntry(Exercise entry);

  Future<void> deleteEntry(String entryId);

  Future<void> reorderEntries(Weekday weekday, List<String> orderedIds);
}

abstract interface class MuscleGroupRepository {
  Future<List<MuscleGroup>> all();

  Future<void> save(MuscleGroup group);

  Future<void> delete(String groupId);
}
