import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/core/database/database_provider.dart';
import 'package:oral_collector/features/recording/data/repositories/recording_session_repository.dart';
import 'package:oral_collector/features/recording/data/services/recovery_coordinator.dart';
import 'package:oral_collector/features/recording/data/services/segmented_recorder.dart';
import 'package:oral_collector/features/recording/data/services/storage_guard.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockAudioRecorder extends Mock implements AudioRecorder {}

class _FakeRecordConfig extends Fake implements RecordConfig {}

class _StubStorageGuard extends StorageGuard {
  @override
  Future<StorageCheck<DuringSeverity>> checkDuring() async =>
      const StorageCheck<DuringSeverity>(
        severity: DuringSeverity.ok,
        freeBytes: 1024 * 1024 * 1024,
        estimatedSeconds: 999999,
      );
}

const int _bytesPerSecond = 16000 * 2;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(_FakeRecordConfig());
    registerFallbackValue(Duration.zero);
  });

  late Directory docs;
  late AppDatabase db;
  late RecordingSessionRepository repo;
  late ProviderContainer container;
  late _MockAudioRecorder mockRecorder;
  late StreamController<Uint8List> pcm;
  late SegmentedRecorder rec;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    docs = await Directory.systemTemp.createTemp('eng408_death_');
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = RecordingSessionRepository(db);
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        recoveryCoordinatorProvider.overrideWith(
          (ref) =>
              RecoveryCoordinator(ref, directoryResolver: () async => docs),
        ),
      ],
    );

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
      segmentDuration: const Duration(seconds: 1),
      recorderFactory: () => mockRecorder,
      docDirProvider: () async => docs.path,
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
    container.dispose();
    await db.close();
    if (docs.existsSync()) docs.deleteSync(recursive: true);
  });

  Future<RecordingSession> waitForSegments(String id, int count) async {
    for (var attempt = 0; attempt < 300; attempt++) {
      final session = await repo.getById(id);
      if (session != null && repo.decodeSegmentPaths(session).length >= count) {
        return session;
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    fail('$id never reached $count finalized segments');
  }

  test(
    'ENG-408: a recording killed mid-session comes back whole — the rotating '
    'segment is repaired and attached, not lost',
    () async {
      await repo.insertSession(
        RecordingSessionsCompanion.insert(
          id: 'killed',
          projectId: 'proj-1',
          genreId: 'genre-1',
          startedAt: DateTime(2026, 8, 11),
        ),
      );
      await rec.startSession(sessionId: 'killed', amplitudeMapper: (_) => 0.0);

      // 3.5 s at 1 s per segment: three rotations land in the DB, the fourth
      // segment is still open when the process dies.
      const streamedBytes = _bytesPerSecond * 7 ~/ 2;
      final chunk = Uint8List(_bytesPerSecond ~/ 10);
      for (var written = 0; written < streamedBytes; written += chunk.length) {
        pcm.add(chunk);
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);
      }

      // Each rotation finalizes through SegmentedRecorder's internal chain —
      // an async sink close plus a SQLite append. Reading the row the instant
      // the loop ends races that chain: the third rotation is often still in
      // flight, and the test would be asserting how fast the machine is.
      // Wait for the three to land, so "killed after three rotations" is the
      // precondition rather than the coin flip.
      final duringDeath = await waitForSegments('killed', 3);

      // Process death: no finish(), no discard(). The session row stays
      // 'active' and the in-flight WAV keeps its zeroed header placeholders.
      expect(duringDeath.lastSegmentIndex, 2);

      // Next launch.
      await container.read(recoveryCoordinatorProvider).scanOnStartup();

      final recovered = await repo.getById('killed');
      final paths = repo.decodeSegmentPaths(recovered!);
      expect(recovered.status, 'crashed');
      expect(
        paths.length,
        4,
        reason: 'the segment that was rotating must be attached too',
      );
      expect(
        recovered.lastSegmentIndex,
        3,
        reason:
            'the index must advance past the repaired segment, otherwise the '
            'cleanup that runs when the user taps recover deletes it again',
      );
      expect(recovered.totalDurationSeconds, closeTo(3.5, 0.01));

      var recoveredPcm = 0;
      for (final p in paths) {
        recoveredPcm += await File(p).length() - 44;
      }
      expect(
        recoveredPcm,
        streamedBytes,
        reason: 'every captured byte survives the kill',
      );

      expect(
        container
            .read(interruptedSessionsProvider)
            .firstWhere((s) => s.sessionId == 'killed')
            .totalDuration,
        const Duration(milliseconds: 3500),
      );
    },
  );
}
