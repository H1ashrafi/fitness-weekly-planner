import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'application/providers.dart';
import 'data/database/app_database.dart';
import 'data/media/local_video_store.dart';
import 'presentation/hani_fitness_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final Database database = await const DeviceDatabaseOpener().open();
  final Directory documents = await getApplicationDocumentsDirectory();
  final LocalVideoStore videoStore = await LocalVideoStore.open(documents);

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(database),
        videoStoreProvider.overrideWithValue(videoStore),
      ],
      child: const HaniFitnessApp(),
    ),
  );
}
