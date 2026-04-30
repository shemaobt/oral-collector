import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'file_source.dart';

FileSource fileSourceFromPath({
  required String path,
  required String name,
  required int length,
  String? mimeType,
}) => _NativeFileSource(
  path: path,
  name: name,
  length: length,
  mimeType: mimeType,
);

class _NativeFileSource implements FileSource {
  _NativeFileSource({
    required this.path,
    required this.name,
    required this.length,
    required this.mimeType,
  });

  final String path;

  @override
  String? get filePath => path;

  @override
  final String name;

  @override
  final int length;

  @override
  final String? mimeType;

  RandomAccessFile? _raf;

  Future<RandomAccessFile> _open() async {
    final existing = _raf;
    if (existing != null) return existing;
    final raf = await File(path).open();
    _raf = raf;
    return raf;
  }

  @override
  Future<Uint8List> readRange(int start, int end) async {
    if (end <= start) return Uint8List(0);
    final raf = await _open();
    await raf.setPosition(start);
    return raf.read(end - start);
  }

  @override
  Future<Uint8List> readHead(int maxBytes) {
    final end = maxBytes < length ? maxBytes : length;
    return readRange(0, end);
  }

  @override
  void dispose() {
    final raf = _raf;
    _raf = null;
    if (raf != null) {
      unawaited(raf.close());
    }
  }
}
