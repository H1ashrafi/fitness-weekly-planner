
import 'package:flutter_test/flutter_test.dart';
import 'package:hanimob2/domain/entities/anatomy_region.dart';
import 'package:hanimob2/presentation/anatomy/anatomy_body_map.dart';
import 'package:hanimob2/presentation/anatomy/anatomy_geometry.dart';

Offset centroidOf(Polygon polygon) {
  double x = 0;
  double y = 0;
  for (final Offset point in polygon) {
    x += point.dx;
    y += point.dy;
  }
  return Offset(x / polygon.length, y / polygon.length);
}

AnatomyRegion? resolveTap(AnatomyFigure figure, Offset point) {
  for (final AnatomyShape shape in figure.shapes.reversed) {
    if (AnatomyBodyMap.pathFor(shape.polygon, 1).contains(point)) {
      return shape.region;
    }
  }
  return null;
}

void main() {
  for (final AnatomyFacing facing in AnatomyFacing.values) {
    final AnatomyFigure figure = AnatomyGeometry.of(facing);

    group('${facing.name} figure', () {
      test('every shape polygon is a closed area of at least 4 vertices', () {
        for (final AnatomyShape shape in figure.shapes) {
          expect(shape.polygon.length, greaterThanOrEqualTo(4));
        }
      });

      test('tapping each region centroid selects that same region', () {
        for (final AnatomyShape shape in figure.shapes) {
          final Offset centroid = centroidOf(shape.polygon);
          expect(
            resolveTap(figure, centroid),
            shape.region,
            reason: '${shape.region.name} centroid $centroid misresolved',
          );
        }
      });

      test('all shapes stay within the view box', () {
        for (final AnatomyShape shape in figure.shapes) {
          for (final Offset point in shape.polygon) {
            expect(point.dx, inInclusiveRange(0, AnatomyGeometry.viewBox.width));
            expect(point.dy, inInclusiveRange(0, AnatomyGeometry.viewBox.height));
          }
        }
      });

      test('a point far outside the body resolves to nothing', () {
        expect(resolveTap(figure, const Offset(4, 4)), isNull);
      });

      test('exposes a non-empty set of distinct regions', () {
        final Set<AnatomyRegion> present =
            figure.shapes.map((AnatomyShape shape) => shape.region).toSet();
        expect(present, isNotEmpty);
      });
    });
  }

  test('forearm is the only region shared across both views', () {
    final Set<AnatomyRegion> anterior = AnatomyGeometry.of(AnatomyFacing.anterior)
        .shapes
        .map((AnatomyShape shape) => shape.region)
        .toSet();
    final Set<AnatomyRegion> posterior = AnatomyGeometry.of(AnatomyFacing.posterior)
        .shapes
        .map((AnatomyShape shape) => shape.region)
        .toSet();

    expect(anterior.intersection(posterior), <AnatomyRegion>{AnatomyRegion.forearm});
  });
}
