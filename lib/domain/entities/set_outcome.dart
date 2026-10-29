enum SetOutcome {
  pending(storageCode: 0, isResolved: false, countsTowardCompletion: false),
  completed(storageCode: 1, isResolved: true, countsTowardCompletion: true),
  failed(storageCode: 2, isResolved: true, countsTowardCompletion: false);

  const SetOutcome({
    required this.storageCode,
    required this.isResolved,
    required this.countsTowardCompletion,
  });

  final int storageCode;
  final bool isResolved;
  final bool countsTowardCompletion;

  static SetOutcome fromStorageCode(int code) => switch (code) {
        0 => SetOutcome.pending,
        1 => SetOutcome.completed,
        2 => SetOutcome.failed,
        _ => throw ArgumentError.value(code, 'code', 'Unmapped SetOutcome code'),
      };

  SetOutcome get toggledForward => switch (this) {
        SetOutcome.pending => SetOutcome.completed,
        SetOutcome.completed => SetOutcome.failed,
        SetOutcome.failed => SetOutcome.pending,
      };
}
