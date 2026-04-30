import 'dart:async';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';

import 'file_source_native.dart'
    if (dart.library.js_interop) 'file_source_web.dart';

abstract class FileSource {
  String get name;
  int get length;
  String? get mimeType;

  /// Local filesystem path, when the source is file-backed on a native
  /// platform. Null on web and for in-memory sources.
  String? get filePath => null;

  Future<Uint8List> readRange(int start, int end);

  Future<Uint8List> readHead(int maxBytes) {
    final end = maxBytes < length ? maxBytes : length;
    return readRange(0, end);
  }

  void dispose();

  static FileSource fromPath(
    String path, {
    required String name,
    required int length,
    String? mimeType,
  }) => fileSourceFromPath(
    path: path,
    name: name,
    length: length,
    mimeType: mimeType,
  );

  static Future<FileSource> fromXFile(XFile file, {String? mimeType}) async {
    final resolvedLength = await file.length();
    return _XFileFileSource(
      file: file,
      length: resolvedLength,
      mimeType: mimeType ?? file.mimeType,
    );
  }

  static FileSource fromBytes(
    Uint8List bytes, {
    required String name,
    String? mimeType,
  }) => _InMemoryFileSource(bytes: bytes, name: name, mimeType: mimeType);
}

class _InMemoryFileSource implements FileSource {
  _InMemoryFileSource({
    required this.bytes,
    required this.name,
    required this.mimeType,
  });

  final Uint8List bytes;

  @override
  final String name;

  @override
  final String? mimeType;

  @override
  int get length => bytes.length;

  @override
  String? get filePath => null;

  @override
  Future<Uint8List> readRange(int start, int end) async {
    final clampedStart = start.clamp(0, bytes.length);
    final clampedEnd = end.clamp(clampedStart, bytes.length);
    return Uint8List.sublistView(bytes, clampedStart, clampedEnd);
  }

  @override
  Future<Uint8List> readHead(int maxBytes) {
    final end = maxBytes < length ? maxBytes : length;
    return readRange(0, end);
  }

  @override
  void dispose() {}
}

class _XFileFileSource implements FileSource {
  _XFileFileSource({
    required this.file,
    required this.length,
    required this.mimeType,
  });

  final XFile file;

  @override
  final int length;

  @override
  final String? mimeType;

  @override
  String? get filePath => null;

  @override
  String get name => file.name;

  @override
  Future<Uint8List> readRange(int start, int end) async {
    final builder = BytesBuilder(copy: false);
    await for (final chunk in file.openRead(start, end)) {
      builder.add(chunk);
    }
    return builder.toBytes();
  }

  @override
  Future<Uint8List> readHead(int maxBytes) {
    final end = maxBytes < length ? maxBytes : length;
    return readRange(0, end);
  }

  @override
  void dispose() {}
}
