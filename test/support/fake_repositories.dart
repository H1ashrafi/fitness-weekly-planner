import 'package:hanimob2/core/time/week_stamp.dart';
import 'package:hanimob2/domain/entities/anatomy_region.dart';
import 'package:hanimob2/domain/entities/exercise.dart';
import 'package:hanimob2/domain/entities/exercise_video.dart';
import 'package:hanimob2/domain/entities/movement.dart';
import 'package:hanimob2/domain/entities/muscle_group.dart';
import 'package:hanimob2/domain/entities/set_execution.dart';
import 'package:hanimob2/domain/entities/set_outcome.dart';
import 'package:hanimob2/domain/entities/weekday.dart';
import 'package:hanimob2/domain/repositories/execution_repository.dart';
import 'package:hanimob2/domain/repositories/movement_repository.dart';
import 'package:hanimob2/domain/repositories/routine_repository.dart';

typedef _EntryRecord = ({
  String id,
  String movementId,
  Weekday weekday,
  int orderIndex,
  int targetSets,
  int targetReps,
  String? loadNote,
});

final class InMemoryMovementRepository implements MovementRepository {
  final Map<String, Movement> _movements = <String, Movement>{};
  final List<ExerciseVideo> _videos = <ExerciseVideo>[];

  Movement withVideos(Movement movement) => movement.copyWith(
        videos: (_videos
                .where((ExerciseVideo video) => video.movementId == movement.id)
                .toList()
              ..sort((ExerciseVideo a, ExerciseVideo b) =>
                  a.orderIndex.compareTo(b.orderIndex)))
            .toList(growable: false),
      );

  @override
  Future<List<Movement>> all() async => (_movements.values
          .map(withVideos)
          .toList()
        ..sort((Movement a, Movement b) =>
            a.name.toLowerCase().compareTo(b.name.toLowerCase())))
      .toList(growable: false);

  @override
  Future<Movement?> byId(String id) async {
    final Movement? found = _movements[id];
    return found == null ? null : withVideos(found);
  }

  @override
  Future<void> save(Movement movement) async => _movements[movement.id] = movement;

  @override
  Future<void> delete(String movementId) async {
    _movements.remove(movementId);
    _videos.removeWhere((ExerciseVideo video) => video.movementId == movementId);
  }

  @override
  Future<void> attachVideo(ExerciseVideo video) async => _videos.add(video);

  @override
  Future<void> detachVideo(String videoId) async =>
      _videos.removeWhere((ExerciseVideo video) => video.id == videoId);

  @override
  Future<void> updateVideoNote(String videoId, String? note) async {
    final int position =
        _videos.indexWhere((ExerciseVideo video) => video.id == videoId);
    if (position < 0) return;
    _videos[position] = _videos[position].copyWith(note: note);
  }

  @override
  Future<void> reorderVideos(String movementId, List<String> orderedIds) async {
    for (final (int index, String id) in orderedIds.indexed) {
      final int position = _videos.indexWhere((ExerciseVideo v) => v.id == id);
      if (position < 0) continue;
      _videos[position] = _videos[position].copyWith(orderIndex: index);
    }
  }
}

final class InMemoryRoutineRepository implements RoutineRepository {
  InMemoryRoutineRepository(this._movements);

  final InMemoryMovementRepository _movements;
  final Map<String, _EntryRecord> _entries = <String, _EntryRecord>{};

  Future<Exercise?> _hydrate(_EntryRecord record) async {
    final Movement? movement = await _movements.byId(record.movementId);
    if (movement == null) return null;
    return Exercise(
      id: record.id,
      movement: movement,
      weekday: record.weekday,
      orderIndex: record.orderIndex,
      targetSets: record.targetSets,
      targetReps: record.targetReps,
      loadNote: record.loadNote,
    );
  }

  Future<List<Exercise>> _sortedFor(Weekday weekday) async {
    final List<Exercise> hydrated = <Exercise>[];
    for (final _EntryRecord record in _entries.values) {
      if (record.weekday != weekday) continue;
      final Exercise? exercise = await _hydrate(record);
      if (exercise != null) hydrated.add(exercise);
    }
    hydrated.sort((Exercise a, Exercise b) => a.orderIndex.compareTo(b.orderIndex));
    return hydrated.toList(growable: false);
  }

