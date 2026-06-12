import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/util/crc32c.dart';
import 'package:oral_collector/core/util/crc32c_async.dart';

void main() {
  String reference(Uint8List bytes) => (Crc32c()..add(bytes)).base64BigEndian;

  final cases = <String, Uint8List>{
    'empty': Uint8List(0),
    'abc': Uint8List.fromList(utf8.encode('abc')),
    'large 1MB': Uint8List.fromList(
      List.generate(1024 * 1024, (i) => (i * 31 + 7) & 0xFF),
    ),
  };

  group('crc32cBytesBase64 (off-isolate, native path)', () {
    cases.forEach((name, bytes) {
      test('matches the reference hash for $name', () async {
        expect(await crc32cBytesBase64(bytes), reference(bytes));
      });
    });

    test('"abc" equals the published GCS vector', () async {
      expect(
        await crc32cBytesBase64(Uint8List.fromList(utf8.encode('abc'))),
        'Nks/tw==',
      );
    });
  });

  group('crc32cBytesBase64Chunked (web/cooperative path)', () {
    cases.forEach((name, bytes) {
      test('matches the reference hash for $name', () async {
        expect(await crc32cBytesBase64Chunked(bytes), reference(bytes));
      });
    });

    test('"abc" equals the published GCS vector', () async {
      // Pin the web path to external ground truth, not just the in-repo
      // reference (which shares Crc32c's implementation).
      expect(
        await crc32cBytesBase64Chunked(Uint8List.fromList(utf8.encode('abc'))),
        'Nks/tw==',
      );
    });

    test('hash is independent of the chunk size', () async {
      // Tiny buffer with seams landing mid-data — catches chunk-stitching bugs.
      final abc = cases['abc']!;
      for (final chunk in [1, 2, 3, 4, 7]) {
        expect(
          await crc32cBytesBase64Chunked(abc, chunkBytes: chunk),
          reference(abc),
          reason: 'abc chunkBytes=$chunk',
        );
      }
      // Large buffer spanning many chunks at realistic sizes.
      final big = cases['large 1MB']!;
      for (final chunk in [4096, 100000, 256 * 1024, big.length + 10]) {
        expect(
          await crc32cBytesBase64Chunked(big, chunkBytes: chunk),
          reference(big),
          reason: 'big chunkBytes=$chunk',
        );
      }
    });
  });
}
