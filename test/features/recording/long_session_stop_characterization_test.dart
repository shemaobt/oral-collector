@Timeout(Duration(minutes: 5))
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/features/recording/data/repositories/recording_session_repository.dart';
import 'package:oral_collector/features/recording/data/services/recording_concat_service.dart';
import 'package:oral_collector/features/recording/data/services/recording_finalization_service.dart';
import 'package:oral_collector/features/recording/data/services/segmented_recorder.dart';
import 'package:oral_collector/features/recording/data/services/storage_guard.dart';
import 'package:record/record.dart';

class _MockAudioRecorder extends Mock implements AudioRecorder {}

class _FakeRecordConfig extends Fake implements RecordConfig {}

class _StubStorageGuard extends StorageGuard {
  @override
  Future<StorageCheck<DuringSeverity>> checkDuring() async {
    return const StorageCheck<DuringSeverity>(
      severity: DuringSeverity.ok,
      freeBytes: 1024 * 1024 * 1024,
      estimatedSeconds: 999999,
    );
  }
}

/// Stands in for ffmpeg: never available in the VM/CI, so the concat either
/// "succeeds" by byte-copying the segments or reports failure so the pure-Dart
/// fallback runs.
class _StubConcatService implements RecordingConcatService {
  _StubConcatService({required this.succeeds});

  final bool succeeds;

  @override
  Future<String?> concatSegments({
    required List<String> segmentPaths,
    required String outputPath,
  }) async {
    if (!succeeds) return null;
    final out = File(outputPath).openSync(mode: FileMode.write);
    try {
      for (final p in segmentPaths) {
        out.writeFromSync(await File(p).readAsBytes());
      }
    } finally {
      out.closeSync();
    }
    return outputPath;
  }
}

const int _sampleRate = 16000;
const int _numChannels = 1;
const int _bytesPerSample = 2;
const int _bytesPerSecond = _sampleRate * _numChannels * _bytesPerSample;

/// What the app really does: 60 s per segment (SegmentedRecorder's default,
/// which the notifier never overrides).
const Duration _productionSegmentDuration = Duration(seconds: 60);
const Duration _reportedSessionLength = Duration(minutes: 18);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(_FakeRecordConfig());
    registerFallbackValue(Duration.zero);
  });

  late Directory tmpDocs;
  late AppDatabase db;
  late RecordingSessionRepository repo;
  late _MockAudioRecorder mockRecorder;
  late StreamController<Uint8List> pcm;
  late SegmentedRecorder rec;

  setUp(() async {
    tmpDocs = await Directory.systemTemp.createTemp('eng408_long_');
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = RecordingSessionRepository(db);
    mockRecorder = _MockAudioRecorder();
    pcm = StreamController<Uint8List>.broadcast();

    when(() => mockRecorder.hasPermission()).thenAnswer((_) async => true);
    when(
      () => mockRecorder.startStream(any()),
    ).thenAnswer((_) async => pcm.stream);
    when(
      () => mockRecorder.onAmplitudeChanged(any()),
    ).thenAnswer((_) => const Stream<Amplitude>.empty());
    when(() => mockRecorder.stop()).thenAnswer((_) async => null);
    when(() => mockRecorder.dispose()).thenAnswer((_) async {});

    rec = SegmentedRecorder(
      sessionRepo: repo,
      storageGuard: _StubStorageGuard(),
      segmentDuration: _productionSegmentDuration,
      recorderFactory: () => mockRecorder,
      docDirProvider: () async => tmpDocs.path,
      configureAudioSession: false,
    );
  });

  tearDown(() async {
    try {
      await rec.dispose();
    } catch (_) {}
    try {
      await pcm.close();
    } catch (_) {}
    await db.close();
    // finalize() deletes its sources with unawaited(); those are still in
    // flight here. Let them land, then remove the directory synchronously —
    // an await between the check and the delete hands the event loop back to
    // them and the recursive walk races the files disappearing under it.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (tmpDocs.existsSync()) tmpDocs.deleteSync(recursive: true);
  });

  Future<void> streamAudio(Duration length) async {
    // record delivers PCM in small buffers; 100 ms is the realistic cadence.
    final chunk = Uint8List(_bytesPerSecond ~/ 10);
    final chunks = length.inMilliseconds ~/ 100;
    for (var i = 0; i < chunks; i++) {
      pcm.add(chunk);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
    }
  }

  test('ENG-408 characterization: an 18-minute session stops with segments and '
      'finalizes into a saved recording', () async {
    await repo.insertSession(
      RecordingSessionsCompanion.insert(
        id: 'long',
        projectId: 'proj-1',
        genreId: 'genre-1',
        startedAt: DateTime.utc(2026, 8, 11),
      ),
    );
    expect(
      await rec.startSession(sessionId: 'long', amplitudeMapper: (_) => 0.0),
      isTrue,
    );

    await streamAudio(_reportedSessionLength);

    final sessionResult = await rec.finish();

    expect(
      sessionResult,
      isNotNull,
      reason: 'finish() returning null is the finishProducedNoSegments branch',
    );
    expect(
      sessionResult!.segmentPaths,
      isNotEmpty,
      reason: 'empty paths is the other half of finishProducedNoSegments',
    );
    expect(
      sessionResult.segmentPaths.length,
      _reportedSessionLength.inSeconds ~/ _productionSegmentDuration.inSeconds,
      reason: '18 minutes at 60 s per segment',
    );
    expect(sessionResult.totalDuration, _reportedSessionLength);
    for (final p in sessionResult.segmentPaths) {
      expect(File(p).existsSync(), isTrue, reason: '$p must be on disk');
    }

    final finalizer = RecordingFinalizationService(
      concat: _StubConcatService(succeeds: true),
      documentsDirFn: () async => tmpDocs,
      compressFn: (src, dst) async {
        await File(dst).writeAsBytes(await File(src).readAsBytes());
        return true;
      },
    );

    final outcome = await finalizer.finalize(
      sessionId: sessionResult.sessionId,
      segmentPaths: sessionResult.segmentPaths,
      totalDuration: sessionResult.totalDuration,
    );

    expect(
      outcome,
      isNotNull,
      reason: 'a null outcome is the finalizationFailed branch',
    );
    expect(outcome!.degraded, isFalse);
    expect(File(outcome.result.filePath).existsSync(), isTrue);
    expect(outcome.result.durationSeconds, _reportedSessionLength.inSeconds);
  });
}
