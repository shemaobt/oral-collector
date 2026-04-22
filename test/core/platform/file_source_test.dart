import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/platform/file_source.dart';

void main() {
  group('FileSource.fromBytes', () {
    test('exposes name, length, mimeType', () {
      final source = FileSource.fromBytes(
        Uint8List.fromList(List.generate(100, (i) => i)),
        name: 'sample.bin',
        mimeType: 'application/octet-stream',
      );

      expect(source.name, 'sample.bin');
      expect(source.length, 100);
      expect(source.mimeType, 'application/octet-stream');
      expect(source.filePath, isNull);
    });

    test('readRange returns the requested slice', () async {
      final source = FileSource.fromBytes(
        Uint8List.fromList(List.generate(20, (i) => i)),
        name: 'x.bin',
      );
      final range = await source.readRange(5, 10);
      expect(range, Uint8List.fromList([5, 6, 7, 8, 9]));
    });

    test('readRange clamps end past length', () async {
      final source = FileSource.fromBytes(
        Uint8List.fromList([1, 2, 3, 4]),
        name: 'x.bin',
      );
      final range = await source.readRange(2, 99);
      expect(range, Uint8List.fromList([3, 4]));
    });

    test('readHead returns prefix', () async {
      final source = FileSource.fromBytes(
        Uint8List.fromList(List.generate(100, (i) => i)),
        name: 'x.bin',
      );
      final head = await source.readHead(16);
      expect(head.length, 16);
      expect(head.first, 0);
      expect(head.last, 15);
    });

    test('readHead of small file returns the whole file', () async {
      final source = FileSource.fromBytes(
        Uint8List.fromList([1, 2, 3]),
        name: 'x.bin',
      );
      final head = await source.readHead(64);
      expect(head, Uint8List.fromList([1, 2, 3]));
    });

    test('dispose is a no-op (can be called multiple times)', () {
      final source = FileSource.fromBytes(Uint8List(10), name: 'x.bin');
      source.dispose();
      source.dispose();
    });
  });

  group('FileSource.fromPath (native)', () {
    test('reads arbitrary byte ranges from a real file', () async {
      final tmp = await File(
        '${Directory.systemTemp.path}/file_source_test_${DateTime.now().microsecondsSinceEpoch}.bin',
      ).create();
      try {
        final bytes = Uint8List.fromList(List.generate(256, (i) => i));
        await tmp.writeAsBytes(bytes);

        final source = FileSource.fromPath(
          tmp.path,
          name: 'test.bin',
          length: bytes.length,
        );

        expect(source.filePath, tmp.path);

        final mid = await source.readRange(100, 110);
        expect(mid, Uint8List.fromList(List.generate(10, (i) => 100 + i)));

        final head = await source.readHead(8);
        expect(head, Uint8List.fromList([0, 1, 2, 3, 4, 5, 6, 7]));

        final end = await source.readRange(250, 256);
        expect(end, Uint8List.fromList([250, 251, 252, 253, 254, 255]));

        source.dispose();
      } finally {
        if (await tmp.exists()) await tmp.delete();
      }
    });
  });
}
