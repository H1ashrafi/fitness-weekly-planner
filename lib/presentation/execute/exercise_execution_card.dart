import 'package:flutter/material.dart';

import '../../core/design/app_palette.dart';
import '../../core/design/fibonacci_scale.dart';
import '../../domain/entities/completion_tally.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/muscle_group.dart';
import '../../domain/entities/set_outcome.dart';
import '../movement/movement_detail_screen.dart';
import '../widgets/set_outcome_control.dart';

typedef OutcomeLookup = SetOutcome Function(int setIndex);
typedef OutcomeSelection = void Function(int setIndex, SetOutcome outcome);

final class ExerciseExecutionCard extends StatelessWidget {
  const ExerciseExecutionCard({
    required this.exercise,
    required this.tally,
    required this.outcomeFor,
    required this.onOutcomeSelected,
    super.key,
  });

  final Exercise exercise;
  final CompletionTally tally;
  final OutcomeLookup outcomeFor;
  final OutcomeSelection onOutcomeSelected;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final TextTheme text = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: FibonacciSpace.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Text(exercise.name, style: text.titleLarge),
                ),
                IconButton(
                  tooltip: 'Form videos',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          MovementDetailScreen(movementId: exercise.movementId),
                    ),
                  ),
                  icon: Icon(
                    Icons.smart_display_outlined,
                    color: exercise.hasVideos
                        ? palette.crimson
                        : palette.inkMuted,
                  ),
                ),
                if (tally.isPerfect)
                  Icon(
                    Icons.verified_rounded,
                    size: FibonacciSize.iconRegular,
                    color: palette.outcomeCompleted,
                  ),
              ],
            ),
            const SizedBox(height: FibonacciSpace.snug),
            Text(exercise.prescriptionSummary, style: text.bodyMedium),
            if (exercise.muscleGroups.isNotEmpty) ...<Widget>[
              const SizedBox(height: FibonacciSpace.compact),
              Wrap(
                spacing: FibonacciSpace.snug,
                runSpacing: FibonacciSpace.snug,
                children: <Widget>[
                  for (final MuscleGroup group in exercise.muscleGroups)
                    _MuscleChip(label: group.displayName),
                ],
              ),
            ],
            const SizedBox(height: FibonacciSpace.regular),
            const Divider(),
            for (final int setIndex in exercise.setIndices)
              _SetRow(
                ordinal: setIndex + 1,
                reps: exercise.targetReps,
                outcome: outcomeFor(setIndex),
                onSelected: (SetOutcome outcome) =>
                    onOutcomeSelected(setIndex, outcome),
              ),
          ],
        ),
      ),
    );
  }
}

final class _SetRow extends StatelessWidget {
  const _SetRow({
    required this.ordinal,
    required this.reps,
    required this.outcome,
    required this.onSelected,
  });

  final int ordinal;
  final int reps;
  final SetOutcome outcome;
  final ValueChanged<SetOutcome> onSelected;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final TextTheme text = Theme.of(context).textTheme;

    final Color labelColor = switch (outcome) {
      SetOutcome.completed => palette.outcomeCompleted,
      SetOutcome.failed => palette.outcomeFailed,
      SetOutcome.pending => palette.inkPrimary,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FibonacciSpace.snug),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              'Set $ordinal',
              style: text.titleMedium?.copyWith(
                color: labelColor,
                decoration: outcome == SetOutcome.failed
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
                decorationColor: palette.outcomeFailed,
              ),
            ),
          ),
          Text('$reps reps', style: text.labelSmall),
          const SizedBox(width: FibonacciSpace.regular),
          SetOutcomeControl(outcome: outcome, onSelected: onSelected),
        ],
      ),
    );
  }
}

final class _MuscleChip extends StatelessWidget {
  const _MuscleChip({required this.label});

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
