import 'package:flutter/widgets.dart';

abstract final class FibonacciSpace {
  static const double micro = 1;
  static const double hair = 2;
  static const double tight = 3;
  static const double snug = 5;
  static const double compact = 8;
  static const double regular = 13;
  static const double comfortable = 21;
  static const double roomy = 34;
  static const double generous = 55;
  static const double expansive = 89;
  static const double colossal = 144;

  static const EdgeInsets screenPadding = EdgeInsets.all(comfortable);
  static const EdgeInsets cardPadding = EdgeInsets.all(regular);
  static const EdgeInsets listGutter = EdgeInsets.symmetric(
    horizontal: comfortable,
    vertical: compact,
  );
}

abstract final class FibonacciRadius {
  static const Radius hairline = Radius.circular(FibonacciSpace.tight);
  static const Radius subtle = Radius.circular(FibonacciSpace.snug);
  static const Radius standard = Radius.circular(FibonacciSpace.compact);
  static const Radius pronounced = Radius.circular(FibonacciSpace.regular);
  static const Radius dramatic = Radius.circular(FibonacciSpace.comfortable);

  static const BorderRadius card = BorderRadius.all(pronounced);
  static const BorderRadius sheet = BorderRadius.vertical(top: dramatic);
  static const BorderRadius chip = BorderRadius.all(standard);
  static const BorderRadius control = BorderRadius.all(subtle);
}

abstract final class FibonacciSize {
  static const double checkTarget = FibonacciSpace.roomy + FibonacciSpace.regular;
  static const double iconCompact = FibonacciSpace.regular;
  static const double iconRegular = FibonacciSpace.comfortable;
  static const double iconProminent = FibonacciSpace.roomy;
  static const double avatarRing = FibonacciSpace.generous;
  static const double progressDial = FibonacciSpace.colossal;
  static const double strokeHairline = FibonacciSpace.micro;
  static const double strokeRegular = FibonacciSpace.hair;
  static const double strokeEmphasis = FibonacciSpace.tight;
}
