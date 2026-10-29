import 'package:flutter/material.dart';

import '../../core/design/app_palette.dart';
import '../../core/design/fibonacci_scale.dart';
import '../../domain/entities/anatomy_region.dart';
import 'anatomy_geometry.dart';

typedef RegionIntensities = Map<AnatomyRegion, double>;

final class AnatomyBodyMap extends StatelessWidget {
  const AnatomyBodyMap({
    required this.facing,
    required this.intensities,
    this.onRegionTap,
    super.key,
  });

  final AnatomyFacing facing;
  final RegionIntensities intensities;
  final ValueChanged<AnatomyRegion>? onRegionTap;

  static Path pathFor(Polygon polygon, double scale) {
    final Path path = Path()
      ..moveTo(polygon.first.dx * scale, polygon.first.dy * scale);
    for (final Offset point in polygon.skip(1)) {
      path.lineTo(point.dx * scale, point.dy * scale);
    }
    return path..close();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final AnatomyFigure figure = AnatomyGeometry.of(facing);

    return AspectRatio(
      aspectRatio: AnatomyGeometry.viewBox.width / AnatomyGeometry.viewBox.height,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double scale = constraints.maxWidth / AnatomyGeometry.viewBox.width;

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: onRegionTap == null
                ? null
                : (TapUpDetails details) =>
                    _handleTap(details.localPosition, scale, figure),
            child: CustomPaint(
              size: constraints.biggest,
              painter: _AnatomyPainter(
                figure: figure,
                intensities: intensities,
                scale: scale,
                decorColor: palette.surfaceRaised,
                idleColor: palette.crimsonMuted,
                engagedColor: palette.crimson,
                outlineColor: palette.hairline,
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleTap(Offset local, double scale, AnatomyFigure figure) {
    for (final AnatomyShape shape in figure.shapes.reversed) {
      if (pathFor(shape.polygon, scale).contains(local)) {
        onRegionTap!(shape.region);
        return;
      }
    }
  }
}

final class _AnatomyPainter extends CustomPainter {
  const _AnatomyPainter({
    required this.figure,
    required this.intensities,
    required this.scale,
    required this.decorColor,
    required this.idleColor,
    required this.engagedColor,
    required this.outlineColor,
  });

  final AnatomyFigure figure;
  final RegionIntensities intensities;
  final double scale;
  final Color decorColor;
  final Color idleColor;
  final Color engagedColor;
  final Color outlineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = FibonacciSize.strokeHairline
      ..color = outlineColor;

    final Paint decorFill = Paint()..color = decorColor;
    for (final AnatomyDecor decor in figure.decor) {
      if (decor.isEllipse) {
        final Rect rect = Rect.fromPoints(
          decor.polygon.first.scale(scale, scale),
          decor.polygon.last.scale(scale, scale),
        );
        canvas.drawOval(rect, decorFill);
        canvas.drawOval(rect, outline);
        continue;
      }
      final Path decorPath = AnatomyBodyMap.pathFor(decor.polygon, scale);
      canvas.drawPath(decorPath, decorFill);
      canvas.drawPath(decorPath, outline);
    }

    for (final AnatomyShape shape in figure.shapes) {
      final double intensity = (intensities[shape.region] ?? 0).clamp(0, 1);
      final Path path = AnatomyBodyMap.pathFor(shape.polygon, scale);
      final Paint fill = Paint()
        ..color = Color.lerp(idleColor, engagedColor, intensity)!;
      canvas.drawPath(path, fill);
      canvas.drawPath(path, outline);
    }
  }

  @override
  bool shouldRepaint(_AnatomyPainter old) =>
      old.intensities != intensities ||
      old.scale != scale ||
      old.figure != figure ||
      old.engagedColor != engagedColor;
}
