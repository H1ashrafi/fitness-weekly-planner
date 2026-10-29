import 'package:flutter_test/flutter_test.dart';
import 'package:hanimob2/core/time/week_stamp.dart';
import 'package:hanimob2/data/repositories/sqflite_execution_repository.dart';
import 'package:hanimob2/data/repositories/sqflite_movement_repository.dart';
import 'package:hanimob2/data/repositories/sqflite_routine_repository.dart';
import 'package:hanimob2/domain/entities/exercise.dart';
import 'package:hanimob2/domain/entities/movement.dart';
import 'package:hanimob2/domain/entities/set_execution.dart';
import 'package:hanimob2/domain/entities/set_outcome.dart';
import 'package:hanimob2/domain/entities/weekday.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/in_memory_database.dart';

void main() {
  late Database db;
  late SqfliteExecutionRepository executions;
  late SqfliteRoutineRepository routines;
  late SqfliteMovementRepository movements;

  final WeekStamp thisWeek = WeekStamp.fromDate(DateTime(2026, 7, 15));
  final WeekStamp nextWeek = thisWeek.next;

  const Movement benchMovement =
      Movement(id: 'mv-bench', name: 'Barbell Bench Press');

  const Exercise benchPress = Exercise(
    id: 'ex-bench',
    movement: benchMovement,
    weekday: Weekday.monday,
    orderIndex: 0,
    targetSets: 4,
    targetReps: 15,
  );

  setUp(() async {
    db = await InMemoryDatabase.open();
    executions = SqfliteExecutionRepository(db);
    routines = SqfliteRoutineRepository(db);
    movements = SqfliteMovementRepository(db);
    await movements.save(benchMovement);
    await routines.saveEntry(benchPress);
  });

  tearDown(() async => db.close());

  Future<void> recordSet(int setIndex, SetOutcome outcome, WeekStamp week) =>
      executions.record(
        SetExecution(
          exerciseId: benchPress.id,
          setIndex: setIndex,
          weekStamp: week,
          outcome: outcome,
          recordedAt: week.mondayMidnight.add(const Duration(hours: 9)),
        ),
      );

  test('execution state is empty for a week that has no records', () async {
    expect(await executions.outcomesForWeek(thisWeek), isEmpty);
  });

  test('recorded outcomes are readable within the same week', () async {
    await recordSet(0, SetOutcome.completed, thisWeek);
    await recordSet(1, SetOutcome.failed, thisWeek);

    final Map<SetExecutionKey, SetOutcome> outcomes =
        await executions.outcomesForWeek(thisWeek);

    expect(outcomes, hasLength(2));
    expect(
      outcomes[(exerciseId: 'ex-bench', setIndex: 0, weekToken: thisWeek.token)],
      SetOutcome.completed,
    );
    expect(
      outcomes[(exerciseId: 'ex-bench', setIndex: 1, weekToken: thisWeek.token)],
      SetOutcome.failed,
    );
  });

  test('crossing into a new week presents a fully reset slate', () async {
    for (final int setIndex in benchPress.setIndices) {
      await recordSet(setIndex, SetOutcome.completed, thisWeek);
    }
    expect(await executions.outcomesForWeek(thisWeek), hasLength(4));

    expect(await executions.outcomesForWeek(nextWeek), isEmpty);
  });

  test('the reset preserves prior weeks as history for analytics', () async {
    await recordSet(0, SetOutcome.completed, thisWeek);
    await recordSet(0, SetOutcome.failed, nextWeek);

    expect(await executions.outcomesForWeek(thisWeek), hasLength(1));
    expect(await executions.outcomesForWeek(nextWeek), hasLength(1));
    expect(
      await executions.weeksWithActivity(),
      <WeekStamp>[thisWeek, nextWeek],
    );
  });

  test('the same set in two weeks stays independent', () async {
    await recordSet(2, SetOutcome.completed, thisWeek);
    await recordSet(2, SetOutcome.failed, nextWeek);

    final Map<SetExecutionKey, SetOutcome> current =
        await executions.outcomesForWeek(thisWeek);
    final Map<SetExecutionKey, SetOutcome> upcoming =
        await executions.outcomesForWeek(nextWeek);

    expect(
      current[(exerciseId: 'ex-bench', setIndex: 2, weekToken: thisWeek.token)],
      SetOutcome.completed,
    );
    expect(
      upcoming[(exerciseId: 'ex-bench', setIndex: 2, weekToken: nextWeek.token)],
      SetOutcome.failed,
    );
  });

  test('re-recording a set overwrites rather than duplicates', () async {
    await recordSet(0, SetOutcome.completed, thisWeek);
    await recordSet(0, SetOutcome.failed, thisWeek);

    final Map<SetExecutionKey, SetOutcome> outcomes =
        await executions.outcomesForWeek(thisWeek);
    expect(outcomes, hasLength(1));
    expect(outcomes.values.single, SetOutcome.failed);
  });

  test('returning a set to pending erases its record', () async {
    await recordSet(0, SetOutcome.completed, thisWeek);
    await recordSet(0, SetOutcome.pending, thisWeek);

    expect(await executions.outcomesForWeek(thisWeek), isEmpty);
  });

  test('deleting an entry cascades its execution history away', () async {
    await recordSet(0, SetOutcome.completed, thisWeek);
    await routines.deleteEntry(benchPress.id);

    expect(await executions.outcomesForWeek(thisWeek), isEmpty);
  });

  test('recordedBetween spans weeks for longitudinal charting', () async {
    await recordSet(0, SetOutcome.completed, thisWeek);
    await recordSet(1, SetOutcome.completed, nextWeek);

    final List<SetExecution> spanning = await executions.recordedBetween(
      thisWeek.mondayMidnight,
      nextWeek.exclusiveEnd,
    );
    expect(spanning, hasLength(2));

    final List<SetExecution> firstWeekOnly = await executions.recordedBetween(
      thisWeek.mondayMidnight,
      thisWeek.exclusiveEnd,
    );
    expect(firstWeekOnly, hasLength(1));
    expect(firstWeekOnly.single.weekStamp, thisWeek);
  });
}
