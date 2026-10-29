import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/design/app_palette.dart';
import '../../core/design/fibonacci_scale.dart';
import '../../domain/entities/completion_tally.dart';

final class CompletionDial extends StatelessWidget {
  const CompletionDial({
    required this.tally,
    this.diameter = FibonacciSize.progressDial,
    super.key,
  });

  final CompletionTally tally;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final TextTheme text = Theme.of(context).textTheme;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: tally.completionRatio),
      duration: const Duration(milliseconds: 610),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double animatedRatio, _) => SizedBox.square(
        dimension: diameter,
        child: CustomPaint(
          painter: _DialPainter(
            completedFraction: animatedRatio,
            failedFraction: tally.isEmpty ? 0 : tally.failed / tally.total,
            trackColor: palette.hairline,
            completedColor: palette.outcomeCompleted,
            failedColor: palette.outcomeFailed,
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(FibonacciSpace.comfortable),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${(animatedRatio * 100).round()}%',
                      maxLines: 1,
                      style: text.displayMedium?.copyWith(
                        color: tally.isPerfect
                            ? palette.outcomeCompleted
                            : palette.inkPrimary,
                      ),
                    ),
                  ),
                  if (!tally.isEmpty)
                    Text(
                      '${tally.completed} of ${tally.total} sets',
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.fade,
                      style: text.labelSmall,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _DialPainter extends CustomPainter {
  const _DialPainter({
    required this.completedFraction,
    required this.failedFraction,
    required this.trackColor,
    required this.completedColor,
    required this.failedColor,
  });

  final double completedFraction;
  final double failedFraction;
  final Color trackColor;
  final Color completedColor;
  final Color failedColor;

  static const double _fullTurn = 2 * math.pi;
  static const double _twelveOClock = -math.pi / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect bounds = Offset.zero & size;
    final double stroke = FibonacciSpace.compact;
    final Rect arcRect = bounds.deflate(stroke / 2);

    final Paint track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = trackColor;
    canvas.drawArc(arcRect, _twelveOClock, _fullTurn, false, track);

    if (failedFraction > 0) {
      final Paint failed = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = failedColor;
      canvas.drawArc(
        arcRect,
        _twelveOClock + _fullTurn * (1 - failedFraction),
        _fullTurn * failedFraction,
        false,
        failed,
      );
    }

    if (completedFraction <= 0) return;

    final Paint completed = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = completedColor;
    canvas.drawArc(
      arcRect,
      _twelveOClock,
      _fullTurn * completedFraction,
      false,
      completed,
    );
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.completedFraction != completedFraction ||
      old.failedFraction != failedFraction ||
      old.trackColor != trackColor ||
      old.completedColor != completedColor ||
      old.failedColor != failedColor;
}
