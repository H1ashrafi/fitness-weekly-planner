import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hanimob2/data/database/app_database.dart';
import 'package:hanimob2/data/repositories/sqflite_movement_repository.dart';
import 'package:hanimob2/data/repositories/sqflite_routine_repository.dart';
import 'package:hanimob2/domain/entities/exercise.dart';
import 'package:hanimob2/domain/entities/movement.dart';
import 'package:hanimob2/domain/entities/weekday.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const List<String> _v2Create = <String>[
  '''
  CREATE TABLE muscle_groups (
    id TEXT PRIMARY KEY NOT NULL,
    display_name TEXT NOT NULL,
    region TEXT
  )
  ''',
  '''
  CREATE TABLE exercises (
    id TEXT PRIMARY KEY NOT NULL,
    name TEXT NOT NULL,
    weekday INTEGER NOT NULL CHECK (weekday BETWEEN 1 AND 7),
    order_index INTEGER NOT NULL,
    target_sets INTEGER NOT NULL CHECK (target_sets > 0),
    target_reps INTEGER NOT NULL CHECK (target_reps > 0),
    load_note TEXT
  )
  ''',
  '''
  CREATE TABLE exercise_muscle_groups (
    exercise_id TEXT NOT NULL,
    muscle_group_id TEXT NOT NULL,
    PRIMARY KEY (exercise_id, muscle_group_id),
    FOREIGN KEY (exercise_id) REFERENCES exercises (id) ON DELETE CASCADE,
    FOREIGN KEY (muscle_group_id) REFERENCES muscle_groups (id) ON DELETE CASCADE
  )
  ''',
  '''
  CREATE TABLE exercise_videos (
    id TEXT PRIMARY KEY NOT NULL,
    exercise_id TEXT NOT NULL,
    local_uri TEXT NOT NULL,
    order_index INTEGER NOT NULL,
    label TEXT,
    note TEXT,
    FOREIGN KEY (exercise_id) REFERENCES exercises (id) ON DELETE CASCADE
  )
  ''',
  '''
  CREATE TABLE set_executions (
    exercise_id TEXT NOT NULL,
    set_index INTEGER NOT NULL CHECK (set_index >= 0),
    week_token TEXT NOT NULL,
    outcome INTEGER NOT NULL CHECK (outcome BETWEEN 0 AND 2),
    recorded_at INTEGER NOT NULL,
    PRIMARY KEY (exercise_id, set_index, week_token),
    FOREIGN KEY (exercise_id) REFERENCES exercises (id) ON DELETE CASCADE
  )
  ''',
  '''
  CREATE TABLE journal_entries (
    id TEXT PRIMARY KEY NOT NULL,
    scope TEXT NOT NULL CHECK (scope IN ('day', 'week', 'month', 'year')),
    scope_token TEXT NOT NULL,
    body TEXT NOT NULL,
    updated_at INTEGER NOT NULL,
    UNIQUE (scope, scope_token)
  )
  ''',
];

void main() {
  late String path;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    final Directory dir = await Directory.systemTemp.createTemp('hani_mig');
    path = '${dir.path}/hani_fitness.db';
  });

  tearDown(() async {
    final File file = File(path);
    if (file.existsSync()) file.deleteSync();
  });

  Future<Database> openV2() => databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 2,
          onConfigure: SchemaLifecycle.configure,
          onCreate: (Database db, int version) async {
            final Batch batch = db.batch();
            for (final String statement in _v2Create) {
              batch.execute(statement);
            }
            batch.insert('muscle_groups', <String, Object?>{
              'id': 'region:pectoralis',
              'display_name': 'Chest',
              'region': 'pectoralis',
            });
            await batch.commit(noResult: true);
          },
        ),
      );

  Future<Database> openV3() => databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 3,
          onConfigure: SchemaLifecycle.configure,
          onCreate: SchemaLifecycle.create,
          onUpgrade: SchemaLifecycle.upgrade,
        ),
      );

  test('a v2 plan with videos, muscles and history survives the upgrade',
      () async {
    final Database v2 = await openV2();
    await v2.insert('exercises', <String, Object?>{
      'id': 'ex1',
      'name': 'Barbell Bench Press',
      'weekday': Weekday.monday.isoIndex,
      'order_index': 0,
      'target_sets': 4,
      'target_reps': 15,
      'load_note': '60 kg',
    });
    await v2.insert('exercise_videos', <String, Object?>{
      'id': 'vid1',
      'exercise_id': 'ex1',
      'local_uri': 'vid1.mp4',
      'order_index': 0,
      'label': 'Side angle',
      'note': 'Elbows tucked',
    });
    await v2.insert('exercise_muscle_groups', <String, Object?>{
      'exercise_id': 'ex1',
      'muscle_group_id': 'region:pectoralis',
    });
    await v2.insert('set_executions', <String, Object?>{
      'exercise_id': 'ex1',
      'set_index': 0,
      'week_token': '2026-W29',
      'outcome': 1,
      'recorded_at': 1000,
    });
    await v2.close();

    final Database v3 = await openV3();
    addTearDown(v3.close);

    final SqfliteRoutineRepository routines = SqfliteRoutineRepository(v3);
    final SqfliteMovementRepository movements = SqfliteMovementRepository(v3);

    final List<Exercise> monday =
        (await routines.fullWeek())[Weekday.monday]!;
    expect(monday, hasLength(1));

    final Exercise entry = monday.single;
    expect(entry.id, 'ex1');
    expect(entry.name, 'Barbell Bench Press');
    expect(entry.prescription, '4 × 15');
    expect(entry.loadNote, '60 kg');
    expect(entry.videos, hasLength(1));
    expect(entry.videos.single.localUri, 'vid1.mp4');
    expect(entry.videos.single.note, 'Elbows tucked');
    expect(entry.muscleGroups.map((m) => m.displayName), <String>['Chest']);

    final List<Movement> library = await movements.all();
    expect(library, hasLength(1));
    expect(library.single.id, 'mv:ex1');
    expect(library.single.videos, hasLength(1));

    final List<Map<String, Object?>> history =
        await v3.query('set_executions');
    expect(history, hasLength(1));
    expect(history.single['exercise_id'], 'ex1');
    expect(history.single['outcome'], 1);

    final List<Map<String, Object?>> oldTables = await v3.query(
      'sqlite_master',
      where: "type = 'table' AND name IN (?, ?, ?)",
      whereArgs: <Object?>['exercises', 'exercise_videos', 'exercise_muscle_groups'],
    );
    expect(oldTables, isEmpty);
  });

  test('deleting a migrated entry still cascades its history', () async {
    final Database v2 = await openV2();
    await v2.insert('exercises', <String, Object?>{
      'id': 'ex1',
      'name': 'Squat',
      'weekday': Weekday.tuesday.isoIndex,
      'order_index': 0,
      'target_sets': 5,
      'target_reps': 5,
    });
    await v2.insert('set_executions', <String, Object?>{
      'exercise_id': 'ex1',
      'set_index': 0,
      'week_token': '2026-W29',
      'outcome': 1,
      'recorded_at': 1000,
    });
    await v2.close();

    final Database v3 = await openV3();
    addTearDown(v3.close);

    await SqfliteRoutineRepository(v3).deleteEntry('ex1');
    expect(await v3.query('set_executions'), isEmpty);
  });
}
