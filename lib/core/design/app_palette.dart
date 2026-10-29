import 'package:flutter/material.dart';

@immutable
final class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.crimson,
    required this.crimsonMuted,
    required this.canvas,
    required this.surface,
    required this.surfaceRaised,
    required this.hairline,
    required this.inkPrimary,
    required this.inkMuted,
    required this.onCrimson,
    required this.outcomeCompleted,
    required this.outcomeFailed,
    required this.outcomePending,
    required this.streakEmber,
  });

  final Color crimson;
  final Color crimsonMuted;
  final Color canvas;
  final Color surface;
  final Color surfaceRaised;
  final Color hairline;
  final Color inkPrimary;
  final Color inkMuted;
  final Color onCrimson;
  final Color outcomeCompleted;
  final Color outcomeFailed;
  final Color outcomePending;
  final Color streakEmber;

  static const AppPalette light = AppPalette(
    crimson: Color(0xFFA4133C),
    crimsonMuted: Color(0xFFF3D9E1),
    canvas: Color(0xFFFFFFFF),
    surface: Color(0xFFF7F4F5),
    surfaceRaised: Color(0xFFFFFFFF),
    hairline: Color(0xFFE4DCDF),
    inkPrimary: Color(0xFF14090C),
    inkMuted: Color(0xFF6B5B60),
    onCrimson: Color(0xFFFFFFFF),
    outcomeCompleted: Color(0xFF1B5E43),
    outcomeFailed: Color(0xFFA4133C),
    outcomePending: Color(0xFF6B5B60),
    streakEmber: Color(0xFF8B0F33),
  );

  static const AppPalette dark = AppPalette(
    crimson: Color(0xFFF26E8A),
    crimsonMuted: Color(0xFF3D1622),
    canvas: Color(0xFF0B0708),
    surface: Color(0xFF151011),
    surfaceRaised: Color(0xFF1F1819),
    hairline: Color(0xFF2C2325),
    inkPrimary: Color(0xFFF5F0F1),
    inkMuted: Color(0xFFA2949A),
    onCrimson: Color(0xFF0B0708),
    outcomeCompleted: Color(0xFF4ADE9B),
    outcomeFailed: Color(0xFFF26E8A),
    outcomePending: Color(0xFFA2949A),
    streakEmber: Color(0xFFFFA94D),
  );

  @override
  AppPalette copyWith({
    Color? crimson,
    Color? crimsonMuted,
    Color? canvas,
    Color? surface,
    Color? surfaceRaised,
    Color? hairline,
    Color? inkPrimary,
    Color? inkMuted,
    Color? onCrimson,
    Color? outcomeCompleted,
    Color? outcomeFailed,
    Color? outcomePending,
    Color? streakEmber,
  }) =>
      AppPalette(
        crimson: crimson ?? this.crimson,
        crimsonMuted: crimsonMuted ?? this.crimsonMuted,
        canvas: canvas ?? this.canvas,
        surface: surface ?? this.surface,
        surfaceRaised: surfaceRaised ?? this.surfaceRaised,
        hairline: hairline ?? this.hairline,
        inkPrimary: inkPrimary ?? this.inkPrimary,
        inkMuted: inkMuted ?? this.inkMuted,
        onCrimson: onCrimson ?? this.onCrimson,
        outcomeCompleted: outcomeCompleted ?? this.outcomeCompleted,
        outcomeFailed: outcomeFailed ?? this.outcomeFailed,
        outcomePending: outcomePending ?? this.outcomePending,
        streakEmber: streakEmber ?? this.streakEmber,
      );

  @override
  AppPalette lerp(covariant AppPalette? other, double t) {
    if (other == null) return this;
    return AppPalette(
      crimson: Color.lerp(crimson, other.crimson, t)!,
      crimsonMuted: Color.lerp(crimsonMuted, other.crimsonMuted, t)!,
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      inkPrimary: Color.lerp(inkPrimary, other.inkPrimary, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
      onCrimson: Color.lerp(onCrimson, other.onCrimson, t)!,
      outcomeCompleted: Color.lerp(outcomeCompleted, other.outcomeCompleted, t)!,
      outcomeFailed: Color.lerp(outcomeFailed, other.outcomeFailed, t)!,
      outcomePending: Color.lerp(outcomePending, other.outcomePending, t)!,
      streakEmber: Color.lerp(streakEmber, other.streakEmber, t)!,
    );
  }
}

extension PaletteResolver on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}
