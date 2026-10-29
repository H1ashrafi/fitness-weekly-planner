import 'package:flutter/material.dart';

import '../core/design/app_theme.dart';
import 'home_shell.dart';

final class HaniFitnessApp extends StatelessWidget {
  const HaniFitnessApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Hani Fitness',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        themeAnimationDuration: const Duration(milliseconds: 377),
        themeAnimationCurve: Curves.easeInOutCubic,
        home: const HomeShell(),
      );
}
