import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:oral_collector/features/recording/data/services/recording_concat_service.dart';
import 'package:oral_collector/features/recording/data/services/recording_finalization_service.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recording_session_state.dart';

const _sampleRate = 16000;
const _numChannels = 1;
const _bitsPerSample = 16;

Uint8List _buildWavFile(List<int> samples) {
  final byteRate = _sampleRate * _numChannels * _bitsPerSample ~/ 8;
  final blockAlign = _numChannels * _bitsPerSample ~/ 8;
  final dataSize = samples.length * 2;
  final fileSize = 36 + dataSize;

  final builder = BytesBuilder();
  builder.add('RIFF'.codeUnits);
  builder.add(_uint32LE(fileSize));
  builder.add('WAVE'.codeUnits);
  builder.add('fmt '.codeUnits);
  builder.add(_uint32LE(16));
  builder.add(_uint16LE(1));
  builder.add(_uint16LE(_numChannels));
  builder.add(_uint32LE(_sampleRate));
  builder.add(_uint32LE(byteRate));
  builder.add(_uint16LE(blockAlign));
  builder.add(_uint16LE(_bitsPerSample));
  builder.add('data'.codeUnits);
  builder.add(_uint32LE(dataSize));
  for (final s in samples) {
    builder.add(_int16LE(s));
  }
  return builder.toBytes();
}

List<int> _uint32LE(int v) => [
  v & 0xff,
  (v >> 8) & 0xff,
  (v >> 16) & 0xff,
  (v >> 24) & 0xff,
];
List<int> _uint16LE(int v) => [v & 0xff, (v >> 8) & 0xff];
List<int> _int16LE(int v) => [v & 0xff, (v >> 8) & 0xff];

class _StubConcatService implements RecordingConcatService {
  _StubConcatService({this.result, this.error});

  final String? Function()? result;
  final Object? error;
  int callCount = 0;

  @override
  Future<String?> concatSegments({
    required List<String> segmentPaths,
    required String outputPath,
  }) async {
    callCount++;
    if (error != null) throw error!;
    final path = result?.call();
    if (path != null) {
      // Simulate ffmpeg writing the output file so downstream reads succeed.
      await File(path).writeAsBytes(Uint8List(8));
    }
    return path;
  }
}

