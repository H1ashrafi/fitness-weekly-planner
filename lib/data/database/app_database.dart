import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../domain/entities/anatomy_region.dart';
import 'schema.dart';

abstract interface class DatabaseOpener {
  Future<Database> open();
}

abstract final class AnatomyCatalogSeed {
  static String idFor(AnatomyRegion region) => 'region:${region.name}';

  static Iterable<Map<String, Object?>> get rows =>
      AnatomyRegion.values.map((AnatomyRegion region) => <String, Object?>{
            'id': idFor(region),
            'display_name': region.label,
            'region': region.name,
          });
}

abstract final class SchemaLifecycle {
  static Future<void> configure(Database db) async =>
      db.execute('PRAGMA foreign_keys = ON');

  static Future<void> create(Database db, int version) async {
    final Batch batch = db.batch();
    for (final String statement in CreateStatements.all) {
      batch.execute(statement);
    }
    for (final Map<String, Object?> row in AnatomyCatalogSeed.rows) {
      batch.insert(Tables.muscleGroups, row);
    }
    await batch.commit(noResult: true);
  }

  static Future<void> upgrade(Database db, int from, int to) async {
    for (int version = from + 1; version <= to; version++) {
      final List<String>? statements =
          MigrationStatements.byTargetVersion[version];
      if (statements == null) {
        throw UnsupportedError('No migration path registered to v$version');
      }
      for (final String statement in statements) {
        await db.execute(statement);
      }
    }
  }
}

final class DeviceDatabaseOpener implements DatabaseOpener {
  const DeviceDatabaseOpener({this.fileName = 'hani_fitness.db'});

  final String fileName;

  static bool get _isDesktop =>
      Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  DatabaseFactory get _factory {
    if (!_isDesktop) return databaseFactory;
    sqfliteFfiInit();
    return databaseFactoryFfi;
  }

  @override
  Future<Database> open() async {
    final DatabaseFactory factory = _factory;
    final String directory = await factory.getDatabasesPath();
    return factory.openDatabase(
      p.join(directory, fileName),
      options: OpenDatabaseOptions(
        version: SchemaVersion.current,
        onConfigure: SchemaLifecycle.configure,
        onCreate: SchemaLifecycle.create,
        onUpgrade: SchemaLifecycle.upgrade,
      ),
    );
  }
}
