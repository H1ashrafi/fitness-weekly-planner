import 'package:sqflite/sqflite.dart';

import '../../core/time/week_stamp.dart';
import '../../domain/entities/set_execution.dart';
import '../../domain/entities/set_outcome.dart';
import '../../domain/repositories/execution_repository.dart';
import '../database/schema.dart';

final class SqfliteExecutionRepository implements ExecutionRepository {
  const SqfliteExecutionRepository(this._db);

  final Database _db;

  @override
  Future<Map<SetExecutionKey, SetOutcome>> outcomesForWeek(WeekStamp week) async {
    final List<Map<String, Object?>> rows = await _db.query(
      Tables.setExecutions,
      where: 'week_token = ?',
      whereArgs: <Object?>[week.token],
    );
    return <SetExecutionKey, SetOutcome>{
      for (final Map<String, Object?> row in rows)
        (
          exerciseId: row['exercise_id']! as String,
          setIndex: row['set_index']! as int,
          weekToken: row['week_token']! as String,
        ): SetOutcome.fromStorageCode(row['outcome']! as int),
    };
  }

  @override
  Future<void> record(SetExecution execution) async {
    if (execution.outcome == SetOutcome.pending) {
      await _db.delete(
        Tables.setExecutions,
        where: 'exercise_id = ? AND set_index = ? AND week_token = ?',
        whereArgs: <Object?>[
          execution.exerciseId,
          execution.setIndex,
          execution.weekStamp.token,
        ],
      );
      return;
    }

    await _db.insert(
      Tables.setExecutions,
      <String, Object?>{
        'exercise_id': execution.exerciseId,
        'set_index': execution.setIndex,
        'week_token': execution.weekStamp.token,
        'outcome': execution.outcome.storageCode,
        'recorded_at': execution.recordedAt.millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> clearExercise(String exerciseId, WeekStamp week) async =>
      _db.delete(
        Tables.setExecutions,
        where: 'exercise_id = ? AND week_token = ?',
        whereArgs: <Object?>[exerciseId, week.token],
      );

  @override
  Future<List<SetExecution>> recordedBetween(DateTime start, DateTime end) async {
    final List<Map<String, Object?>> rows = await _db.query(
      Tables.setExecutions,
      where: 'recorded_at >= ? AND recorded_at < ?',
      whereArgs: <Object?>[
        start.millisecondsSinceEpoch,
        end.millisecondsSinceEpoch,
      ],
      orderBy: 'recorded_at ASC',
    );
    return rows.map(_toEntity).toList(growable: false);
  }

  @override
  Future<List<WeekStamp>> weeksWithActivity() async {
    final List<Map<String, Object?>> rows = await _db.rawQuery(
      'SELECT DISTINCT week_token FROM ${Tables.setExecutions} ORDER BY week_token ASC',
    );
    return rows
        .map((Map<String, Object?> row) =>
            WeekStamp.fromToken(row['week_token']! as String))
        .toList(growable: false);
  }

  SetExecution _toEntity(Map<String, Object?> row) => SetExecution(
        exerciseId: row['exercise_id']! as String,
        setIndex: row['set_index']! as int,
        weekStamp: WeekStamp.fromToken(row['week_token']! as String),
        outcome: SetOutcome.fromStorageCode(row['outcome']! as int),
        recordedAt:
            DateTime.fromMillisecondsSinceEpoch(row['recorded_at']! as int),
      );
}
