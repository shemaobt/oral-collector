import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute, kIsWeb;

import 'crc32c.dart';

/// CRC32C (GCS base64 big-endian) of in-memory [bytes], computed off the UI
/// isolate. Native runs in a background isolate via [compute]; web (no isolates)
/// chunks the work with cooperative event-loop yields. See ADR-0004.
Future<String> crc32cBytesBase64(Uint8List bytes) {
  if (kIsWeb) return crc32cBytesBase64Chunked(bytes);
  return compute(_crc32cBytesBase64, bytes);
}

String _crc32cBytesBase64(Uint8List bytes) =>
    (Crc32c()..add(bytes)).base64BigEndian;

/// Cooperative chunked CRC32C — yields to the event loop every [chunkBytes] so
/// a multi-MB hash does not block the web UI thread. The result is identical to
/// a one-shot hash because [Crc32c] is a running register, independent of where
/// the chunk boundaries fall.
Future<String> crc32cBytesBase64Chunked(
  Uint8List bytes, {
  int chunkBytes = 256 * 1024,
}) async {
  final crc = Crc32c();
  for (var offset = 0; offset < bytes.length; offset += chunkBytes) {
    final end = offset + chunkBytes < bytes.length
        ? offset + chunkBytes
        : bytes.length;
    crc.add(Uint8List.sublistView(bytes, offset, end));
    await Future<void>.delayed(Duration.zero);
  }
  return crc.base64BigEndian;
}
