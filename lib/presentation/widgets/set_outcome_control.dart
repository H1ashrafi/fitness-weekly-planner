import 'package:flutter/material.dart';

import '../../core/design/app_palette.dart';
import '../../core/design/fibonacci_scale.dart';
import '../../domain/entities/set_outcome.dart';

final class SetOutcomeControl extends StatelessWidget {
  const SetOutcomeControl({
    required this.outcome,
    required this.onSelected,
    super.key,
  });

  final SetOutcome outcome;
  final ValueChanged<SetOutcome> onSelected;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _OutcomeButton(
          icon: Icons.check_rounded,
          semanticLabel: 'Mark set completed',
          isSelected: outcome == SetOutcome.completed,
          accent: palette.outcomeCompleted,
          onPressed: () => onSelected(
            outcome == SetOutcome.completed ? SetOutcome.pending : SetOutcome.completed,
          ),
        ),
        const SizedBox(width: FibonacciSpace.compact),
        _OutcomeButton(
          icon: Icons.close_rounded,
          semanticLabel: 'Mark set failed or skipped',
          isSelected: outcome == SetOutcome.failed,
          accent: palette.outcomeFailed,
          onPressed: () => onSelected(
            outcome == SetOutcome.failed ? SetOutcome.pending : SetOutcome.failed,
          ),
        ),
      ],
    );
  }
}

final class _OutcomeButton extends StatelessWidget {
  const _OutcomeButton({
    required this.icon,
    required this.semanticLabel,
    required this.isSelected,
    required this.accent,
    required this.onPressed,
  });

  final IconData icon;
  final String semanticLabel;
  final bool isSelected;
  final Color accent;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Semantics(
      label: semanticLabel,
      selected: isSelected,
      button: true,
      child: InkWell(
        onTap: onPressed,
        borderRadius: FibonacciRadius.control,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 233),
          curve: Curves.easeOutCubic,
          width: FibonacciSize.checkTarget,
          height: FibonacciSize.checkTarget,
          decoration: BoxDecoration(
            color: isSelected ? accent : Colors.transparent,
            borderRadius: FibonacciRadius.control,
            border: Border.all(
              color: isSelected ? accent : palette.hairline,
              width: isSelected
                  ? FibonacciSize.strokeRegular
                  : FibonacciSize.strokeHairline,
            ),
          ),
          child: Icon(
            icon,
            size: FibonacciSize.iconRegular,
            color: isSelected ? palette.canvas : palette.inkMuted,
          ),
        ),
      ),
    );
  }
}
