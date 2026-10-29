import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/movement_library_controller.dart';
import '../../core/design/app_palette.dart';
import '../../core/design/fibonacci_scale.dart';
import '../../domain/entities/movement.dart';
import '../../domain/entities/muscle_group.dart';
import 'movement_composer_sheet.dart';
import 'movement_detail_screen.dart';

final class MovementsScreen extends ConsumerWidget {
  const MovementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme text = Theme.of(context).textTheme;
    final List<Movement> library =
        ref.watch(movementLibraryProvider).value ?? const <Movement>[];

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showMovementComposer(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New movement'),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                FibonacciSpace.comfortable,
                FibonacciSpace.comfortable,
                FibonacciSpace.comfortable,
                FibonacciSpace.compact,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Movements', style: text.displayMedium),
                  const SizedBox(height: FibonacciSpace.tight),
                  Text(
                    'Your exercise library. Define a movement once with its '
                    'videos and notes, then reuse it any day.',
                    style: text.bodyMedium,
                  ),
                ],
              ),
            ),
            Expanded(
              child: library.isEmpty
                  ? const _EmptyLibrary()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        FibonacciSpace.comfortable,
                        FibonacciSpace.compact,
                        FibonacciSpace.comfortable,
                        FibonacciSpace.expansive,
                      ),
                      itemCount: library.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: FibonacciSpace.compact),
                      itemBuilder: (BuildContext context, int index) =>
                          _MovementTile(movement: library[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _MovementTile extends ConsumerWidget {
  const _MovementTile({required this.movement});

  final Movement movement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = context.palette;
    final TextTheme text = Theme.of(context).textTheme;

    return Dismissible(
      key: ValueKey<String>('dismiss-${movement.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: FibonacciSpace.comfortable),
        decoration: BoxDecoration(
          color: palette.outcomeFailed,
          borderRadius: FibonacciRadius.card,
        ),
        child: Icon(Icons.delete_outline_rounded, color: palette.onCrimson),
      ),
      onDismissed: (_) =>
          ref.read(movementLibraryProvider.notifier).deleteMovement(movement.id),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => MovementDetailScreen(movementId: movement.id),
            ),
          ),
          child: Padding(
            padding: FibonacciSpace.cardPadding,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(movement.name, style: text.titleMedium),
                      if (movement.hasSummary) ...<Widget>[
                        const SizedBox(height: FibonacciSpace.tight),
                        Text(movement.summary!, style: text.labelSmall),
                      ],
                      if (movement.muscleGroups.isNotEmpty) ...<Widget>[
                        const SizedBox(height: FibonacciSpace.snug),
                        Wrap(
                          spacing: FibonacciSpace.snug,
                          runSpacing: FibonacciSpace.snug,
                          children: <Widget>[
                            for (final MuscleGroup group in movement.muscleGroups)
                              _MiniMuscleChip(label: group.displayName),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: FibonacciSpace.compact),
                _VideoBadge(count: movement.videoCount),
                const SizedBox(width: FibonacciSpace.snug),
                Icon(Icons.chevron_right_rounded, color: palette.inkMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async =>
      await showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) => AlertDialog(
          title: Text('Delete ${movement.name}?'),
          content: const Text(
            'This removes the movement, its videos and notes, and every '
            'plan entry that uses it. Recorded set history for those entries '
            'is cleared too.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        ),
      ) ??
      false;
}

final class _VideoBadge extends StatelessWidget {
  const _VideoBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final Color tint = count > 0 ? palette.crimson : palette.inkMuted;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          count > 0
              ? Icons.play_circle_outline_rounded
              : Icons.videocam_off_outlined,
          size: FibonacciSize.iconCompact,
          color: tint,
        ),
        const SizedBox(width: FibonacciSpace.hair),
        Text(
          '$count',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: tint),
        ),
      ],
    );
  }
}

final class _MiniMuscleChip extends StatelessWidget {
  const _MiniMuscleChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: FibonacciSpace.compact,
        vertical: FibonacciSpace.tight,
      ),
      decoration: BoxDecoration(
        color: palette.crimsonMuted,
        borderRadius: FibonacciRadius.chip,
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: palette.crimson),
      ),
    );
  }
}

final class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary();

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Center(
      child: Padding(
        padding: FibonacciSpace.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.fitness_center_rounded,
              size: FibonacciSize.iconProminent,
              color: palette.inkMuted,
            ),
            const SizedBox(height: FibonacciSpace.regular),
            Text(
              'No movements yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: FibonacciSpace.snug),
            Text(
              'Create your first movement — add its videos and target '
              'muscles — then add it to any day in your plan.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
