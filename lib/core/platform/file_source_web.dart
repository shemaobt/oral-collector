import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'file_source.dart';

FileSource fileSourceFromPath({
  required String path,
  required String name,
  required int length,
  String? mimeType,
}) => throw UnsupportedError(
  'FileSource.fromPath is not supported on web; use fileSourceFromWebFile instead',
);

FileSource fileSourceFromWebFile(web.File file) => _WebFileSource(file);

class _WebFileSource implements FileSource {
  _WebFileSource(this._file) : length = _file.size;

  final web.File _file;

  @override
  final int length;

  @override
  String? get filePath => null;

  @override
  String? get storageKey => null;

  @override
  String get name => _file.name;

  @override
  String? get mimeType {
    final type = _file.type;
    return type.isEmpty ? null : type;
  }

  @override
  Future<Uint8List> readRange(int start, int end) async {
    if (end <= start) return Uint8List(0);
    final blob = _file.slice(start, end);
    final buffer = await blob.arrayBuffer().toDart;
    return buffer.toDart.asUint8List();
  }

  @override
  Future<Uint8List> readHead(int maxBytes) {
    final end = maxBytes < length ? maxBytes : length;
    return readRange(0, end);
  }

  @override
  void dispose() {}
}
