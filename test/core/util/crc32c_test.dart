import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/util/crc32c.dart';

void main() {
  group('Crc32c', () {
    test('empty input produces 0', () {
      final crc = Crc32c();
      expect(crc.value, 0x00000000);
    });

    test('"a" matches known vector', () {
      final crc = Crc32c()..add(utf8.encode('a'));
      expect(crc.value, 0xC1D04330);
    });

    test('"abc" matches known vector', () {
      final crc = Crc32c()..add(utf8.encode('abc'));
      expect(crc.value, 0x364B3FB7);
    });

    test('"123456789" matches known vector', () {
      final crc = Crc32c()..add(utf8.encode('123456789'));
      expect(crc.value, 0xE3069283);
    });

    // RFC 3720 Appendix B.4 — iSCSI CRC32C reference vectors.
    test('32 zero bytes (RFC 3720)', () {
      final crc = Crc32c()..add(Uint8List(32));
      expect(crc.value, 0x8A9136AA);
    });

    test('32 0xFF bytes (RFC 3720)', () {
      final crc = Crc32c()..add(Uint8List.fromList(List.filled(32, 0xFF)));
      expect(crc.value, 0x62A8AB43);
    });

    test('32 incrementing bytes 0x00..0x1F (RFC 3720)', () {
      final crc = Crc32c()
        ..add(Uint8List.fromList(List.generate(32, (i) => i)));
      expect(crc.value, 0x46DD794E);
    });

    test('32 decrementing bytes 0x1F..0x00 (RFC 3720)', () {
      final crc = Crc32c()
        ..add(Uint8List.fromList(List.generate(32, (i) => 31 - i)));
      expect(crc.value, 0x113FDB5C);
    });

    test('incremental add matches single add', () {
      final whole = Crc32c()..add(utf8.encode('abcdefghij'));
      final split = Crc32c()
        ..add(utf8.encode('abc'))
        ..add(utf8.encode('def'))
        ..add(utf8.encode('ghij'));
      expect(split.value, whole.value);
    });

    test('base64BigEndian encodes value as 4-byte big-endian', () {
      final crc = Crc32c()..add(utf8.encode('abc'));
      // 0x364B3FB7 big-endian = bytes [0x36, 0x4B, 0x3F, 0xB7] → "Nks/tw=="
      expect(crc.base64BigEndian, 'Nks/tw==');
    });
  });

  group('parseGcsCrc32cHeader', () {
    test('returns null when header is absent', () {
      expect(parseGcsCrc32cHeader(<String, String>{}), isNull);
    });

    test('extracts crc32c value from combined header', () {
      final headers = {'x-goog-hash': 'crc32c=Nks/tw==,md5=kAFQmDzST7DWlj99KOF/cg=='};
      expect(parseGcsCrc32cHeader(headers), 'Nks/tw==');
    });

    test('extracts crc32c value when md5 comes first', () {
      final headers = {
        'x-goog-hash': 'md5=kAFQmDzST7DWlj99KOF/cg==, crc32c=Nks/tw==',
      };
      expect(parseGcsCrc32cHeader(headers), 'Nks/tw==');
    });

    test('returns null when only md5 is present', () {
      final headers = {'x-goog-hash': 'md5=kAFQmDzST7DWlj99KOF/cg=='};
      expect(parseGcsCrc32cHeader(headers), isNull);
    });

    test('handles capitalized header name', () {
      final headers = {'X-Goog-Hash': 'crc32c=Nks/tw=='};
      expect(parseGcsCrc32cHeader(headers), 'Nks/tw==');
    });
  });
}
