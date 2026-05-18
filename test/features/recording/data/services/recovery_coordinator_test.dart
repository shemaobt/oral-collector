import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:oral_collector/core/config/recording_config.dart';
import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/core/database/database_provider.dart';
import 'package:oral_collector/core/platform/recording_active_flag.dart';
import 'package:oral_collector/features/recording/data/services/recovery_coordinator.dart';
import 'package:oral_collector/features/recording/data/services/segment_paths.dart';
import 'package:oral_collector/features/recording/data/services/wav_header_repair.dart';
import 'package:oral_collector/features/recording/data/repositories/recording_session_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late RecordingSessionRepository repo;
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = RecordingSessionRepository(db);
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<void> seedSession({
    required String id,
    required String status,
    required DateTime startedAt,
    List<String> segmentPaths = const [],
    double totalDurationSeconds = 0.0,
    int lastSegmentIndex = -1,
  }) async {
    await repo.insertSession(
      RecordingSessionsCompanion.insert(
        id: id,
        projectId: 'proj-1',
        genreId: 'genre-1',
        startedAt: startedAt,
        status: Value(status),
        segmentPathsJson: segmentPaths.isEmpty
            ? const Value.absent()
            : Value(jsonEncode(segmentPaths)),
        totalDurationSeconds: Value(totalDurationSeconds),
        lastSegmentIndex: Value(lastSegmentIndex),
      ),
    );
  }

  group('RecordingSessionRepository.findCrashedSessions', () {
    test('returns only crashed sessions ordered by startedAt desc', () async {
      await seedSession(
        id: 'older-crashed',
        status: 'crashed',
        startedAt: DateTime(2026, 5, 10, 9, 0),
        segmentPaths: ['/p1.wav'],
      );
      await seedSession(
        id: 'completed',
        status: 'completed',
        startedAt: DateTime(2026, 5, 11),
        segmentPaths: ['/p2.wav'],
      );
      await seedSession(
        id: 'newer-crashed',
        status: 'crashed',
        startedAt: DateTime(2026, 5, 12, 14, 0),
        segmentPaths: ['/p3.wav'],
      );

      final result = await repo.findCrashedSessions();
      expect(result.map((s) => s.id).toList(), [
        'newer-crashed',
        'older-crashed',
      ]);
    });
  });

  group('RecordingSessionRepository.markActive', () {
    test('flips a crashed session back to active', () async {
      await seedSession(
        id: 'sess-1',
        status: 'crashed',
        startedAt: DateTime(2026, 5, 12),
      );

      await repo.markActive('sess-1');

      final session = await repo.getById('sess-1');
      expect(session?.status, 'active');
    });
  });

  group('RecoveryCoordinator', () {
    test('scanOnStartup marks active sessions as crashed', () async {
      await seedSession(
        id: 'orphaned',
        status: 'active',
        startedAt: DateTime(2026, 5, 12),
        segmentPaths: ['/p.wav'],
      );

      final coordinator = container.read(recoveryCoordinatorProvider);
      await coordinator.scanOnStartup();

      final session = await repo.getById('orphaned');
      expect(session?.status, 'crashed');
    });

    test(
      'scanOnStartup clears the RecordingActiveFlag left over from a crashed run',
      () async {
        SharedPreferences.setMockInitialValues({
          RecordingConfig.recordingActiveFlagKey: true,
        });
        await seedSession(
          id: 'orphaned',
          status: 'active',
          startedAt: DateTime(2026, 5, 12),
          segmentPaths: ['/p.wav'],
        );

        final coordinator = container.read(recoveryCoordinatorProvider);
        await coordinator.scanOnStartup();

        expect(await const RecordingActiveFlag().read(), isFalse);
      },
    );

    test('refresh populates interruptedSessionsProvider with crashed sessions '
        'having at least one segment', () async {
      await seedSession(
        id: 'with-segments',
        status: 'crashed',
        startedAt: DateTime(2026, 5, 12),
        segmentPaths: ['/a.wav', '/b.wav'],
        totalDurationSeconds: 120.0,
        lastSegmentIndex: 1,
      );
      await seedSession(
        id: 'no-segments',
        status: 'crashed',
        startedAt: DateTime(2026, 5, 11),
      );

      final coordinator = container.read(recoveryCoordinatorProvider);
      await coordinator.refresh();

      final list = container.read(interruptedSessionsProvider);
      expect(list.length, 1);
      expect(list.first.sessionId, 'with-segments');
      expect(list.first.segmentCount, 2);
      expect(list.first.totalDuration, const Duration(seconds: 120));

      final noSegments = await repo.getById('no-segments');
      expect(
        noSegments?.status,
        'discarded',
        reason: 'zero-segment crashed sessions should be auto-discarded',
      );
    });

    test('refresh sorts sessions by startedAt desc', () async {
      await seedSession(
        id: 'old',
        status: 'crashed',
        startedAt: DateTime(2026, 5, 10, 8, 0),
        segmentPaths: ['/o.wav'],
      );
      await seedSession(
        id: 'new',
        status: 'crashed',
        startedAt: DateTime(2026, 5, 12, 17, 0),
        segmentPaths: ['/n.wav'],
      );

      final coordinator = container.read(recoveryCoordinatorProvider);
      await coordinator.refresh();

      final list = container.read(interruptedSessionsProvider);
      expect(list.map((s) => s.sessionId).toList(), ['new', 'old']);
    });
  });

  group('RecoveryCoordinator filesystem rescue (ENG-51)', () {
    late Directory tempDir;
    late ProviderContainer fsContainer;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('eng51_recovery_');
      fsContainer = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          recoveryCoordinatorProvider.overrideWith(
            (ref) => RecoveryCoordinator(
              ref,
              wavRepair: _FakeWavHeaderRepair(),
              directoryResolver: () async => tempDir,
            ),
          ),
        ],
      );
    });

    tearDown(() async {
      fsContainer.dispose();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    Future<File> writeSegmentFile(String sessionId, int index) async {
      final path = SegmentPaths.forSegment(tempDir.path, sessionId, index);
      final file = File(path);
      // _FakeWavHeaderRepair only cares about existence + non-zero length.
      await file.writeAsBytes(List<int>.filled(64, 0));
      return file;
    }

    test(
      'refresh rescues crashed session with empty DB paths but orphan files on disk',
      () async {
        // Simulates: _stopNative caught a finish() exception before any
        // appendSegment landed. DB row has segmentPathsJson=[], but the WAV
        // segments are still on the filesystem.
        await seedSession(
          id: 'sess-empty-with-disk',
          status: 'crashed',
          startedAt: DateTime(2026, 5, 15),
          lastSegmentIndex: -1,
        );
        await writeSegmentFile('sess-empty-with-disk', 0);
        await writeSegmentFile('sess-empty-with-disk', 1);

        final coordinator = fsContainer.read(recoveryCoordinatorProvider);
        await coordinator.refresh();

        final list = fsContainer.read(interruptedSessionsProvider);
        expect(list.map((s) => s.sessionId), contains('sess-empty-with-disk'));
        expect(
          list
              .firstWhere((s) => s.sessionId == 'sess-empty-with-disk')
              .segmentCount,
          2,
        );

        final session = await repo.getById('sess-empty-with-disk');
        expect(
          session?.status,
          'crashed',
          reason: 'rescued session stays crashed so the banner keeps showing',
        );
      },
    );

    test(
      'refresh still discards crashed sessions when no orphan files exist',
      () async {
        await seedSession(
          id: 'sess-truly-empty',
          status: 'crashed',
          startedAt: DateTime(2026, 5, 15),
        );

        final coordinator = fsContainer.read(recoveryCoordinatorProvider);
        await coordinator.refresh();

        final list = fsContainer.read(interruptedSessionsProvider);
        expect(
          list.map((s) => s.sessionId),
          isNot(contains('sess-truly-empty')),
        );

        final session = await repo.getById('sess-truly-empty');
        expect(session?.status, 'discarded');
      },
    );

    test(
      'scanOnStartup sweep promotes completed-without-localrecording to crashed',
      () async {
        // Daniel's scenario: _stopNative returned null, SegmentedRecorder.finish
        // marked the session completed, no LocalRecording was ever saved, but
        // 30 segments worth of WAV are still on disk.
        await seedSession(
          id: 'sess-orphan-completed',
          status: 'completed',
          startedAt: DateTime(2026, 5, 15),
          lastSegmentIndex: -1,
        );
        await writeSegmentFile('sess-orphan-completed', 0);
        await writeSegmentFile('sess-orphan-completed', 1);

        final coordinator = fsContainer.read(recoveryCoordinatorProvider);
        await coordinator.scanOnStartup();

        final session = await repo.getById('sess-orphan-completed');
        expect(
          session?.status,
          'crashed',
          reason: 'session is now eligible for the unsaved-recordings banner',
        );

        final list = fsContainer.read(interruptedSessionsProvider);
        expect(list.map((s) => s.sessionId), contains('sess-orphan-completed'));
      },
    );

    test(
      'sweep does NOT promote completed sessions that have a LocalRecording',
      () async {
        await seedSession(
          id: 'sess-saved',
          status: 'completed',
          startedAt: DateTime(2026, 5, 15),
        );
        await writeSegmentFile('sess-saved', 0);

        // Simulate the user pressed Save: a LocalRecording row exists whose
        // localFilePath embeds the session id (the finalize output naming
        // convention used by the recording feature).
        await db
            .into(db.localRecordings)
            .insert(
              LocalRecordingsCompanion.insert(
                id: 'rec-1',
                projectId: 'proj-1',
                genreId: 'genre-1',
                localFilePath: '/tmp/recording_sess-saved.m4a',
                recordedAt: DateTime(2026, 5, 15),
              ),
            );

        final coordinator = fsContainer.read(recoveryCoordinatorProvider);
        await coordinator.scanOnStartup();

        final session = await repo.getById('sess-saved');
        expect(
          session?.status,
          'completed',
          reason: 'session was successfully saved; sweep must not touch it',
        );
      },
    );

    test(
      'sweep does NOT promote completed sessions without orphan segments',
      () async {
        await seedSession(
          id: 'sess-clean-completed',
          status: 'completed',
          startedAt: DateTime(2026, 5, 15),
        );
        // No segment files written.

        final coordinator = fsContainer.read(recoveryCoordinatorProvider);
        await coordinator.scanOnStartup();

        final session = await repo.getById('sess-clean-completed');
        expect(session?.status, 'completed');
      },
    );
  });
}

class _FakeWavHeaderRepair extends WavHeaderRepair {
  @override
  Future<WavRepairResult?> repair(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return null;
    final size = await file.length();
    if (size == 0) return null;
    return WavRepairResult(
      duration: const Duration(seconds: 30),
      fileSize: size,
    );
  }
}
