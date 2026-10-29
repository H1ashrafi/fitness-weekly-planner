import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hanimob2/application/providers.dart';
import 'package:hanimob2/core/design/app_palette.dart';
import 'package:hanimob2/core/design/app_theme.dart';
import 'package:hanimob2/core/design/fibonacci_scale.dart';
import 'package:hanimob2/core/time/clock.dart';
import 'package:hanimob2/domain/entities/anatomy_region.dart';
import 'package:hanimob2/domain/entities/exercise.dart';
import 'package:hanimob2/domain/entities/movement.dart';
import 'package:hanimob2/domain/entities/muscle_group.dart';
import 'package:hanimob2/domain/entities/set_execution.dart';
import 'package:hanimob2/domain/entities/set_outcome.dart';
import 'package:hanimob2/domain/entities/weekday.dart';
import 'package:hanimob2/presentation/anatomy/anatomy_body_map.dart';
import 'package:hanimob2/presentation/execute/execute_screen.dart';
import 'package:hanimob2/presentation/home_shell.dart';

import '../support/fake_repositories.dart';

Future<void> _loadFontFamily(String family, List<String> paths) async {
  final FontLoader loader = FontLoader(family);
  bool loadedAny = false;
  for (final String path in paths) {
    final File file = File(path);
    if (!file.existsSync()) continue;
    final Uint8List bytes = file.readAsBytesSync();
    loader.addFont(Future<ByteData>.value(ByteData.view(bytes.buffer)));
    loadedAny = true;
  }
  if (loadedAny) await loader.load();
}

Future<void> _loadFonts() async {
  await _loadFontFamily('Inter', <String>[
    r'C:\Windows\Fonts\segoeui.ttf',
    r'C:\Windows\Fonts\segoeuib.ttf',
    r'C:\Windows\Fonts\segoeuisl.ttf',
  ]);
  await _loadFontFamily('MaterialIcons', <String>[
    r'E:\flutter\bin\cache\artifacts\material_fonts\materialicons-regular.otf',
  ]);
}

final bool _fontsAvailable = File(r'C:\Windows\Fonts\segoeui.ttf').existsSync();

void main() {
  setUpAll(_loadFonts);

  final DateTime wednesday = DateTime(2026, 7, 15, 9);
  final Weekday today = Weekday.of(wednesday);

  const Movement benchMovement = Movement(
    id: 'mv-bench',
    name: 'Barbell Bench Press',
    muscleGroups: <MuscleGroup>[
      MuscleGroup(id: 'region:pectoralis', displayName: 'Chest', region: AnatomyRegion.pectoralis),
      MuscleGroup(id: 'region:triceps', displayName: 'Triceps', region: AnatomyRegion.triceps),
    ],
  );
  const Movement flyMovement =
      Movement(id: 'mv-fly', name: 'Incline Dumbbell Fly');

  const List<Exercise> plan = <Exercise>[
    Exercise(
      id: 'ex-bench',
      movement: benchMovement,
      weekday: Weekday.wednesday,
      orderIndex: 0,
      targetSets: 4,
      targetReps: 15,
      loadNote: '60 kg',
    ),
    Exercise(
      id: 'ex-fly',
      movement: flyMovement,
      weekday: Weekday.wednesday,
      orderIndex: 1,
      targetSets: 3,
      targetReps: 13,
    ),
  ];

  Future<Widget> wrap(Widget child, {required Brightness brightness}) async {
    final movements = InMemoryMovementRepository();
    final routines = InMemoryRoutineRepository(movements);
    final executions = InMemoryExecutionRepository();
    await movements.save(benchMovement);
    await movements.save(flyMovement);
    for (final Exercise exercise in plan) {
      await routines.saveEntry(exercise);
    }

    for (final (int index, SetOutcome outcome) in <SetOutcome>[
      SetOutcome.completed,
      SetOutcome.completed,
      SetOutcome.failed,
    ].indexed) {
      await executions.record(
        SetExecution(
          exerciseId: 'ex-bench',
          setIndex: index,
          weekStamp: FixedClock(wednesday).currentWeek,
          outcome: outcome,
          recordedAt: wednesday,
        ),
      );
    }

    return ProviderScope(
      overrides: [
        routineRepositoryProvider.overrideWithValue(routines),
        movementRepositoryProvider.overrideWithValue(movements),
        muscleGroupRepositoryProvider.overrideWithValue(InMemoryMuscleGroupRepository()),
        executionRepositoryProvider.overrideWithValue(executions),
        clockProvider.overrideWithValue(FixedClock(wednesday)),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
        home: child,
      ),
    );
  }

  Future<void> renderPhone(WidgetTester tester, Widget app) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app);
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 700));
  }

  testWidgets('golden: today execution — light', (tester) async {
    await renderPhone(tester, await wrap(const HomeShell(), brightness: Brightness.light));
    await expectLater(
      find.byType(HomeShell),
      matchesGoldenFile('images/today_light.png'),
    );
    expect(today, Weekday.wednesday);
  }, skip: !_fontsAvailable);

  testWidgets('golden: today execution — dark', (tester) async {
    await renderPhone(tester, await wrap(const ExecuteScreen(), brightness: Brightness.dark));
    await expectLater(
      find.byType(ExecuteScreen),
      matchesGoldenFile('images/today_dark.png'),
    );
  }, skip: !_fontsAvailable);

  testWidgets('golden: anatomy heatmap', (tester) async {
    tester.view.physicalSize = const Size(1100, 1400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (BuildContext context) => ColoredBox(
            color: context.palette.canvas,
            child: const Padding(
              padding: EdgeInsets.all(FibonacciSpace.comfortable),
              child: AnatomyBodyMap(
                facing: AnatomyFacing.anterior,
                intensities: <AnatomyRegion, double>{
                  AnatomyRegion.pectoralis: 1.0,
                  AnatomyRegion.anteriorDeltoid: 0.7,
                  AnatomyRegion.abdominals: 0.45,
                  AnatomyRegion.quadriceps: 0.2,
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await expectLater(
      find.byType(AnatomyBodyMap),
      matchesGoldenFile('images/anatomy_heatmap.png'),
    );
  }, skip: !_fontsAvailable);
}
