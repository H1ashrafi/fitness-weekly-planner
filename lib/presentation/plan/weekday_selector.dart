import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/routine_controller.dart';
import '../../core/design/app_palette.dart';
import '../../core/design/fibonacci_scale.dart';
import '../../domain/entities/weekday.dart';

final class WeekdaySelector extends ConsumerWidget {
  const WeekdaySelector({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final Weekday selected;
  final ValueChanged<Weekday> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) => SizedBox(
        height: FibonacciSpace.expansive,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: FibonacciSpace.comfortable,
          ),
          itemCount: Weekday.values.length,
          separatorBuilder: (_, _) => const SizedBox(width: FibonacciSpace.compact),
          itemBuilder: (BuildContext context, int index) {
            final Weekday day = Weekday.values[index];
            return _WeekdayPill(
              weekday: day,
              isSelected: day == selected,
              plannedCount: ref.watch(exercisesForDayProvider(day)).length,
              onTap: () => onSelected(day),
            );
          },
        ),
      );
}

final class _WeekdayPill extends StatelessWidget {
  const _WeekdayPill({
    required this.weekday,
    required this.isSelected,
    required this.plannedCount,
    required this.onTap,
  });

  final Weekday weekday;
  final bool isSelected;
  final int plannedCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final TextTheme text = Theme.of(context).textTheme;

    return Semantics(
      selected: isSelected,
      button: true,
      label: '${weekday.fullName}, $plannedCount exercises planned',
      child: InkWell(
        onTap: onTap,
        borderRadius: FibonacciRadius.card,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 233),
          curve: Curves.easeOutCubic,
          width: FibonacciSpace.roomy + FibonacciSpace.compact,
          padding: const EdgeInsets.symmetric(vertical: FibonacciSpace.compact),
          decoration: BoxDecoration(
            color: isSelected ? palette.crimson : palette.surface,
            borderRadius: FibonacciRadius.card,
            border: Border.all(
              color: isSelected ? palette.crimson : palette.hairline,
              width: FibonacciSize.strokeHairline,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                weekday.abbreviation.toUpperCase(),
                style: text.labelSmall?.copyWith(
                  color: isSelected ? palette.onCrimson : palette.inkMuted,
                ),
              ),
              const SizedBox(height: FibonacciSpace.tight),
              Container(
                width: FibonacciSpace.snug,
                height: FibonacciSpace.snug,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: plannedCount == 0
                      ? Colors.transparent
                      : isSelected
                          ? palette.onCrimson
                          : palette.crimson,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
