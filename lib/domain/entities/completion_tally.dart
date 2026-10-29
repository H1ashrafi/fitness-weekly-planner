import 'package:flutter/foundation.dart';

import 'set_outcome.dart';

@immutable
final class CompletionTally {
  const CompletionTally({
    required this.completed,
    required this.failed,
    required this.pending,
  });

  const CompletionTally.empty()
      : completed = 0,
        failed = 0,
        pending = 0;

  factory CompletionTally.fromOutcomes(Iterable<SetOutcome> outcomes) {
    int completed = 0;
    int failed = 0;
    int pending = 0;
    for (final SetOutcome outcome in outcomes) {
      switch (outcome) {
        case SetOutcome.completed:
          completed++;
        case SetOutcome.failed:
          failed++;
        case SetOutcome.pending:
          pending++;
      }
    }
    return CompletionTally(completed: completed, failed: failed, pending: pending);
  }

  final int completed;
  final int failed;
  final int pending;

  int get total => completed + failed + pending;

  int get resolved => completed + failed;

  bool get isEmpty => total == 0;

  bool get isFullyResolved => !isEmpty && pending == 0;

  bool get isPerfect => !isEmpty && completed == total;

  double get completionRatio => isEmpty ? 0 : completed / total;

  double get resolutionRatio => isEmpty ? 0 : resolved / total;

  int get completionPercent => (completionRatio * 100).round();

  CompletionTally operator +(CompletionTally other) => CompletionTally(
        completed: completed + other.completed,
        failed: failed + other.failed,
        pending: pending + other.pending,
      );

  static CompletionTally sum(Iterable<CompletionTally> tallies) =>
      tallies.fold(const CompletionTally.empty(), (a, b) => a + b);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompletionTally &&
          other.completed == completed &&
          other.failed == failed &&
          other.pending == pending;

  @override
  int get hashCode => Object.hash(completed, failed, pending);

  @override
  String toString() => 'CompletionTally($completed✅ / $failed❌ / $pending·)';
}
