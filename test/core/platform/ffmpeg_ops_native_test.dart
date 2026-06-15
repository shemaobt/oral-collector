import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/platform/ffmpeg_ops_native.dart';

void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('ffmpeg_ops_native_test_');
  });

  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  group('compressToM4a output verification (ENG-140 F18)', () {
    test(
      'returns false when ffmpeg reports success but no output exists',
      () async {
        final out = '${tmp.path}/out.m4a';
        // ffmpeg returned 0 but never produced the file — the source must NOT be
        // deemed safe to delete.
        final ok = await compressToM4a(
          '${tmp.path}/in.wav',
          out,
          runner: (_) async => true,
        );

        expect(ok, isFalse);
        expect(File(out).existsSync(), isFalse);
      },
    );

    test(
      'returns false when ffmpeg reports success but the output is empty',
      () async {
        final out = '${tmp.path}/out.m4a';
        final ok = await compressToM4a(
          '${tmp.path}/in.wav',
          out,
          runner: (_) async {
            await File(out).writeAsBytes(<int>[]);
            return true;
          },
        );

        expect(ok, isFalse);
      },
    );

    test(
      'returns true when ffmpeg succeeds and the output is non-empty',
      () async {
        final out = '${tmp.path}/out.m4a';
        final ok = await compressToM4a(
          '${tmp.path}/in.wav',
          out,
          runner: (_) async {
            await File(out).writeAsBytes(List<int>.filled(2048, 0));
            return true;
          },
        );

        expect(ok, isTrue);
      },
    );

    test('returns false when ffmpeg itself fails', () async {
      final ok = await compressToM4a(
        '${tmp.path}/in.wav',
        '${tmp.path}/out.m4a',
        runner: (_) async => false,
      );

      expect(ok, isFalse);
    });
  });
}
