abstract final class Tables {
  static const String muscleGroups = 'muscle_groups';
  static const String movements = 'movements';
  static const String movementMuscleGroups = 'movement_muscle_groups';
  static const String movementVideos = 'movement_videos';
  static const String planEntries = 'plan_entries';
  static const String setExecutions = 'set_executions';
  static const String journalEntries = 'journal_entries';
}

abstract final class SchemaVersion {
  static const int current = 3;
}

abstract final class MigrationStatements {
  static const Map<int, List<String>> byTargetVersion = <int, List<String>>{
    2: <String>[
      'ALTER TABLE exercise_videos ADD COLUMN note TEXT',
    ],
    3: _toLibraryModel,
  };

  static const List<String> _toLibraryModel = <String>[
    CreateStatements.movements,
    CreateStatements.movementMuscleGroups,
    CreateStatements.movementVideos,
    CreateStatements.planEntries,
    '''
    INSERT INTO ${Tables.movements} (id, name, summary, description)
    SELECT 'mv:' || id, name, NULL, NULL FROM exercises
    ''',
    '''
    INSERT INTO ${Tables.planEntries}
      (id, movement_id, weekday, order_index, target_sets, target_reps, load_note)
    SELECT id, 'mv:' || id, weekday, order_index, target_sets, target_reps, load_note
    FROM exercises
    ''',
    '''
    INSERT INTO ${Tables.movementVideos}
      (id, movement_id, local_uri, order_index, label, note)
    SELECT id, 'mv:' || exercise_id, local_uri, order_index, label, note
    FROM exercise_videos
    ''',
    '''
    INSERT INTO ${Tables.movementMuscleGroups} (movement_id, muscle_group_id)
    SELECT 'mv:' || exercise_id, muscle_group_id FROM exercise_muscle_groups
    ''',
    '''
    CREATE TABLE set_executions_v3 (
      exercise_id TEXT NOT NULL,
      set_index INTEGER NOT NULL CHECK (set_index >= 0),
      week_token TEXT NOT NULL,
      outcome INTEGER NOT NULL CHECK (outcome BETWEEN 0 AND 2),
      recorded_at INTEGER NOT NULL,
      PRIMARY KEY (exercise_id, set_index, week_token),
      FOREIGN KEY (exercise_id) REFERENCES ${Tables.planEntries} (id) ON DELETE CASCADE
    )
    ''',
    '''
    INSERT INTO set_executions_v3
      (exercise_id, set_index, week_token, outcome, recorded_at)
    SELECT exercise_id, set_index, week_token, outcome, recorded_at
    FROM ${Tables.setExecutions}
    ''',
    'DROP TABLE ${Tables.setExecutions}',
    'ALTER TABLE set_executions_v3 RENAME TO ${Tables.setExecutions}',
    'DROP TABLE exercise_videos',
    'DROP TABLE exercise_muscle_groups',
    'DROP TABLE exercises',
    CreateStatements.entriesByWeekday,
    CreateStatements.videosByMovement,
    CreateStatements.executionsByWeek,
    CreateStatements.executionsByRecordedAt,
  ];
}

abstract final class CreateStatements {
  static const List<String> all = <String>[
    muscleGroups,
    movements,
    movementMuscleGroups,
    movementVideos,
    planEntries,
    setExecutions,
    journalEntries,
    entriesByWeekday,
    executionsByWeek,
    executionsByRecordedAt,
    videosByMovement,
    journalByScope,
  ];

  static const String muscleGroups = '''
    CREATE TABLE ${Tables.muscleGroups} (
      id TEXT PRIMARY KEY NOT NULL,
      display_name TEXT NOT NULL,
      region TEXT
    )
  ''';

  static const String movements = '''
    CREATE TABLE ${Tables.movements} (
      id TEXT PRIMARY KEY NOT NULL,
      name TEXT NOT NULL,
      summary TEXT,
      description TEXT
    )
  ''';

  static const String movementMuscleGroups = '''
    CREATE TABLE ${Tables.movementMuscleGroups} (
      movement_id TEXT NOT NULL,
      muscle_group_id TEXT NOT NULL,
      PRIMARY KEY (movement_id, muscle_group_id),
      FOREIGN KEY (movement_id) REFERENCES ${Tables.movements} (id) ON DELETE CASCADE,
      FOREIGN KEY (muscle_group_id) REFERENCES ${Tables.muscleGroups} (id) ON DELETE CASCADE
    )
  ''';

  static const String movementVideos = '''
    CREATE TABLE ${Tables.movementVideos} (
      id TEXT PRIMARY KEY NOT NULL,
      movement_id TEXT NOT NULL,
      local_uri TEXT NOT NULL,
      order_index INTEGER NOT NULL,
      label TEXT,
      note TEXT,
      FOREIGN KEY (movement_id) REFERENCES ${Tables.movements} (id) ON DELETE CASCADE
    )
  ''';

  static const String planEntries = '''
    CREATE TABLE ${Tables.planEntries} (
      id TEXT PRIMARY KEY NOT NULL,
      movement_id TEXT NOT NULL,
      weekday INTEGER NOT NULL CHECK (weekday BETWEEN 1 AND 7),
      order_index INTEGER NOT NULL,
      target_sets INTEGER NOT NULL CHECK (target_sets > 0),
      target_reps INTEGER NOT NULL CHECK (target_reps > 0),
      load_note TEXT,
      FOREIGN KEY (movement_id) REFERENCES ${Tables.movements} (id) ON DELETE CASCADE
    )
  ''';

  static const String setExecutions = '''
    CREATE TABLE ${Tables.setExecutions} (
      exercise_id TEXT NOT NULL,
      set_index INTEGER NOT NULL CHECK (set_index >= 0),
      week_token TEXT NOT NULL,
      outcome INTEGER NOT NULL CHECK (outcome BETWEEN 0 AND 2),
      recorded_at INTEGER NOT NULL,
      PRIMARY KEY (exercise_id, set_index, week_token),
      FOREIGN KEY (exercise_id) REFERENCES ${Tables.planEntries} (id) ON DELETE CASCADE
    )
  ''';

  static const String journalEntries = '''
    CREATE TABLE ${Tables.journalEntries} (
      id TEXT PRIMARY KEY NOT NULL,
      scope TEXT NOT NULL CHECK (scope IN ('day', 'week', 'month', 'year')),
      scope_token TEXT NOT NULL,
      body TEXT NOT NULL,
      updated_at INTEGER NOT NULL,
      UNIQUE (scope, scope_token)
    )
  ''';

  static const String entriesByWeekday =
      'CREATE INDEX idx_entries_weekday ON ${Tables.planEntries} (weekday, order_index)';

  static const String executionsByWeek =
      'CREATE INDEX idx_executions_week ON ${Tables.setExecutions} (week_token)';

  static const String executionsByRecordedAt =
      'CREATE INDEX idx_executions_recorded_at ON ${Tables.setExecutions} (recorded_at)';

  static const String videosByMovement =
      'CREATE INDEX idx_videos_movement ON ${Tables.movementVideos} (movement_id, order_index)';

  static const String journalByScope =
      'CREATE INDEX idx_journal_scope ON ${Tables.journalEntries} (scope, scope_token)';
}
