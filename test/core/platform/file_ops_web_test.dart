import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:oral_collector/core/platform/file_ops.dart' as file_ops;

void main() {
  group('file_ops (native)', () {
    test('fileExists returns false for nonexistent file', () async {
      final exists = await file_ops.fileExists('/nonexistent/path.txt');
      expect(exists, isFalse);
    });

    test('writeFileBytes and readFileBytes round-trip', () async {
      final testDir = Directory.systemTemp.createTempSync('file_ops_test');
      final path = '${testDir.path}/test_file.bin';
      final data = Uint8List.fromList([1, 2, 3, 4, 5]);

      await file_ops.writeFileBytes(path, data);

      final exists = await file_ops.fileExists(path);
      expect(exists, isTrue);

      final length = await file_ops.fileLength(path);
      expect(length, 5);

      final read = await file_ops.readFileBytes(path);
      expect(read, equals(data));

      await file_ops.deleteFile(path);
      final existsAfter = await file_ops.fileExists(path);
      expect(existsAfter, isFalse);

      testDir.deleteSync(recursive: true);
    });

    test('copyFile creates a copy', () async {
      final testDir = Directory.systemTemp.createTempSync('file_ops_copy');
      final src = '${testDir.path}/source.bin';
      final dst = '${testDir.path}/dest.bin';
      final data = Uint8List.fromList([10, 20, 30]);

      await file_ops.writeFileBytes(src, data);
      await file_ops.copyFile(src, dst);

      final dstExists = await file_ops.fileExists(dst);
      expect(dstExists, isTrue);

      final dstData = await file_ops.readFileBytes(dst);
      expect(dstData, equals(data));

      testDir.deleteSync(recursive: true);
    });

    test('createDir and dirExists', () async {
      final testDir = Directory.systemTemp.createTempSync('file_ops_dir');
      final subdir = '${testDir.path}/nested/deep';

      await file_ops.createDir(subdir);
      final exists = await file_ops.dirExists(subdir);
      expect(exists, isTrue);

      testDir.deleteSync(recursive: true);
    });

    test('deleteFile on nonexistent file does not throw', () async {
      await file_ops.deleteFile('/nonexistent/should_not_throw.bin');
    });
  });
}
