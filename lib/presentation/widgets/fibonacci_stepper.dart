import 'package:flutter/material.dart';

import '../../core/design/app_palette.dart';
import '../../core/design/fibonacci_scale.dart';

final class FibonacciStepper extends StatelessWidget {
  const FibonacciStepper({
    required this.label,
    required this.value,
    required this.minimum,
    required this.maximum,
    required this.onChanged,
    super.key,
  });

  final String label;
  final int value;
  final int minimum;
  final int maximum;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final TextTheme text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: FibonacciSpace.compact,
        vertical: FibonacciSpace.compact,
      ),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: FibonacciRadius.control,
        border: Border.all(
          color: palette.hairline,
          width: FibonacciSize.strokeHairline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: text.labelSmall),
          const SizedBox(height: FibonacciSpace.tight),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              _StepButton(
                icon: Icons.remove_rounded,
                semanticLabel: 'Decrease $label',
                onPressed: value > minimum ? () => onChanged(value - 1) : null,
              ),
              Text('$value', style: text.headlineMedium),
              _StepButton(
                icon: Icons.add_rounded,
                semanticLabel: 'Increase $label',
                onPressed: value < maximum ? () => onChanged(value + 1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Semantics(
      label: semanticLabel,
      button: true,
      child: InkWell(
        onTap: onPressed,
        borderRadius: FibonacciRadius.chip,
        child: SizedBox.square(
          dimension: FibonacciSpace.roomy,
          child: Icon(
            icon,
            size: FibonacciSize.iconCompact,
            color: onPressed == null ? palette.hairline : palette.crimson,
          ),
        ),
      ),
    );
  }
}
