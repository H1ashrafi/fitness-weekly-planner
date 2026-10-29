import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../core/time/clock.dart';
import '../data/repositories/sqflite_execution_repository.dart';
import '../data/repositories/sqflite_movement_repository.dart';
import '../data/repositories/sqflite_routine_repository.dart';
import '../domain/repositories/execution_repository.dart';
import '../domain/repositories/movement_repository.dart';
import '../domain/repositories/routine_repository.dart';
import '../domain/repositories/video_store.dart';

final Provider<Database> databaseProvider = Provider<Database>(
  (Ref ref) => throw UnimplementedError(
    'databaseProvider must be overridden with an opened Database at startup',
  ),
);

final Provider<VideoStore> videoStoreProvider = Provider<VideoStore>(
  (Ref ref) => throw UnimplementedError(
    'videoStoreProvider must be overridden with an opened VideoStore at startup',
  ),
);

final Provider<Clock> clockProvider = Provider<Clock>((Ref ref) => const SystemClock());

final Provider<RoutineRepository> routineRepositoryProvider =
    Provider<RoutineRepository>(
  (Ref ref) => SqfliteRoutineRepository(ref.watch(databaseProvider)),
);

final Provider<MovementRepository> movementRepositoryProvider =
    Provider<MovementRepository>(
  (Ref ref) => SqfliteMovementRepository(ref.watch(databaseProvider)),
);

final Provider<MuscleGroupRepository> muscleGroupRepositoryProvider =
    Provider<MuscleGroupRepository>(
  (Ref ref) => SqfliteMuscleGroupRepository(ref.watch(databaseProvider)),
);

final Provider<ExecutionRepository> executionRepositoryProvider =
    Provider<ExecutionRepository>(
  (Ref ref) => SqfliteExecutionRepository(ref.watch(databaseProvider)),
);
