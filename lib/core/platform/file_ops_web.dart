import 'dart:typed_data';

Future<bool> fileExists(String path) async => false;

Future<int> fileLength(String path) async => 0;

Future<Uint8List> readFileBytes(String path) async => Uint8List(0);

Future<void> writeFileBytes(String path, Uint8List bytes) async {}

Future<void> deleteFile(String path) async {}

Future<void> copyFile(String from, String to) async {}

Future<void> createDir(String path) async {}

Future<bool> dirExists(String path) async => false;

bool get isAndroidPlatform => false;

bool get isIOSPlatform => false;
