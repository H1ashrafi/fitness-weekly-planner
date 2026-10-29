import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/movement_library_controller.dart';
import '../../application/routine_controller.dart';
import '../../core/design/app_palette.dart';
import '../../core/design/fibonacci_scale.dart';
import '../../domain/entities/movement.dart';
import '../../domain/entities/muscle_group.dart';
import '../../domain/entities/weekday.dart';
import '../movement/movement_composer_sheet.dart';
import '../widgets/fibonacci_stepper.dart';

final class ExerciseComposerSheet extends ConsumerStatefulWidget {
  const ExerciseComposerSheet({required this.weekday, super.key});

  final Weekday weekday;

  @override
  ConsumerState<ExerciseComposerSheet> createState() =>
      _ExerciseComposerSheetState();
}

final class _ExerciseComposerSheetState
    extends ConsumerState<ExerciseComposerSheet> {
  final TextEditingController _loadNote = TextEditingController();

  String? _movementId;
  int _sets = 4;
  int _reps = 15;

  @override
  void dispose() {
    _loadNote.dispose();
    super.dispose();
  }

  Movement? _selectedIn(List<Movement> library) {
    final String? id = _movementId;
    if (id == null) return null;
    for (final Movement movement in library) {
      if (movement.id == id) return movement;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final List<Movement> library =
        ref.watch(movementLibraryProvider).value ?? const <Movement>[];
    final Movement? selected = _selectedIn(library);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            FibonacciSpace.comfortable,
            FibonacciSpace.compact,
            FibonacciSpace.comfortable,
            FibonacciSpace.comfortable,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('Add to ${widget.weekday.fullName}', style: text.headlineMedium),
              const SizedBox(height: FibonacciSpace.tight),
              Text(
                selected == null
                    ? 'Pick a movement from your library.'
                    : 'Set how many sets and reps for this day.',
                style: text.bodyMedium,
              ),
              const SizedBox(height: FibonacciSpace.comfortable),
              if (selected case final Movement movement)
                _Prescribe(
                  movement: movement,
                  sets: _sets,
                  reps: _reps,
                  loadNote: _loadNote,
                  onSetsChanged: (int value) => setState(() => _sets = value),
                  onRepsChanged: (int value) => setState(() => _reps = value),
                  onChangeMovement: () => setState(() => _movementId = null),
                  onSave: _save,
                )
              else
                _MovementPicker(
                  onSelected: (String id) => setState(() => _movementId = id),
                  onCreateNew: _createNewMovement,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createNewMovement() async {
    final String? created = await showMovementComposer(context);
    if (created != null && mounted) setState(() => _movementId = created);
  }

  Future<void> _save() async {
    final String? id = _movementId;
    if (id == null) return;

    await ref.read(routineControllerProvider.notifier).addEntry(
          movementId: id,
          weekday: widget.weekday,
          targetSets: _sets,
          targetReps: _reps,
          loadNote: _loadNote.text,
        );

    if (mounted) Navigator.of(context).pop();
  }
}

final class _MovementPicker extends ConsumerWidget {
  const _MovementPicker({required this.onSelected, required this.onCreateNew});

  final ValueChanged<String> onSelected;
  final VoidCallback onCreateNew;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Movement> library =
        ref.watch(movementLibraryProvider).value ?? const <Movement>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        OutlinedButton.icon(
          onPressed: onCreateNew,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Create a new movement'),
        ),
        if (library.isNotEmpty) ...<Widget>[
          const SizedBox(height: FibonacciSpace.regular),
          for (final Movement movement in library)
            Padding(
              padding: const EdgeInsets.only(bottom: FibonacciSpace.compact),
              child: _PickableMovementTile(
                movement: movement,
                onTap: () => onSelected(movement.id),
              ),
            ),
        ] else ...<Widget>[
          const SizedBox(height: FibonacciSpace.regular),
          Text(
            'Your library is empty. Create a movement to add it here.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ],
    );
  }
}

final class _PickableMovementTile extends StatelessWidget {
  const _PickableMovementTile({required this.movement, required this.onTap});

  final Movement movement;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final TextTheme text = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
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
                  ],
                ),
              ),
              if (movement.hasVideos)
                Padding(
                  padding: const EdgeInsets.only(right: FibonacciSpace.snug),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.play_circle_outline_rounded,
                        size: FibonacciSize.iconCompact,
                        color: palette.inkMuted,
                      ),
                      const SizedBox(width: FibonacciSpace.hair),
                      Text('${movement.videoCount}', style: text.labelSmall),
                    ],
                  ),
                ),
              Icon(Icons.add_circle_outline_rounded, color: palette.crimson),
            ],
          ),
        ),
      ),
    );
  }
}

final class _Prescribe extends StatelessWidget {
  const _Prescribe({
    required this.movement,
    required this.sets,
    required this.reps,
    required this.loadNote,
    required this.onSetsChanged,
    required this.onRepsChanged,
    required this.onChangeMovement,
    required this.onSave,
  });

  final Movement movement;
  final int sets;
  final int reps;
  final TextEditingController loadNote;
  final ValueChanged<int> onSetsChanged;
  final ValueChanged<int> onRepsChanged;
  final VoidCallback onChangeMovement;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final TextTheme text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          padding: FibonacciSpace.cardPadding,
          decoration: BoxDecoration(
            color: palette.crimsonMuted,
            borderRadius: FibonacciRadius.card,
          ),
          child: Row(
            children: <Widget>[
              Icon(Icons.fitness_center_rounded, color: palette.crimson),
              const SizedBox(width: FibonacciSpace.compact),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      movement.name,
                      style: text.titleMedium?.copyWith(color: palette.crimson),
                    ),
                    if (movement.hasSummary)
                      Text(
                        movement.summary!,
                        style: text.labelSmall?.copyWith(color: palette.crimson),
                      ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onChangeMovement,
                child: const Text('Change'),
              ),
            ],
          ),
        ),
        const SizedBox(height: FibonacciSpace.regular),
        Row(
          children: <Widget>[
            Expanded(
              child: FibonacciStepper(
                label: 'Sets',
                value: sets,
                minimum: 1,
                maximum: 21,
                onChanged: onSetsChanged,
              ),
            ),
            const SizedBox(width: FibonacciSpace.regular),
            Expanded(
              child: FibonacciStepper(
                label: 'Reps',
                value: reps,
                minimum: 1,
                maximum: 55,
                onChanged: onRepsChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: FibonacciSpace.regular),
        TextField(
          controller: loadNote,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Note for this day',
            hintText: 'e.g. 60 kg, drop set on the last one (optional)',
          ),
        ),
        const SizedBox(height: FibonacciSpace.roomy),
        FilledButton(
          onPressed: onSave,
          child: const Text('Add to plan'),
        ),
        if (movement.muscleGroups.isNotEmpty) ...<Widget>[
          const SizedBox(height: FibonacciSpace.regular),
          Wrap(
            spacing: FibonacciSpace.snug,
            runSpacing: FibonacciSpace.snug,
            children: <Widget>[
              for (final MuscleGroup group in movement.muscleGroups)
                Chip(label: Text(group.displayName)),
            ],
          ),
        ],
      ],
    );
  }
}
