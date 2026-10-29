
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hanimob2/core/design/app_theme.dart';
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

void main() {
  Future<AnatomyRegion?> tapRegionAt(
    WidgetTester tester,
    AnatomyFacing facing,
    Offset viewBoxPoint,
  ) async {
    AnatomyRegion? tapped;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: AnatomyGeometry.viewBox.width,
              height: AnatomyGeometry.viewBox.height,
              child: AnatomyBodyMap(
                facing: facing,
                intensities: const <AnatomyRegion, double>{},
                onRegionTap: (AnatomyRegion region) => tapped = region,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Offset topLeft = tester.getTopLeft(find.byType(AnatomyBodyMap));
    await tester.tapAt(topLeft + viewBoxPoint);
    await tester.pumpAndSettle();
    return tapped;
  }

  testWidgets('tapping the chest on the front view selects pectoralis',
      (tester) async {
    final AnatomyShape chest = AnatomyGeometry.of(AnatomyFacing.anterior)
        .shapes
        .firstWhere((AnatomyShape s) => s.region == AnatomyRegion.pectoralis);

    final AnatomyRegion? tapped =
        await tapRegionAt(tester, AnatomyFacing.anterior, centroidOf(chest.polygon));

    expect(tapped, AnatomyRegion.pectoralis);
  });

  testWidgets('tapping a thigh on the front view selects quadriceps',
      (tester) async {
    final AnatomyShape thigh = AnatomyGeometry.of(AnatomyFacing.anterior)
        .shapes
        .firstWhere((AnatomyShape s) => s.region == AnatomyRegion.quadriceps);

    final AnatomyRegion? tapped =
        await tapRegionAt(tester, AnatomyFacing.anterior, centroidOf(thigh.polygon));

    expect(tapped, AnatomyRegion.quadriceps);
  });

  testWidgets('tapping the upper back on the rear view selects trapezius',
      (tester) async {
    final AnatomyShape traps = AnatomyGeometry.of(AnatomyFacing.posterior)
        .shapes
        .firstWhere((AnatomyShape s) => s.region == AnatomyRegion.trapezius);

    final AnatomyRegion? tapped =
        await tapRegionAt(tester, AnatomyFacing.posterior, centroidOf(traps.polygon));

    expect(tapped, AnatomyRegion.trapezius);
  });

  testWidgets('tapping empty space selects nothing', (tester) async {
    final AnatomyRegion? tapped =
        await tapRegionAt(tester, AnatomyFacing.anterior, const Offset(6, 6));

    expect(tapped, isNull);
  });
}
