/// ENG-527: discarding a *resumed* recording must not swallow the finalized
/// audio the session is still anchored to.
///
/// The exemption ENG-521 granted `SegmentedRecorder.discard` — "it runs before
/// any anchor can exist" — is true of a fresh recording and false of a resumed
/// one: the startup sweep promotes a finished session back to the status the
/// banner reads *with its anchor intact*, and that is the session a resume
/// picks up.
///
/// Every case drives the real recorder over real files in a temp directory and
/// then looks at the two things that matter to the person: is the audio still
/// on the disk, and is the recording still offered. None asserts which status
/// was written.
library;

import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/core/database/database_provider.dart';
import 'package:oral_collector/features/recording/data/repositories/recording_session_repository.dart';
import 'package:oral_collector/features/recording/data/services/recovery_coordinator.dart';
import 'package:oral_collector/features/recording/data/services/recovery_disk.dart';
import 'package:oral_collector/features/recording/data/services/segment_paths.dart';
import 'package:oral_collector/features/recording/data/services/segmented_recorder.dart';
import 'package:oral_collector/features/recording/data/services/storage_guard.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/interrupted_sessions_notifier.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  late Directory docs;
  late AppDatabase db;
  late RecordingSessionRepository sessions;
  late ProviderContainer container;
  late _MockAudioRecorder mockRecorder;
  late StreamController<Uint8List> pcm;
  late Set<String> undeletable;
  late SegmentedRecorder rec;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    docs = await Directory.systemTemp.createTemp('eng527_resumed_');

    // The anchor is resolved by basename in the current documents directory,
    // so the production lookup has to land in this temp directory.
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (_) async => docs.path);
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    db = AppDatabase.forTesting(NativeDatabase.memory());
    sessions = RecordingSessionRepository(db);
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        recoveryCoordinatorProvider.overrideWith(
          (ref) => RecoveryCoordinator(
            ref,
            disk: RecoveryDisk(documentsPath: () async => docs.path),
          ),
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
    when(() => mockRecorder.pause()).thenAnswer((_) async {});
    when(() => mockRecorder.resume()).thenAnswer((_) async {});
    when(() => mockRecorder.dispose()).thenAnswer((_) async {});

    undeletable = <String>{};
    rec = SegmentedRecorder(
      sessionRepo: sessions,
      storageGuard: _StubStorageGuard(),
      segmentDuration: const Duration(seconds: 1),
      recorderFactory: () => mockRecorder,
      docDirProvider: () async => docs.path,
      configureAudioSession: false,
      fileDeleter: (path) async {
        if (undeletable.contains(path)) {
          throw const FileSystemException('refusing to delete');
        }
        final file = File(path);
        if (file.existsSync()) await file.delete();
      },
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

  String anchorFor(String sessionId) => '${docs.path}/recording_$sessionId.m4a';

  /// The row a resume picks up: recorded, finalized (so it carries the v14
  /// anchor), and promoted back to the status the unsaved list reads by the
  /// startup sweep — which leaves both the anchor and the segments in place.
  ///
  /// [anchored] false is the pre-v14 / never-finalized shape: segments and no
  /// anchor at all.
  Future<List<String>> seedResumableSession(
    String sessionId, {
    required bool anchored,
    int segmentCount = 2,
  }) async {
    await sessions.insertSession(
      RecordingSessionsCompanion.insert(
        id: sessionId,
        projectId: 'proj-1',
        genreId: 'genre-1',
        subcategoryId: const Value('sub-1'),
        startedAt: DateTime(2026, 8, 12),
      ),
    );
    final paths = <String>[];
    for (var i = 0; i < segmentCount; i++) {
      final path = SegmentPaths.forSegment(docs.path, sessionId, i);
      await File(path).writeAsString('segment $i');
      await sessions.appendSegment(sessionId, path, 1.0);
      paths.add(path);
    }
    if (anchored) {
      await File(anchorFor(sessionId)).writeAsString('finalized audio');
      await sessions.completeWithFinalizedAudio(
        sessionId,
        filePath: anchorFor(sessionId),
        durationSeconds: segmentCount.toDouble(),
      );
    }
    await sessions.markCrashed(sessionId);
    return paths;
  }

  /// What `_startRecorderForResume` does: flips the row active and hands the
  /// surviving segments to the recorder.
  Future<void> resume(String sessionId, List<String> paths) async {
    await sessions.markActive(sessionId);
    final ok = await rec.startSession(
      sessionId: sessionId,
      amplitudeMapper: (_) => 0.0,
      resumeFromPaths: paths,
      resumeFromDuration: Duration(seconds: paths.length),
    );
    expect(ok, isTrue);
  }

  Future<List<String>> offered() async {
    await container.read(recoveryCoordinatorProvider).refresh();
    return container
        .read(interruptedSessionsProvider)
        .map((s) => s.sessionId)
        .toList();
  }

  Uint8List toneChunk(int samples) => Uint8List(samples * _bytesPerSample);

  Future<void> recordOneSegment() async {
    // 1.5s at a 1s segment duration, in 100ms chunks — enough to close a
    // segment and leave a second one open.
    const total = _sampleRate + _sampleRate ~/ 2;
    for (var n = 0; n < total; n += 1600) {
      pcm.add(toneChunk(n + 1600 > total ? total - n : 1600));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
    }
    // Fechar o segmento é uma cadeia assíncrona — o sink, o cabeçalho WAV, a
    // linha no banco — e nada garante que ela caiba nos microtasks acima. Num
    // runner lento (Linux, `--coverage`) ela não cabia, e o caso falhava com
    // "nothing to erase otherwise" sem que nada estivesse errado. Esperar o
    // segmento aparecer não muda o que se mede.
    final deadline = DateTime.now().add(const Duration(seconds: 10));
    while (rec.segmentPaths.isEmpty && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  group('ENG-527: discarding a resumed recording', () {
    test(
      'leaves the anchored audio on disk and the recording offered',
      () async {
        final paths = await seedResumableSession(
          'sess-resumed',
          anchored: true,
        );
        await resume('sess-resumed', paths);

        await rec.discard();

        expect(
          File(anchorFor('sess-resumed')).existsSync(),
          isTrue,
          reason:
              'walking away from a resume is not a request to delete the '
              'finalized recording',
        );
        expect(await offered(), contains('sess-resumed'));
      },
    );

    test('discarding a fresh recording still erases it', () async {
      // The net that stops the guard from becoming never-discards.
      await sessions.insertSession(
        RecordingSessionsCompanion.insert(
          id: 'sess-fresh',
          projectId: 'proj-1',
          genreId: 'genre-1',
          startedAt: DateTime(2026, 8, 12),
        ),
      );
      final ok = await rec.startSession(
        sessionId: 'sess-fresh',
        amplitudeMapper: (_) => 0.0,
      );
      expect(ok, isTrue);
      await recordOneSegment();
      final recorded = rec.segmentPaths;
      expect(recorded, isNotEmpty, reason: 'nothing to erase otherwise');

      await rec.discard();

      for (final path in recorded) {
        expect(File(path).existsSync(), isFalse);
      }
      expect(await offered(), isNot(contains('sess-fresh')));
    });

    test(
      'a segment that refuses to be deleted keeps the session reachable',
      () async {
        // No anchor here on purpose: the only audio left is the segment the
        // delete failed on, so this measures the delete, not the anchor.
        final paths = await seedResumableSession('sess-stuck', anchored: false);
        undeletable.add(paths.first);
        await resume('sess-stuck', paths);

        await rec.discard();

        expect(File(paths.first).existsSync(), isTrue);
        expect(await offered(), contains('sess-stuck'));
      },
    );

    test(
      'the recording that survives the discard opens on its anchored audio',
      () async {
        final paths = await seedResumableSession('sess-usable', anchored: true);
        await resume('sess-usable', paths);
        await rec.discard();

        final list = await offered();
        expect(list, contains('sess-usable'));

        final result = await container
            .read(interruptedSessionsNotifierProvider.notifier)
            .save('sess-usable');

        expect(result, isNotNull);
        expect(result!.filePath, anchorFor('sess-usable'));
        expect(File(result.filePath).existsSync(), isTrue);
      },
    );
  });
}
