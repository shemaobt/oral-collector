import 'dart:io';
import 'dart:typed_data';

Future<bool> fileExists(String path) => File(path).exists();

Future<int> fileLength(String path) => File(path).length();

Future<Uint8List> readFileBytes(String path) => File(path).readAsBytes();

Future<void> writeFileBytes(String path, Uint8List bytes) =>
    File(path).writeAsBytes(bytes);

Future<void> deleteFile(String path) async {
  final f = File(path);
  if (await f.exists()) await f.delete();
}

Future<void> copyFile(String from, String to) =>
    File(from).copy(to).then((_) {});

Future<void> createDir(String path) => Directory(path).create(recursive: true);

Future<bool> dirExists(String path) => Directory(path).exists();

bool get isAndroidPlatform => Platform.isAndroid;

bool get isIOSPlatform => Platform.isIOS;
