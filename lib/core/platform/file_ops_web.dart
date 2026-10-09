import 'dart:typed_data';

import 'package:idb_shim/idb_client_native.dart' show idbFactoryNative;

import 'web_file_store.dart';

/// Built on first use, because `idbFactoryNative` throws where IndexedDB is
/// unavailable (private mode, storage blocked by policy) and that has to
/// surface at the call that needs storage, not at import time. Nothing falls
/// back to an in-memory map: audio that looks saved and is gone after a reload
/// is the defect ENG-421 fixes, and a silent fallback would recreate it.
WebFileStore? _files;

WebFileStore get _store => _files ??= WebFileStore(idbFactoryNative);

Future<bool> fileExists(String path) async => _store.exists(path);

Future<int> fileLength(String path) async => _store.length(path);

Future<Uint8List> readFileBytes(String path) async => _store.read(path);

Future<void> writeFileBytes(String path, Uint8List bytes) async =>
    _store.write(path, bytes);

Future<void> deleteFile(String path) async => _store.delete(path);

/// Web-only, and the native variant throws rather than answering: enumerating
/// the whole store is a question only the browser build can answer, because
/// only there is every file in one flat keyspace. Native audio is spread over
/// directories a caller lists individually, so an empty list would be a false
/// answer, not a degenerate one — `web_file_picker_native.dart` refuses a
/// web-only capability the same way. The startup sweep for recordings
/// abandoned before upload (ENG-426) is the one caller.
Future<List<String>> listStoredKeys() async => _store.listKeys();

Future<void> copyFile(String from, String to) async => _store.copy(from, to);

Future<void> createDir(String path) async {}

Future<bool> dirExists(String path) async => true;

Future<Uint8List> readFileChunk(String path, int offset, int length) async =>
    _store.readChunk(path, offset, length);

bool get isAndroidPlatform => false;

bool get isIOSPlatform => false;