void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('finalization_test_');
  });

  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  Future<Directory> tmpDocsDir() async => tmp;

  Future<bool> okCompress(String src, String dst) async {
    await File(dst).writeAsBytes(Uint8List(16));
    return true;
  }

  Future<bool> failingCompress(String src, String dst) async => false;

  group('finalize - empty segments', () {
    test('returns null on empty segmentPaths and emits no stages', () async {
      final service = RecordingFinalizationService(
        concat: _StubConcatService(),
        documentsDirFn: tmpDocsDir,
        compressFn: okCompress,
      );
      final stages = <FinalizationStage>[];

      final outcome = await service.finalize(
        sessionId: 's',
        segmentPaths: const [],
        totalDuration: const Duration(seconds: 1),
        onStage: stages.add,
      );

      expect(outcome, isNull);
      expect(stages, isEmpty);
    });
  });

  group('finalize - single segment paths', () {
    test('single m4a segment skips combining and compressing stages', () async {
      final m4a = '${tmp.path}/seg.m4a';
      await File(m4a).writeAsBytes(Uint8List(8));

      final service = RecordingFinalizationService(
        concat: _StubConcatService(),
        documentsDirFn: tmpDocsDir,
        compressFn: okCompress,
      );
      final stages = <FinalizationStage>[];

      final outcome = await service.finalize(
        sessionId: 'sess',
        segmentPaths: [m4a],
        totalDuration: const Duration(seconds: 5),
        onStage: stages.add,
      );

      expect(stages, [FinalizationStage.finalizing]);
      expect(outcome, isNotNull);
      expect(outcome!.result.filePath, m4a);
      expect(outcome.result.format, 'm4a');
      expect(outcome.degraded, isFalse);
    });

    test(
      'single wav segment emits finalizing then compressing and produces m4a',
      () async {
        final wav = '${tmp.path}/seg.wav';
        await File(wav).writeAsBytes(_buildWavFile([1, 2, 3]));

        final service = RecordingFinalizationService(
          concat: _StubConcatService(),
          documentsDirFn: tmpDocsDir,
          compressFn: okCompress,
        );
        final stages = <FinalizationStage>[];

        final outcome = await service.finalize(
          sessionId: 'sess',
          segmentPaths: [wav],
          totalDuration: const Duration(seconds: 5),
          onStage: stages.add,
        );

        expect(stages, [
          FinalizationStage.finalizing,
          FinalizationStage.compressingAudio,
        ]);
        expect(outcome, isNotNull);
        expect(outcome!.result.filePath, endsWith('recording_sess.m4a'));
        expect(outcome.result.format, 'm4a');
        expect(outcome.degraded, isFalse);
      },
    );
  });

  group('finalize - multi-segment WAV (happy path)', () {
    test(
      'emits finalizing → combiningSegments → compressingAudio for multi-wav '
      'when ffmpeg concat succeeds and compress succeeds',
      () async {
        final w1 = '${tmp.path}/s1.wav';
        final w2 = '${tmp.path}/s2.wav';
        await File(w1).writeAsBytes(_buildWavFile([1, 2]));
        await File(w2).writeAsBytes(_buildWavFile([3, 4]));

        final concatOut = '${tmp.path}/concat_sess.wav';
        final service = RecordingFinalizationService(
          concat: _StubConcatService(result: () => concatOut),
          documentsDirFn: tmpDocsDir,
          compressFn: okCompress,
        );
        final stages = <FinalizationStage>[];

        final outcome = await service.finalize(
          sessionId: 'sess',
          segmentPaths: [w1, w2],
          totalDuration: const Duration(seconds: 5),
          onStage: stages.add,
        );

        expect(stages, [
          FinalizationStage.finalizing,
          FinalizationStage.combiningSegments,
          FinalizationStage.compressingAudio,
        ]);
        expect(outcome, isNotNull);
        expect(outcome!.result.filePath, endsWith('recording_sess.m4a'));
        expect(outcome.degraded, isFalse);
      },
    );
  });

  group('finalize - concat fallbacks', () {
    test(
      'pure-Dart WAV fallback runs when ffmpeg concat returns null and marks '
      'outcome as degraded',
      () async {
        final w1 = '${tmp.path}/s1.wav';
        final w2 = '${tmp.path}/s2.wav';
        await File(w1).writeAsBytes(_buildWavFile([1, 2]));
        await File(w2).writeAsBytes(_buildWavFile([3, 4]));

        final service = RecordingFinalizationService(
          concat: _StubConcatService(result: () => null),
          documentsDirFn: tmpDocsDir,
          compressFn: okCompress,
        );

        final outcome = await service.finalize(
          sessionId: 'sess',
          segmentPaths: [w1, w2],
          totalDuration: const Duration(seconds: 5),
        );

        expect(outcome, isNotNull);
        expect(outcome!.degraded, isTrue);
        expect(outcome.result.filePath, endsWith('recording_sess.m4a'));
      },
    );

    test(
      'ffmpeg concat throwing is treated as a concat failure (graceful)',
      () async {
        final w1 = '${tmp.path}/s1.wav';
        final w2 = '${tmp.path}/s2.wav';
        await File(w1).writeAsBytes(_buildWavFile([1, 2]));
        await File(w2).writeAsBytes(_buildWavFile([3, 4]));

        final service = RecordingFinalizationService(
          concat: _StubConcatService(error: Exception('boom')),
          documentsDirFn: tmpDocsDir,
          compressFn: okCompress,
        );

        final outcome = await service.finalize(
          sessionId: 'sess',
          segmentPaths: [w1, w2],
          totalDuration: const Duration(seconds: 5),
        );

        expect(outcome, isNotNull);
        expect(outcome!.degraded, isTrue);
      },
    );

    test(
      'falls back to first-segment-only when both ffmpeg and pure-Dart fail',
      () async {
        final w1 = '${tmp.path}/s1.wav';
        final junk = '${tmp.path}/junk.wav';
        await File(w1).writeAsBytes(_buildWavFile([1, 2]));
        // junk is NOT a WAV (no RIFF header) — pure-Dart concat will fail.
        await File(junk).writeAsBytes(Uint8List.fromList([0, 0, 0, 0]));

        final service = RecordingFinalizationService(
          concat: _StubConcatService(result: () => null),
          documentsDirFn: tmpDocsDir,
          compressFn: okCompress,
        );

        final outcome = await service.finalize(
          sessionId: 'sess',
          segmentPaths: [w1, junk],
          totalDuration: const Duration(seconds: 5),
        );

        expect(outcome, isNotNull);
        expect(outcome!.degraded, isTrue);
      },
    );

    test('for non-WAV multi-segment, pure-Dart fallback does NOT run (concat '
        'failure falls straight to first segment)', () async {
      final m1 = '${tmp.path}/s1.m4a';
      final m2 = '${tmp.path}/s2.m4a';
      await File(m1).writeAsBytes(Uint8List(8));
      await File(m2).writeAsBytes(Uint8List(8));

      final service = RecordingFinalizationService(
        concat: _StubConcatService(result: () => null),
        documentsDirFn: tmpDocsDir,
        compressFn: okCompress,
      );

      final outcome = await service.finalize(
        sessionId: 'sess',
        segmentPaths: [m1, m2],
        totalDuration: const Duration(seconds: 5),
      );

      expect(outcome, isNotNull);
      expect(outcome!.degraded, isTrue);
      // No compress stage for m4a → result is the first segment as-is.
      expect(outcome.result.filePath, m1);
    });
  });

  group('finalize - compress fallbacks', () {
    test('compress failure on WAV returns format=wav RecordingResult and '
        'marks outcome as degraded', () async {
      final wav = '${tmp.path}/seg.wav';
      await File(wav).writeAsBytes(_buildWavFile([1, 2, 3]));

      final service = RecordingFinalizationService(
        concat: _StubConcatService(),
        documentsDirFn: tmpDocsDir,
        compressFn: failingCompress,
      );

      final outcome = await service.finalize(
        sessionId: 'sess',
        segmentPaths: [wav],
        totalDuration: const Duration(seconds: 5),
      );

      expect(outcome, isNotNull);
      expect(outcome!.degraded, isTrue);
      expect(outcome.result.filePath, wav);
      expect(outcome.result.format, 'wav');
    });

    test('compress throwing is treated as a compress failure', () async {
      final wav = '${tmp.path}/seg.wav';
      await File(wav).writeAsBytes(_buildWavFile([1, 2, 3]));

      final service = RecordingFinalizationService(
        concat: _StubConcatService(),
        documentsDirFn: tmpDocsDir,
        compressFn: (_, _) async => throw Exception('compress boom'),
      );

      final outcome = await service.finalize(
        sessionId: 'sess',
        segmentPaths: [wav],
        totalDuration: const Duration(seconds: 5),
      );

      expect(outcome, isNotNull);
      expect(outcome!.degraded, isTrue);
      expect(outcome.result.format, 'wav');
    });
  });

  group('finalize - callback semantics', () {
    test('works without onStage callback (optional parameter)', () async {
      final wav = '${tmp.path}/seg.wav';
      await File(wav).writeAsBytes(_buildWavFile([1]));

      final service = RecordingFinalizationService(
        concat: _StubConcatService(),
        documentsDirFn: tmpDocsDir,
        compressFn: okCompress,
      );

      final outcome = await service.finalize(
        sessionId: 'sess',
        segmentPaths: [wav],
        totalDuration: const Duration(seconds: 1),
      );

      expect(outcome, isNotNull);
    });

    test('totalDuration is propagated into the RecordingResult', () async {
      final m4a = '${tmp.path}/seg.m4a';
      await File(m4a).writeAsBytes(Uint8List(8));

      final service = RecordingFinalizationService(
        concat: _StubConcatService(),
        documentsDirFn: tmpDocsDir,
        compressFn: okCompress,
      );

      final outcome = await service.finalize(
        sessionId: 'sess',
        segmentPaths: [m4a],
        totalDuration: const Duration(milliseconds: 12500),
      );

      expect(outcome!.result.durationSeconds, 12.5);
    });
  });
}
