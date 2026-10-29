import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../application/routine_controller.dart';
import '../../core/design/app_palette.dart';
import '../../core/design/fibonacci_scale.dart';
import '../../core/time/clock.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/weekday.dart';
import '../movement/movement_detail_screen.dart';
import 'exercise_composer_sheet.dart';
import 'weekday_selector.dart';

final class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key});

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

final class _PlanScreenState extends ConsumerState<PlanScreen> {
  Weekday? _chosen;

  Weekday get _selected => _chosen ?? ref.read(clockProvider).today;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final Weekday selected = _selected;
    final List<Exercise> exercises = ref.watch(exercisesForDayProvider(selected));

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openComposer(selected),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add exercise'),
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
                  Text('Weekly plan', style: text.displayMedium),
                  const SizedBox(height: FibonacciSpace.tight),
                  Text(
                    'A fixed routine that repeats every week.',
                    style: text.bodyMedium,
                  ),
                ],
              ),
            ),
            WeekdaySelector(
              selected: selected,
              onSelected: (Weekday day) => setState(() => _chosen = day),
            ),
            const SizedBox(height: FibonacciSpace.compact),
            Expanded(
              child: exercises.isEmpty
                  ? _EmptyDay(weekday: selected)
                  : _ExerciseReorderList(weekday: selected, exercises: exercises),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openComposer(Weekday weekday) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => ExerciseComposerSheet(weekday: weekday),
      );
}

final class _ExerciseReorderList extends ConsumerWidget {
  const _ExerciseReorderList({required this.weekday, required this.exercises});

  final Weekday weekday;
  final List<Exercise> exercises;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ReorderableListView.builder(
        padding: const EdgeInsets.fromLTRB(
          FibonacciSpace.comfortable,
          0,
          FibonacciSpace.comfortable,
          FibonacciSpace.expansive,
        ),
        itemCount: exercises.length,
        onReorderItem: (int from, int to) => ref
            .read(routineControllerProvider.notifier)
            .moveEntry(weekday, from, to),
        itemBuilder: (BuildContext context, int index) {
          final Exercise exercise = exercises[index];
          return Padding(
            key: ValueKey<String>(exercise.id),
            padding: const EdgeInsets.only(bottom: FibonacciSpace.compact),
            child: _PlannedExerciseTile(exercise: exercise),
          );
        },
      );
}

final class _PlannedExerciseTile extends ConsumerWidget {
  const _PlannedExerciseTile({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = context.palette;
    final TextTheme text = Theme.of(context).textTheme;

    return Dismissible(
      key: ValueKey<String>('dismiss-${exercise.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: FibonacciSpace.comfortable),
        decoration: BoxDecoration(
          color: palette.outcomeFailed,
          borderRadius: FibonacciRadius.card,
        ),
        child: Icon(Icons.delete_outline_rounded, color: palette.onCrimson),
      ),
      onDismissed: (_) => ref
          .read(routineControllerProvider.notifier)
          .removeEntry(exercise.id),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  MovementDetailScreen(movementId: exercise.movementId),
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
                      Text(exercise.name, style: text.titleMedium),
                      const SizedBox(height: FibonacciSpace.tight),
                      Text(exercise.prescriptionSummary, style: text.labelSmall),
                    ],
                  ),
                ),
                if (exercise.hasVideos)
                  Padding(
                    padding: const EdgeInsets.only(right: FibonacciSpace.compact),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          Icons.play_circle_outline_rounded,
                          size: FibonacciSize.iconCompact,
                          color: palette.inkMuted,
                        ),
                        const SizedBox(width: FibonacciSpace.hair),
                        Text('${exercise.videoCount}', style: text.labelSmall),
                      ],
                    ),
                  ),
                Icon(Icons.drag_handle_rounded, color: palette.inkMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _EmptyDay extends StatelessWidget {
  const _EmptyDay({required this.weekday});

  final Weekday weekday;

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
              Icons.add_task_rounded,
              size: FibonacciSize.iconProminent,
              color: palette.inkMuted,
            ),
            const SizedBox(height: FibonacciSpace.regular),
            Text(
              '${weekday.fullName} is a rest day',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: FibonacciSpace.snug),
            Text(
              'Add an exercise to make it a training day.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
