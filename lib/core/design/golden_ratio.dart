import 'dart:math' as math;

abstract final class GoldenRatio {
  static const double phi = 1.618033988749895;
  static final double rootPhi = math.sqrt(phi);
  static const double inverse = 1 / phi;

  static double majorOf(double whole) => whole * inverse;

  static double minorOf(double whole) => whole - majorOf(whole);

  static double growBy(double base, int steps) =>
      base * math.pow(phi, steps).toDouble();

  static double growByHalfStep(double base, int steps) =>
      base * math.pow(rootPhi, steps).toDouble();

  static const double portraitCardAspect = inverse;
  static const double landscapeCardAspect = phi;
  static const double heroSplitFraction = inverse;
}
