import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../domain/entities/exercise.dart';
import '../domain/entities/movement.dart';
import '../domain/entities/weekday.dart';
import '../domain/repositories/movement_repository.dart';
import '../domain/repositories/routine_repository.dart';
import 'providers.dart';

typedef WeeklyRoutine = Map<Weekday, List<Exercise>>;

final class RoutineController extends AsyncNotifier<WeeklyRoutine> {
  static const Uuid _ids = Uuid();

  @override
  Future<WeeklyRoutine> build() =>
      ref.watch(routineRepositoryProvider).fullWeek();

  RoutineRepository get _routines => ref.read(routineRepositoryProvider);

  MovementRepository get _movements => ref.read(movementRepositoryProvider);

  Future<void> addEntry({
    required String movementId,
    required Weekday weekday,
    required int targetSets,
    required int targetReps,
    String? loadNote,
  }) async {
    final Movement? movement = await _movements.byId(movementId);
    if (movement == null) return;

    final List<Exercise> existing = state.value?[weekday] ?? const <Exercise>[];
    await _routines.saveEntry(
      Exercise(
        id: _ids.v4(),
        movement: movement,
        weekday: weekday,
        orderIndex: existing.length,
        targetSets: targetSets,
        targetReps: targetReps,
        loadNote: loadNote?.trim(),
      ),
    );
    ref.invalidateSelf();
  }

  Future<void> updateEntry(Exercise entry) async {
    await _routines.saveEntry(entry);
    ref.invalidateSelf();
  }

  Future<void> removeEntry(String entryId) async {
    await _routines.deleteEntry(entryId);
    ref.invalidateSelf();
  }

  Future<void> moveEntry(Weekday weekday, int from, int to) async {
    final List<Exercise>? current = state.value?[weekday];
    if (current == null || current.isEmpty) return;
    if (from == to) return;

    final List<Exercise> reordered = List<Exercise>.of(current);
    reordered.insert(to, reordered.removeAt(from));

    await _routines.reorderEntries(
      weekday,
      reordered.map((Exercise exercise) => exercise.id).toList(growable: false),
    );
    ref.invalidateSelf();
  }
}

final AsyncNotifierProvider<RoutineController, WeeklyRoutine>
    routineControllerProvider =
    AsyncNotifierProvider<RoutineController, WeeklyRoutine>(RoutineController.new);

final exercisesForDayProvider = Provider.family<List<Exercise>, Weekday>(
  (Ref ref, Weekday weekday) =>
      ref.watch(routineControllerProvider).value?[weekday] ??
      const <Exercise>[],
);

final exerciseByIdProvider = Provider.family<Exercise?, String>(
  (Ref ref, String exerciseId) {
    final WeeklyRoutine? week = ref.watch(routineControllerProvider).value;
    if (week == null) return null;
    for (final List<Exercise> day in week.values) {
      for (final Exercise exercise in day) {
        if (exercise.id == exerciseId) return exercise;
      }
    }
    return null;
  },
);
