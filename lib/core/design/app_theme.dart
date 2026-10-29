import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'app_palette.dart';
import 'app_typography.dart';
import 'fibonacci_scale.dart';

abstract final class AppTheme {
  static ThemeData light() => _compose(AppPalette.light, Brightness.light);

  static ThemeData dark() => _compose(AppPalette.dark, Brightness.dark);

  static ThemeData _compose(AppPalette palette, Brightness brightness) {
    final TextTheme textTheme =
        AppTypography.resolveFor(palette.inkPrimary, palette.inkMuted);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: palette.canvas,
      canvasColor: palette.canvas,
      splashFactory: InkSparkle.splashFactory,
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[palette],
      colorScheme: ColorScheme.fromSeed(
        seedColor: palette.crimson,
        brightness: brightness,
      ).copyWith(
        primary: palette.crimson,
        onPrimary: palette.onCrimson,
        surface: palette.surface,
        onSurface: palette.inkPrimary,
        error: palette.outcomeFailed,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.headlineMedium,
        iconTheme: IconThemeData(
          color: palette.inkPrimary,
          size: FibonacciSize.iconRegular,
        ),
      ),
      cardTheme: CardThemeData(
        color: palette.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: FibonacciRadius.card,
          side: BorderSide(
            color: palette.hairline,
            width: FibonacciSize.strokeHairline,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: palette.hairline,
        thickness: FibonacciSize.strokeHairline,
        space: FibonacciSpace.compact,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.crimson,
          foregroundColor: palette.onCrimson,
          textStyle: textTheme.labelLarge,
          minimumSize: const Size.fromHeight(FibonacciSpace.roomy + FibonacciSpace.compact),
          shape: const RoundedRectangleBorder(borderRadius: FibonacciRadius.control),
          padding: const EdgeInsets.symmetric(
            horizontal: FibonacciSpace.comfortable,
            vertical: FibonacciSpace.regular,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.crimson,
          textStyle: textTheme.labelLarge,
          shape: const RoundedRectangleBorder(borderRadius: FibonacciRadius.control),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: FibonacciSpace.regular,
          vertical: FibonacciSpace.regular,
        ),
        hintStyle: textTheme.bodyMedium,
        border: OutlineInputBorder(
          borderRadius: FibonacciRadius.control,
          borderSide: BorderSide(color: palette.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: FibonacciRadius.control,
          borderSide: BorderSide(color: palette.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: FibonacciRadius.control,
          borderSide: BorderSide(
            color: palette.crimson,
            width: FibonacciSize.strokeRegular,
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: FibonacciRadius.sheet),
        showDragHandle: true,
        dragHandleColor: palette.hairline,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: palette.surface,
        selectedColor: palette.crimsonMuted,
        side: BorderSide(color: palette.hairline),
        labelStyle: textTheme.labelLarge!,
        shape: const RoundedRectangleBorder(borderRadius: FibonacciRadius.chip),
        padding: const EdgeInsets.symmetric(
          horizontal: FibonacciSpace.compact,
          vertical: FibonacciSpace.snug,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
