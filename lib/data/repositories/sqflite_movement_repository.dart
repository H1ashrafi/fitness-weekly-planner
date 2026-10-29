import 'package:sqflite/sqflite.dart';

import '../../domain/entities/anatomy_region.dart';
import '../../domain/entities/exercise_video.dart';
import '../../domain/entities/movement.dart';
import '../../domain/entities/muscle_group.dart';
import '../../domain/repositories/movement_repository.dart';
import '../database/schema.dart';

Future<Map<String, Movement>> loadMovementsByIds(
  Database db,
  List<String> ids,
) async {
  if (ids.isEmpty) return const <String, Movement>{};
  final String placeholders = List<String>.filled(ids.length, '?').join(', ');

  final List<Map<String, Object?>> movementRows = await db.query(
    Tables.movements,
    where: 'id IN ($placeholders)',
    whereArgs: ids,
  );

  final List<Map<String, Object?>> groupRows = await db.rawQuery(
    '''
    SELECT link.movement_id, mg.id, mg.display_name, mg.region
    FROM ${Tables.movementMuscleGroups} link
    JOIN ${Tables.muscleGroups} mg ON mg.id = link.muscle_group_id
    WHERE link.movement_id IN ($placeholders)
    ''',
    ids,
  );

  final List<Map<String, Object?>> videoRows = await db.query(
    Tables.movementVideos,
    where: 'movement_id IN ($placeholders)',
    whereArgs: ids,
    orderBy: 'order_index ASC',
  );

  final Map<String, List<MuscleGroup>> groupsByMovement =
      <String, List<MuscleGroup>>{};
  for (final Map<String, Object?> row in groupRows) {
    groupsByMovement
        .putIfAbsent(row['movement_id']! as String, () => <MuscleGroup>[])
        .add(
          MuscleGroup(
            id: row['id']! as String,
            displayName: row['display_name']! as String,
            region: AnatomyRegion.tryParse(row['region'] as String?),
          ),
        );
  }

  final Map<String, List<ExerciseVideo>> videosByMovement =
      <String, List<ExerciseVideo>>{};
  for (final Map<String, Object?> row in videoRows) {
    videosByMovement
        .putIfAbsent(row['movement_id']! as String, () => <ExerciseVideo>[])
        .add(
          ExerciseVideo(
            id: row['id']! as String,
            movementId: row['movement_id']! as String,
            localUri: row['local_uri']! as String,
            orderIndex: row['order_index']! as int,
            label: row['label'] as String?,
            note: row['note'] as String?,
          ),
        );
  }

  return <String, Movement>{
    for (final Map<String, Object?> row in movementRows)
      row['id']! as String: Movement(
        id: row['id']! as String,
        name: row['name']! as String,
        summary: row['summary'] as String?,
        description: row['description'] as String?,
        muscleGroups:
            groupsByMovement[row['id']! as String] ?? const <MuscleGroup>[],
        videos: videosByMovement[row['id']! as String] ?? const <ExerciseVideo>[],
      ),
  };
}

final class SqfliteMovementRepository implements MovementRepository {
  const SqfliteMovementRepository(this._db);

  final Database _db;

  @override
  Future<List<Movement>> all() async {
    final List<Map<String, Object?>> rows =
        await _db.query(Tables.movements, orderBy: 'name COLLATE NOCASE ASC');
    final List<String> ids =
        rows.map((Map<String, Object?> row) => row['id']! as String).toList();
    final Map<String, Movement> byId = await loadMovementsByIds(_db, ids);
    return ids
        .map((String id) => byId[id])
        .whereType<Movement>()
        .toList(growable: false);
  }

  @override
  Future<Movement?> byId(String id) async {
    final Map<String, Movement> byId = await loadMovementsByIds(_db, <String>[id]);
    return byId[id];
  }

  @override
  Future<void> save(Movement movement) => _db.transaction(
        (Transaction txn) async {
          await txn.insert(
            Tables.movements,
            <String, Object?>{
              'id': movement.id,
              'name': movement.name,
              'summary': movement.summary,
              'description': movement.description,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );

          await txn.delete(
            Tables.movementMuscleGroups,
            where: 'movement_id = ?',
            whereArgs: <Object?>[movement.id],
          );
          for (final MuscleGroup group in movement.muscleGroups) {
            await txn.insert(
              Tables.movementMuscleGroups,
              <String, Object?>{
                'movement_id': movement.id,
                'muscle_group_id': group.id,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        },
      );

  @override
  Future<void> delete(String movementId) => _db.delete(
        Tables.movements,
        where: 'id = ?',
        whereArgs: <Object?>[movementId],
      );

  @override
  Future<void> attachVideo(ExerciseVideo video) => _db.insert(
        Tables.movementVideos,
        <String, Object?>{
          'id': video.id,
          'movement_id': video.movementId,
          'local_uri': video.localUri,
          'order_index': video.orderIndex,
          'label': video.label,
          'note': video.note,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  @override
  Future<void> detachVideo(String videoId) => _db.delete(
        Tables.movementVideos,
        where: 'id = ?',
        whereArgs: <Object?>[videoId],
      );

  @override
  Future<void> updateVideoNote(String videoId, String? note) => _db.update(
        Tables.movementVideos,
        <String, Object?>{'note': note},
        where: 'id = ?',
        whereArgs: <Object?>[videoId],
      );

  @override
  Future<void> reorderVideos(String movementId, List<String> orderedIds) =>
      _db.transaction((Transaction txn) async {
        for (final (int index, String id) in orderedIds.indexed) {
          await txn.update(
            Tables.movementVideos,
            <String, Object?>{'order_index': index},
            where: 'id = ? AND movement_id = ?',
            whereArgs: <Object?>[id, movementId],
          );
        }
      });
}