  @override
  Future<List<Exercise>> exercisesOn(Weekday weekday) => _sortedFor(weekday);

  @override
  Future<Map<Weekday, List<Exercise>>> fullWeek() async =>
      <Weekday, List<Exercise>>{
        for (final Weekday day in Weekday.values) day: await _sortedFor(day),
      };

  @override
  Future<Exercise?> exerciseById(String id) async {
    final _EntryRecord? record = _entries[id];
    return record == null ? null : _hydrate(record);
  }

  @override
  Future<void> saveEntry(Exercise entry) async {
    _entries[entry.id] = (
      id: entry.id,
      movementId: entry.movementId,
      weekday: entry.weekday,
      orderIndex: entry.orderIndex,
      targetSets: entry.targetSets,
      targetReps: entry.targetReps,
      loadNote: entry.loadNote,
    );
  }

  @override
  Future<void> deleteEntry(String entryId) async => _entries.remove(entryId);

  @override
  Future<void> reorderEntries(Weekday weekday, List<String> orderedIds) async {
    for (final (int index, String id) in orderedIds.indexed) {
      final _EntryRecord? record = _entries[id];
      if (record == null || record.weekday != weekday) continue;
      _entries[id] = (
        id: record.id,
        movementId: record.movementId,
        weekday: record.weekday,
        orderIndex: index,
        targetSets: record.targetSets,
        targetReps: record.targetReps,
        loadNote: record.loadNote,
      );
    }
  }
}

final class InMemoryMuscleGroupRepository implements MuscleGroupRepository {
  InMemoryMuscleGroupRepository() {
    for (final AnatomyRegion region in AnatomyRegion.values) {
      final String id = 'region:${region.name}';
      _groups[id] = MuscleGroup(
        id: id,
        displayName: region.label,
        region: region,
      );
    }
  }

  final Map<String, MuscleGroup> _groups = <String, MuscleGroup>{};

  @override
  Future<List<MuscleGroup>> all() async => (_groups.values.toList()
        ..sort((MuscleGroup a, MuscleGroup b) =>
            a.displayName.compareTo(b.displayName)))
      .toList(growable: false);

  @override
  Future<void> save(MuscleGroup group) async => _groups[group.id] = group;

  @override
  Future<void> delete(String groupId) async => _groups.remove(groupId);
}

final class InMemoryExecutionRepository implements ExecutionRepository {
  final Map<SetExecutionKey, SetExecution> _records =
      <SetExecutionKey, SetExecution>{};

  @override
  Future<Map<SetExecutionKey, SetOutcome>> outcomesForWeek(WeekStamp week) async =>
      <SetExecutionKey, SetOutcome>{
        for (final MapEntry<SetExecutionKey, SetExecution> entry
            in _records.entries)
          if (entry.value.weekStamp == week) entry.key: entry.value.outcome,
      };

  @override
  Future<void> record(SetExecution execution) async {
    if (execution.outcome == SetOutcome.pending) {
      _records.remove(execution.key);
      return;
    }
    _records[execution.key] = execution;
  }

  @override
  Future<void> clearExercise(String exerciseId, WeekStamp week) async =>
      _records.removeWhere((SetExecutionKey key, SetExecution value) =>
          key.exerciseId == exerciseId && value.weekStamp == week);

  @override
  Future<List<SetExecution>> recordedBetween(DateTime start, DateTime end) async =>
      (_records.values
              .where((SetExecution record) =>
                  !record.recordedAt.isBefore(start) &&
                  record.recordedAt.isBefore(end))
              .toList()
            ..sort((SetExecution a, SetExecution b) =>
                a.recordedAt.compareTo(b.recordedAt)))
          .toList(growable: false);

  @override
  Future<List<WeekStamp>> weeksWithActivity() async => (_records.values
          .map((SetExecution record) => record.weekStamp)
          .toSet()
          .toList()
        ..sort())
      .toList(growable: false);
}
