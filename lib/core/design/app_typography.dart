import 'package:flutter/material.dart';

abstract final class SansSerifStack {
  static const String primary = 'Inter';
  static const List<String> fallbacks = <String>[
    'SF Pro Text',
    'Roboto',
    'Segoe UI',
    'Helvetica Neue',
    'Arial',
  ];
}

abstract final class GoldenTypeScale {
  static const double caption = 13;
  static const double body = 16;
  static const double title = 21;
  static const double heading = 27;
  static const double headline = 34;
  static const double display = 43;
  static const double hero = 55;
}

abstract final class AppTypography {
  static TextTheme resolveFor(Color inkPrimary, Color inkMuted) => TextTheme(
        displayLarge: _sans(GoldenTypeScale.hero, FontWeight.w700, inkPrimary, -1.5),
        displayMedium: _sans(GoldenTypeScale.display, FontWeight.w700, inkPrimary, -1.0),
        headlineLarge: _sans(GoldenTypeScale.headline, FontWeight.w600, inkPrimary, -0.8),
        headlineMedium: _sans(GoldenTypeScale.heading, FontWeight.w600, inkPrimary, -0.5),
        titleLarge: _sans(GoldenTypeScale.title, FontWeight.w600, inkPrimary, -0.3),
        titleMedium: _sans(GoldenTypeScale.body, FontWeight.w600, inkPrimary, 0),
        bodyLarge: _sans(GoldenTypeScale.body, FontWeight.w400, inkPrimary, 0),
        bodyMedium: _sans(GoldenTypeScale.body, FontWeight.w400, inkMuted, 0),
        labelLarge: _sans(GoldenTypeScale.caption, FontWeight.w600, inkPrimary, 0.5),
        labelSmall: _sans(GoldenTypeScale.caption, FontWeight.w500, inkMuted, 0.5),
      );

  static TextStyle _sans(
    double size,
    FontWeight weight,
    Color color,
    double tracking,
  ) =>
      TextStyle(
        fontFamily: SansSerifStack.primary,
        fontFamilyFallback: SansSerifStack.fallbacks,
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: tracking,
        height: 1.382,
      );
}
