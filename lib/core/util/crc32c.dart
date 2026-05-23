import 'dart:convert';
import 'dart:typed_data';

/// Incremental CRC32C (Castagnoli) computation.
///
/// Used to validate GCS uploads end-to-end against the `x-goog-hash` header
/// returned in the final response. GCS reports CRC32C as base64 big-endian,
/// matching [base64BigEndian].
class Crc32c {
  static final Uint32List _table = _buildTable();

  int _crc = 0xFFFFFFFF;

  void add(List<int> chunk) {
    var crc = _crc;
    for (var i = 0; i < chunk.length; i++) {
      crc = (crc >> 8) ^ _table[(crc ^ chunk[i]) & 0xFF];
    }
    _crc = crc;
  }

  int get value => (_crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;

  String get base64BigEndian {
    final bytes = ByteData(4)..setUint32(0, value, Endian.big);
    return base64.encode(bytes.buffer.asUint8List());
  }

  static Uint32List _buildTable() {
    // Castagnoli polynomial 0x1EDC6F41, reflected = 0x82F63B78.
    const poly = 0x82F63B78;
    final table = Uint32List(256);
    for (var i = 0; i < 256; i++) {
      var crc = i;
      for (var j = 0; j < 8; j++) {
        crc = (crc & 1) == 1 ? (crc >> 1) ^ poly : crc >> 1;
      }
      table[i] = crc;
    }
    return table;
  }
}

/// Returns the raw base64 of the `crc32c=` value from a GCS `x-goog-hash`
/// header (format `"crc32c=AAAA==,md5=BBBB=="`), or `null` if absent.
String? parseGcsCrc32cHeader(Map<String, String> headers) {
  final raw = headers['x-goog-hash'] ?? headers['X-Goog-Hash'];
  if (raw == null) return null;
  for (final part in raw.split(',')) {
    final trimmed = part.trim();
    if (trimmed.startsWith('crc32c=')) {
      return trimmed.substring('crc32c='.length);
    }
  }
  return null;
}
