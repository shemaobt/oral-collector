import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:record/record.dart';

import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/features/recording/data/repositories/recording_session_repository.dart';
import 'package:oral_collector/features/recording/data/services/segmented_recorder.dart';
import 'package:oral_collector/features/recording/data/services/storage_guard.dart';
import 'package:oral_collector/features/recording/data/services/wav_header_repair.dart';

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

const int _sampleRate = 16000;
const int _bytesPerSample = 2;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(_FakeRecordConfig());
    registerFallbackValue(Duration.zero);
  });

  late Directory tmpDocs;
  late AppDatabase db;
  late RecordingSessionRepository repo;
  late _StubStorageGuard storageGuard;
  late _MockAudioRecorder mockRecorder;
  late StreamController<Uint8List> pcm;
  late SegmentedRecorder rec;

  Future<void> seedSession(String id) {
    return repo.insertSession(
      RecordingSessionsCompanion.insert(
        id: id,
        projectId: 'proj-1',
        genreId: 'genre-1',
        startedAt: DateTime.utc(2026, 5, 20),
      ),
    );
  }

  setUp(() async {
    tmpDocs = await Directory.systemTemp.createTemp('eng63_streaming_');
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = RecordingSessionRepository(db);
    storageGuard = _StubStorageGuard();
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
    when(() => mockRecorder.pause()).thenAnswer((_) async {});
    when(() => mockRecorder.resume()).thenAnswer((_) async {});
    when(() => mockRecorder.dispose()).thenAnswer((_) async {});

    rec = SegmentedRecorder(
      sessionRepo: repo,
      storageGuard: storageGuard,
      segmentDuration: const Duration(seconds: 1),
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
    if (tmpDocs.existsSync()) {
      await tmpDocs.delete(recursive: true);
    }
  });

  Uint8List toneChunk(int startIndex, int samples) {
    final bytes = Uint8List(samples * _bytesPerSample);
    final view = ByteData.sublistView(bytes);
    for (var i = 0; i < samples; i++) {
      view.setInt16(i * 2, (startIndex + i) & 0x7FFF, Endian.little);
    }
    return bytes;
  }

  Future<List<int>> readPcmSamples(String path) async {
    final raw = await File(path).readAsBytes();
    expect(raw.length, greaterThanOrEqualTo(44));
    final samples = <int>[];
    final pcmPart = raw.sublist(44);
    final view = ByteData.sublistView(pcmPart);
    for (var i = 0; i < pcmPart.length ~/ 2; i++) {
      samples.add(view.getInt16(i * 2, Endian.little));
    }
    return samples;
  }

  Future<void> emitAndYield(Uint8List chunk) async {
    pcm.add(chunk);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  test('ENG-63: PCM samples are contiguous across segment boundaries', () async {
    await seedSession('sess1');
    final ok = await rec.startSession(
      sessionId: 'sess1',
      amplitudeMapper: (_) => 0.0,
    );
    expect(ok, isTrue);

    // Emit 3.5 seconds of monotonic samples in 100ms chunks (1600 samples each).
    // At 1s segmentDuration, this spans 3 full boundaries.
    const totalSamples = _sampleRate * 3 + _sampleRate ~/ 2;
    const chunkSamples = 1600;
    for (var n = 0; n < totalSamples; n += chunkSamples) {
      final end = (n + chunkSamples) > totalSamples
          ? totalSamples
          : n + chunkSamples;
      await emitAndYield(toneChunk(n, end - n));
    }

    final result = await rec.finish();
    expect(result, isNotNull);
    expect(
      result!.segmentPaths.length,
      greaterThanOrEqualTo(3),
      reason: '3.5s @ 1s/segment → at least 3 segments',
    );

    final reconstructed = <int>[];
    for (final p in result.segmentPaths) {
      reconstructed.addAll(await readPcmSamples(p));
    }

    expect(
      reconstructed.length,
      totalSamples,
      reason:
          'every captured sample must land in some segment (ENG-63 root cause)',
    );
    for (var i = 0; i < reconstructed.length; i++) {
      if (reconstructed[i] != (i & 0x7FFF)) {
        fail(
          'sample at index $i = ${reconstructed[i]}, expected ${i & 0x7FFF} '
          '(would indicate a gap at index $i)',
        );
      }
    }
  });

  test('pause() drops PCM bytes; resume() resumes capture', () async {
    await seedSession('sess2');
    await rec.startSession(sessionId: 'sess2', amplitudeMapper: (_) => 0.0);

    // 800 samples (50ms), pause, 800 (must drop), resume, 800.
    await emitAndYield(toneChunk(0, 800));
    await rec.pause();
    await emitAndYield(toneChunk(800, 800));
    await rec.resume();
    await emitAndYield(toneChunk(1600, 800));

    final result = await rec.finish();
    expect(result, isNotNull);

    final samples = <int>[];
    for (final p in result!.segmentPaths) {
      samples.addAll(await readPcmSamples(p));
    }

    expect(
      samples.length,
      1600,
      reason: 'first 800 + last 800 = 1600; middle 800 dropped while paused',
    );
    for (var i = 0; i < 800; i++) {
      expect(samples[i], i & 0x7FFF);
    }
    for (var i = 0; i < 800; i++) {
      expect(samples[800 + i], (1600 + i) & 0x7FFF);
    }
  });

  test(
    'finish() flushes the final partial segment with a size-patched WAV header',
    () async {
      await seedSession('sess3');
      await rec.startSession(sessionId: 'sess3', amplitudeMapper: (_) => 0.0);

      // 500 ms = 8000 samples; below 1s segment threshold → single partial segment.
      await emitAndYield(toneChunk(0, _sampleRate ~/ 2));

      final result = await rec.finish();
      expect(result, isNotNull);
      expect(result!.segmentPaths.length, 1);

      // WavHeaderRepair should be a no-op (header already patched).
      final repaired = await const WavHeaderRepair().repair(
        result.segmentPaths.first,
      );
      expect(repaired, isNotNull);
      expect(
        repaired!.duration,
        const Duration(milliseconds: 500),
        reason: 'data chunk size in header == 16000 bytes ⇒ 500ms',
      );
    },
  );

  test(
    'discard() removes all segment files and marks session discarded',
    () async {
      await seedSession('sess4');
      await rec.startSession(sessionId: 'sess4', amplitudeMapper: (_) => 0.0);

      await emitAndYield(toneChunk(0, _sampleRate)); // 1 full segment
      await emitAndYield(toneChunk(_sampleRate, 1000)); // partial

      await rec.discard();

      final remainingWavs = tmpDocs
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.wav'))
          .toList();
      expect(
        remainingWavs,
        isEmpty,
        reason: 'discard must delete every WAV it created',
      );

      final session = await repo.getById('sess4');
      expect(session?.status, 'discarded');
    },
  );

  test(
    'crash recovery: an in-progress segment file with unclosed sink is repairable',
    () async {
      await seedSession('sess5');
      await rec.startSession(sessionId: 'sess5', amplitudeMapper: (_) => 0.0);

      // 250 ms in mid-segment, then simulate crash by tearing down the PCM stream
      // WITHOUT calling finish() or discard().
      await emitAndYield(toneChunk(0, _sampleRate ~/ 4));

      final inFlightFiles = tmpDocs
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.wav'))
          .toList();
      expect(
        inFlightFiles,
        isNotEmpty,
        reason: 'at least one segment file must exist on disk mid-stream',
      );

      // Process death — no graceful close. WavHeaderRepair is what runs on
      // the next launch via RecoveryCoordinator.
      final repaired = await const WavHeaderRepair().repair(
        inFlightFiles.first.path,
      );
      expect(repaired, isNotNull);
      expect(
        repaired!.duration,
        const Duration(milliseconds: 250),
        reason: 'placeholder header must be recoverable from the file size',
      );
    },
  );
}
