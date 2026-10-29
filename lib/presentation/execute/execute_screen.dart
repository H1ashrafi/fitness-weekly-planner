import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/execution_controller.dart';
import '../../application/execution_snapshot.dart';
import '../../core/design/app_palette.dart';
import '../../core/design/fibonacci_scale.dart';
import '../../domain/entities/exercise.dart';
import '../widgets/completion_dial.dart';
import 'exercise_execution_card.dart';

final class ExecuteScreen extends ConsumerWidget {
  const ExecuteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ExecutionSnapshot> snapshot =
        ref.watch(executionControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: switch (snapshot) {
          AsyncError(:final Object error) => _ExecutionFailure(error: error),
          AsyncLoading() => const Center(child: CircularProgressIndicator()),
          AsyncData(:final ExecutionSnapshot value) => _ExecutionBody(snapshot: value),
        },
      ),
    );
  }
}

final class _ExecutionBody extends ConsumerWidget {
  const _ExecutionBody({required this.snapshot});

  final ExecutionSnapshot snapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme text = Theme.of(context).textTheme;

    return CustomScrollView(
      slivers: <Widget>[
        SliverPadding(
          padding: FibonacciSpace.screenPadding,
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(snapshot.weekday.fullName, style: text.displayMedium),
                const SizedBox(height: FibonacciSpace.tight),
                Text(
                  snapshot.isRestDay
                      ? 'Rest day · week ${snapshot.week.isoWeek}'
                      : '${snapshot.exercises.length} exercises · week ${snapshot.week.isoWeek}',
                  style: text.bodyMedium,
                ),
                const SizedBox(height: FibonacciSpace.comfortable),
                if (!snapshot.isRestDay)
                  Center(child: CompletionDial(tally: snapshot.dayTally)),
                if (snapshot.isPerfectDay) const _PerfectDayBanner(),
                const SizedBox(height: FibonacciSpace.comfortable),
              ],
            ),
          ),
        ),
        if (snapshot.isRestDay)
          const SliverFillRemaining(hasScrollBody: false, child: _RestDayNotice())
        else
          SliverList.separated(
            itemCount: snapshot.exercises.length,
            separatorBuilder: (_, _) => const SizedBox(height: FibonacciSpace.regular),
            itemBuilder: (BuildContext context, int index) {
              final Exercise exercise = snapshot.exercises[index];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: FibonacciSpace.comfortable,
                ),
                child: ExerciseExecutionCard(
                  exercise: exercise,
                  tally: snapshot.tallyFor(exercise),
                  outcomeFor: (int setIndex) =>
                      snapshot.outcomeFor(exercise.id, setIndex),
                  onOutcomeSelected: (int setIndex, outcome) => ref
                      .read(executionControllerProvider.notifier)
                      .markOutcome(exercise.id, setIndex, outcome),
                ),
              );
            },
          ),
        const SliverToBoxAdapter(
          child: SizedBox(height: FibonacciSpace.generous),
        ),
      ],
    );
  }
}

final class _PerfectDayBanner extends StatelessWidget {
  const _PerfectDayBanner();

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Padding(
      padding: const EdgeInsets.only(top: FibonacciSpace.comfortable),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: FibonacciSpace.regular,
          vertical: FibonacciSpace.compact,
        ),
        decoration: BoxDecoration(
          color: palette.crimsonMuted,
          borderRadius: FibonacciRadius.chip,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.local_fire_department_rounded,
              color: palette.streakEmber,
              size: FibonacciSize.iconRegular,
            ),
            const SizedBox(width: FibonacciSpace.compact),
            Text(
              'Every set cleared today',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: palette.streakEmber),
            ),
          ],
        ),
      ),
    );
  }
}

final class _RestDayNotice extends StatelessWidget {
  const _RestDayNotice();

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
              Icons.self_improvement_rounded,
              size: FibonacciSize.iconProminent,
              color: palette.inkMuted,
            ),
            const SizedBox(height: FibonacciSpace.regular),
            Text(
              'Nothing scheduled today',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: FibonacciSpace.snug),
            Text(
              'Add exercises to this weekday in Plan.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

final class _ExecutionFailure extends StatelessWidget {
  const _ExecutionFailure({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: FibonacciSpace.screenPadding,
          child: Text(
            'Could not load today: $error',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      );
}
