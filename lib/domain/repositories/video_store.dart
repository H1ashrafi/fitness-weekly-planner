abstract interface class VideoStore {
  Future<String> import(String sourcePath, String videoId);

  Future<void> discard(String storedUri);

  String resolvePath(String storedUri);
}
