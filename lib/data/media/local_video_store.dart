import 'dart:io';

import 'package:path/path.dart' as p;

import '../../domain/repositories/video_store.dart';

final class LocalVideoStore implements VideoStore {
  const LocalVideoStore(this._root);

  final Directory _root;

  static Future<LocalVideoStore> open(Directory documentsDirectory) async {
    final Directory root =
        Directory(p.join(documentsDirectory.path, 'exercise_videos'));
    await root.create(recursive: true);
    return LocalVideoStore(root);
  }

  @override
  Future<String> import(String sourcePath, String videoId) async {
    final String storedName = '$videoId${p.extension(sourcePath)}';
    await File(sourcePath).copy(p.join(_root.path, storedName));
    return storedName;
  }

  @override
  Future<void> discard(String storedUri) async {
    final File file = File(resolvePath(storedUri));
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  String resolvePath(String storedUri) =>
      p.isAbsolute(storedUri) ? storedUri : p.join(_root.path, storedUri);
}
