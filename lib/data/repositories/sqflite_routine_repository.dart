import 'package:sqflite/sqflite.dart';

import '../../domain/entities/anatomy_region.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/movement.dart';
import '../../domain/entities/muscle_group.dart';
import '../../domain/entities/weekday.dart';
import '../../domain/repositories/routine_repository.dart';
import '../database/schema.dart';
import 'sqflite_movement_repository.dart';

final class SqfliteRoutineRepository implements RoutineRepository {
  const SqfliteRoutineRepository(this._db);

  final Database _db;

  @override
  Future<List<Exercise>> exercisesOn(Weekday weekday) async {
    final List<Map<String, Object?>> rows = await _db.query(
      Tables.planEntries,
      where: 'weekday = ?',
      whereArgs: <Object?>[weekday.isoIndex],
      orderBy: 'order_index ASC',
    );
    return _hydrate(rows);
  }

  @override
  Future<Map<Weekday, List<Exercise>>> fullWeek() async {
    final List<Map<String, Object?>> rows = await _db.query(
      Tables.planEntries,
      orderBy: 'weekday ASC, order_index ASC',
    );
    final List<Exercise> hydrated = await _hydrate(rows);
    return <Weekday, List<Exercise>>{
      for (final Weekday day in Weekday.values)
        day: hydrated
            .where((Exercise exercise) => exercise.weekday == day)
            .toList(growable: false),
    };
  }

  @override
  Future<Exercise?> exerciseById(String id) async {
    final List<Map<String, Object?>> rows = await _db.query(
      Tables.planEntries,
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final List<Exercise> hydrated = await _hydrate(rows);
    return hydrated.singleOrNull;
  }

  @override
  Future<void> saveEntry(Exercise entry) => _db.insert(
        Tables.planEntries,
        <String, Object?>{
          'id': entry.id,
          'movement_id': entry.movementId,
          'weekday': entry.weekday.isoIndex,
          'order_index': entry.orderIndex,
          'target_sets': entry.targetSets,
          'target_reps': entry.targetReps,
          'load_note': entry.loadNote,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  @override
  Future<void> deleteEntry(String entryId) => _db.delete(
        Tables.planEntries,
        where: 'id = ?',
        whereArgs: <Object?>[entryId],
      );

  @override
  Future<void> reorderEntries(Weekday weekday, List<String> orderedIds) =>
      _db.transaction((Transaction txn) async {
        for (final (int index, String id) in orderedIds.indexed) {
          await txn.update(
            Tables.planEntries,
            <String, Object?>{'order_index': index},
            where: 'id = ? AND weekday = ?',
            whereArgs: <Object?>[id, weekday.isoIndex],
          );
        }
      });

  Future<List<Exercise>> _hydrate(List<Map<String, Object?>> entryRows) async {
    if (entryRows.isEmpty) return const <Exercise>[];

    final List<String> movementIds = entryRows
        .map((Map<String, Object?> row) => row['movement_id']! as String)
        .toSet()
        .toList(growable: false);
    final Map<String, Movement> movements =
        await loadMovementsByIds(_db, movementIds);

    return entryRows
        .map((Map<String, Object?> row) {
          final Movement? movement = movements[row['movement_id']! as String];
          if (movement == null) return null;
          return Exercise(
            id: row['id']! as String,
            movement: movement,
            weekday: Weekday.fromIsoIndex(row['weekday']! as int),
            orderIndex: row['order_index']! as int,
            targetSets: row['target_sets']! as int,
            targetReps: row['target_reps']! as int,
            loadNote: row['load_note'] as String?,
          );
        })
        .whereType<Exercise>()
        .toList(growable: false);
  }
}

final class SqfliteMuscleGroupRepository implements MuscleGroupRepository {
  const SqfliteMuscleGroupRepository(this._db);

  final Database _db;

  @override
  Future<List<MuscleGroup>> all() async {
    final List<Map<String, Object?>> rows =
        await _db.query(Tables.muscleGroups, orderBy: 'display_name ASC');
    return rows
        .map((Map<String, Object?> row) => MuscleGroup(
              id: row['id']! as String,
              displayName: row['display_name']! as String,
              region: AnatomyRegion.tryParse(row['region'] as String?),
            ))
        .toList(growable: false);
  }

  @override
  Future<void> save(MuscleGroup group) => _db.insert(
        Tables.muscleGroups,
        <String, Object?>{
          'id': group.id,
          'display_name': group.displayName,
          'region': group.region?.name,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  @override
  Future<void> delete(String groupId) => _db.delete(
        Tables.muscleGroups,
        where: 'id = ?',
        whereArgs: <Object?>[groupId],
      );
}
