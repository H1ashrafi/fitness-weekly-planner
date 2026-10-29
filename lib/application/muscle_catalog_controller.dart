import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../domain/entities/anatomy_region.dart';
import '../domain/entities/muscle_group.dart';
import '../domain/repositories/routine_repository.dart';
import 'providers.dart';

final class MuscleCatalogController extends AsyncNotifier<List<MuscleGroup>> {
  static const Uuid _ids = Uuid();

  @override
  Future<List<MuscleGroup>> build() =>
      ref.watch(muscleGroupRepositoryProvider).all();

  MuscleGroupRepository get _catalog => ref.read(muscleGroupRepositoryProvider);

  Future<void> addCustom(String displayName) async {
    final String trimmed = displayName.trim();
    if (trimmed.isEmpty) return;

    final bool alreadyPresent = (state.value ?? const <MuscleGroup>[]).any(
      (MuscleGroup group) =>
          group.displayName.toLowerCase() == trimmed.toLowerCase(),
    );
    if (alreadyPresent) return;

    await _catalog.save(MuscleGroup(id: _ids.v4(), displayName: trimmed));
    ref.invalidateSelf();
  }

  Future<void> remove(String groupId) async {
    await _catalog.delete(groupId);
    ref.invalidateSelf();
  }

  Future<void> rename(MuscleGroup group, String displayName) async {
    final String trimmed = displayName.trim();
    if (trimmed.isEmpty) return;

    await _catalog.save(group.copyWith(displayName: trimmed));
    ref.invalidateSelf();
  }
}

final AsyncNotifierProvider<MuscleCatalogController, List<MuscleGroup>>
    muscleCatalogProvider =
    AsyncNotifierProvider<MuscleCatalogController, List<MuscleGroup>>(
  MuscleCatalogController.new,
);

final Provider<List<MuscleGroup>> anatomyBackedGroupsProvider =
    Provider<List<MuscleGroup>>(
  (Ref ref) => (ref.watch(muscleCatalogProvider).value ?? const <MuscleGroup>[])
      .where((MuscleGroup group) => group.isAnatomyBacked)
      .toList(growable: false),
);

final Provider<List<MuscleGroup>> customGroupsProvider = Provider<List<MuscleGroup>>(
  (Ref ref) => (ref.watch(muscleCatalogProvider).value ?? const <MuscleGroup>[])
      .where((MuscleGroup group) => group.isUserDefined)
      .toList(growable: false),
);

final Provider<Map<AnatomyRegion, MuscleGroup>> groupsByRegionProvider =
    Provider<Map<AnatomyRegion, MuscleGroup>>(
  (Ref ref) => <AnatomyRegion, MuscleGroup>{
    for (final MuscleGroup group in ref.watch(anatomyBackedGroupsProvider))
      group.region!: group,
  },
);
