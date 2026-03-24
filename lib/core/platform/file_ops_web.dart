import 'dart:typed_data';

final Map<String, Uint8List> _webFileCache = {};

void cacheWebFile(String path, Uint8List bytes) {
  _webFileCache[path] = bytes;
}

void removeCachedWebFile(String path) {
  _webFileCache.remove(path);
}

Future<bool> fileExists(String path) async => _webFileCache.containsKey(path);

Future<int> fileLength(String path) async => _webFileCache[path]?.length ?? 0;

Future<Uint8List> readFileBytes(String path) async =>
    _webFileCache[path] ?? Uint8List(0);

Future<void> writeFileBytes(String path, Uint8List bytes) async {
  _webFileCache[path] = bytes;
}

Future<void> deleteFile(String path) async {
  _webFileCache.remove(path);
}

Future<void> copyFile(String from, String to) async {
  final bytes = _webFileCache[from];
  if (bytes != null) {
    _webFileCache[to] = Uint8List.fromList(bytes);
  }
}

Future<void> createDir(String path) async {}

Future<bool> dirExists(String path) async => true;

Future<Uint8List> readFileChunk(String path, int offset, int length) async {
  final bytes = await readFileBytes(path);
  return bytes.sublist(offset, offset + length);
}

bool get isAndroidPlatform => false;

bool get isIOSPlatform => false;
