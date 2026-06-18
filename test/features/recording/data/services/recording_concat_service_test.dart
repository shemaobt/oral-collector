import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/recording/data/services/recording_concat_service.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('concat_svc_test');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test(
    'back-to-back concats at the same instant use distinct scratch files',
    () async {
      final segA = File('${tempDir.path}/a.wav')..writeAsBytesSync([1, 2, 3]);
      final segB = File('${tempDir.path}/b.wav')..writeAsBytesSync([4, 5, 6]);

      final listPaths = <String>[];
      Future<bool> fakeFfmpeg(String command) async {
        final quoted = RegExp(
          r'"([^"]+)"',
        ).allMatches(command).map((m) => m.group(1)!).toList();
        listPaths.add(quoted[0]);
        // Produce a non-empty output so the service's existence/size checks pass.
        File(quoted[1]).writeAsBytesSync([0, 0, 0, 0]);
        return true;
      }

      // Pin the clock so a millisecond-only scratch name would be identical for
      // both calls: exactly the same-instant collision the fix must prevent.
      final fixedNow = DateTime(2024, 1, 1, 12);
      final service = RecordingConcatService(
        tempDirPath: () async => tempDir.path,
        now: () => fixedNow,
        ffmpegExec: fakeFfmpeg,
      );

      await service.concatSegments(
        segmentPaths: [segA.path, segB.path],
        outputPath: '${tempDir.path}/out1.wav',
      );
      await service.concatSegments(
        segmentPaths: [segA.path, segB.path],
        outputPath: '${tempDir.path}/out2.wav',
      );

      expect(listPaths, hasLength(2));
      expect(
        listPaths[0],
        isNot(listPaths[1]),
        reason: 'each concat must use its own scratch list file',
      );
    },
  );
}
