import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/recording/data/services/joined_audio_exporter.dart';

import '../../../../support/system_ffmpeg.dart';

void main() {
  late Directory dir;
  late String source;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('joined_audio_exporter_');
    source = '${dir.path}/source.m4a';
    await writeToneM4a(source, seconds: 60);
  });

  tearDown(() => dir.deleteSync(recursive: true));

  Future<EditedAudio> join({
    required double gainDb,
    required List<String> commands,
  }) => exportJoinedKeptRanges(
    JoinKeptRangesRequest(
      sourceFilePath: source,
      keptRanges: const [
        KeptRange(startSeconds: 0, endSeconds: 20),
        KeptRange(startSeconds: 30, endSeconds: 60),
      ],
      gainDb: gainDb,
    ),
    runner: (command) {
      commands.add(command);
      return runSystemFFmpeg(command);
    },
    documentsDirectoryPath: () async => dir.path,
  );

  test('a join applies the gain in the same single re-encode', () async {
    final plainCommands = <String>[];
    final boostedCommands = <String>[];

    final plain = await join(gainDb: 0, commands: plainCommands);
    final boosted = await join(gainDb: 6, commands: boostedCommands);

    expect(boostedCommands, hasLength(1));
    expect(boostedCommands.single, isNot(contains('-c copy')));
    expect(
      await measuredMeanVolumeDb(boosted.localFilePath),
      closeTo(await measuredMeanVolumeDb(plain.localFilePath) + 6, 0.5),
    );
  });

  test('the joined file lasts the sum of the kept ranges and reports its '
      'size', () async {
    final joined = await join(gainDb: 0, commands: []);

    expect(
      await measuredDurationSeconds(joined.localFilePath),
      closeTo(50, 0.1),
    );
    expect(joined.durationSeconds, closeTo(50, 0.1));
    expect(joined.fileSizeBytes, File(joined.localFilePath).lengthSync());
  });

  test('a failed ffmpeg run fails the join even when it left a file '
      'behind', () async {
    await expectLater(
      exportJoinedKeptRanges(
        JoinKeptRangesRequest(
          sourceFilePath: source,
          keptRanges: const [KeptRange(startSeconds: 0, endSeconds: 20)],
          gainDb: 0,
        ),
        runner: (command) async {
          await runSystemFFmpeg(command);
          return false;
        },
        documentsDirectoryPath: () async => dir.path,
      ),
      throwsA(isA<Exception>()),
    );
  });

  Future<EditedAudio> joinShortSource(List<KeptRange> keptRanges) async {
    final shortSource = '${dir.path}/short.m4a';
    await writeToneM4a(shortSource, seconds: 10);
    return exportJoinedKeptRanges(
      JoinKeptRangesRequest(
        sourceFilePath: shortSource,
        keptRanges: keptRanges,
        gainDb: 0,
      ),
      runner: runSystemFFmpeg,
      documentsDirectoryPath: () async => dir.path,
    );
  }

  test('a kept range wholly past the end of the file fails the join instead '
      'of returning a file with no audio', () async {
    await expectLater(
      joinShortSource(const [KeptRange(startSeconds: 12, endSeconds: 15)]),
      throwsA(isA<Exception>()),
    );
  });

  test('a kept range partly past the end of the file fails the join instead '
      'of claiming audio the file does not have', () async {
    await expectLater(
      joinShortSource(const [
        KeptRange(startSeconds: 0, endSeconds: 5),
        KeptRange(startSeconds: 8, endSeconds: 15),
      ]),
      throwsA(isA<Exception>()),
    );
  });
}
