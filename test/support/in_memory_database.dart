import 'package:hanimob2/data/database/app_database.dart';
import 'package:hanimob2/data/database/schema.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

abstract final class InMemoryDatabase {
  static bool _initialised = false;

  static Future<Database> open() async {
    if (!_initialised) {
      sqfliteFfiInit();
      _initialised = true;
    }
    return databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: SchemaVersion.current,
        onConfigure: SchemaLifecycle.configure,
        onCreate: SchemaLifecycle.create,
        onUpgrade: SchemaLifecycle.upgrade,
      ),
    );
  }
}
