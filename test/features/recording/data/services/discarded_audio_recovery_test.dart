/// ENG-522: audio that reached a terminal session status before the ENG-521
/// fix, and whose files are still on the disk, comes back to the unsaved list.
///
/// Every case seeds real session rows and real files, runs the real
/// `scanOnStartup`, and observes what the person is offered — never which
/// query ran or which status was written.
library;

import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/core/database/database_provider.dart';
import 'package:oral_collector/features/recording/data/repositories/local_recording_repository.dart';
import 'package:oral_collector/features/recording/data/repositories/recording_session_repository.dart';
import 'package:oral_collector/features/recording/data/services/recovery_coordinator.dart';
import 'package:oral_collector/features/recording/data/services/recovery_disk.dart';
import 'package:oral_collector/features/recording/data/services/segment_paths.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/interrupted_sessions_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory docs;
  late AppDatabase db;
  late RecordingSessionRepository sessions;
  late LocalRecordingRepository recordings;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    docs = await Directory.systemTemp.createTemp('eng522_recover_');

    // Both the recovery predicate and the discard resolve an anchor by
    // basename in the current documents directory, so the production lookup
    // has to land in this temp directory.
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (_) async => docs.path);
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    db = AppDatabase.forTesting(NativeDatabase.memory());
    sessions = RecordingSessionRepository(db);
    recordings = LocalRecordingRepository(db);
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
  });

  tearDown(() async {
    container.dispose();
    await db.close();
    if (docs.existsSync()) docs.deleteSync(recursive: true);
  });

  String anchorFor(String sessionId) => '${docs.path}/recording_$sessionId.m4a';

  /// A session row shaped the way production shapes it: it records, it may
  /// finalize (which anchors the row), and it may then reach [status].
  Future<void> seedSession(
    String sessionId, {
    required String status,
    String? anchorPath,
    bool anchorFileExists = true,
    bool segmentsOnDisk = false,
    int segmentCount = 3,
  }) async {
    final paths = <String>[];
    for (var i = 0; i < segmentCount; i++) {
      final path = SegmentPaths.forSegment(docs.path, sessionId, i);
      paths.add(path);
      if (segmentsOnDisk) await File(path).writeAsString('segment');
    }
    await sessions.insertSession(
      RecordingSessionsCompanion.insert(
        id: sessionId,
        projectId: 'proj-1',
        genreId: 'genre-1',
        subcategoryId: const Value('sub-1'),
        startedAt: DateTime(2026, 8, 12),
        status: const Value('active'),
        segmentPathsJson: Value(jsonEncode(paths)),
        totalDurationSeconds: const Value(1080.0),
        lastSegmentIndex: Value(segmentCount - 1),
      ),
    );
    if (anchorPath != null) {
      if (anchorFileExists) await File(anchorPath).writeAsString('final audio');
      await sessions.completeWithFinalizedAudio(
        sessionId,
        filePath: anchorPath,
        durationSeconds: 1080.0,
      );
    }
    switch (status) {
      case 'discarded':
        await sessions.markDiscarded(sessionId);
      case 'crashed':
        await sessions.markCrashed(sessionId);
      case 'completed':
        await sessions.markCompleted(sessionId);
    }
  }

  Future<void> seedSavedRecording(String sessionId) async {
    await recordings.insertRecording(
      LocalRecordingsCompanion(
        id: Value('rec-$sessionId'),
        projectId: const Value('proj-1'),
        genreId: const Value('genre-1'),
        localFilePath: Value('${docs.path}/recording_$sessionId.m4a'),
        recordedAt: Value(DateTime(2026, 8, 12)),
      ),
    );
  }

  Future<List<String>> offeredAfterScan() async {
    await container.read(recoveryCoordinatorProvider).scanOnStartup();
    return container
        .read(interruptedSessionsProvider)
        .map((s) => s.sessionId)
        .toList();
  }

  group('ENG-522: audio stranded by a terminal status comes back', () {
    test('a discarded session whose finalized audio is still on disk is '
        'offered again', () async {
      // The ENG-521 leak: the row reached a status no sweep queries while the
      // file it names was never deleted, so 18 minutes of audio sat on the
      // disk with nothing able to reach it.
      await seedSession(
        'sess-stranded',
        status: 'discarded',
        anchorPath: anchorFor('sess-stranded'),
      );

      expect(await offeredAfterScan(), contains('sess-stranded'));
    });

    test('a discarded session with no anchor but surviving segments is '
        'offered again', () async {
      // Walking away from a *resumed* session was the other half of the leak,
      // and it happens before any finalize can anchor the row: what is left is
      // segments on disk and nothing pointing at them.
      await seedSession(
        'sess-segments',
        status: 'discarded',
        segmentsOnDisk: true,
      );

      expect(await offeredAfterScan(), contains('sess-segments'));
    });

    test('a discarded session whose audio is really gone stays gone', () async {
      // A discard that worked. There is nothing to give back, and asking for
      // it must not break the rest of the scan.
      await seedSession(
        'sess-erased',
        status: 'discarded',
        anchorPath: anchorFor('sess-erased'),
        anchorFileExists: false,
      );
      await seedSession(
        'sess-neighbour',
        status: 'crashed',
        segmentsOnDisk: true,
      );

      final offered = await offeredAfterScan();
      expect(offered, isNot(contains('sess-erased')));
      expect(
        offered,
        contains('sess-neighbour'),
        reason: 'a hopeless row must not take the rest of the scan down',
      );
    });

    test('a recording the person discards after it came back does not come '
        'back a second time', () async {
      // The worst outcome this change could have: recover, the person
      // discards, the next launch hands it straight back, forever. The
      // recovery runs once per device, so the second launch leaves the row
      // alone even though the audio is still reachable — which is the state a
      // deliberate discard can genuinely leave behind (discarding a resumed
      // recording deletes the new segments and never touches the anchor).
      await seedSession(
        'sess-loop',
        status: 'discarded',
        anchorPath: anchorFor('sess-loop'),
      );
      expect(await offeredAfterScan(), contains('sess-loop'));

      await sessions.markDiscarded('sess-loop');
      expect(File(anchorFor('sess-loop')).existsSync(), isTrue);

      expect(await offeredAfterScan(), isNot(contains('sess-loop')));
    });

    test(
      'sessions in every other status are left exactly as they were',
      () async {
        // The flood guard: recovery must widen the list by the stranded rows and
        // by nothing else.
        await seedSession(
          'sess-saved',
          status: 'completed',
          anchorPath: anchorFor('sess-saved'),
        );
        await seedSavedRecording('sess-saved');
        await seedSession(
          'sess-unsaved',
          status: 'completed',
          anchorPath: anchorFor('sess-unsaved'),
        );
        await seedSession(
          'sess-crashed',
          status: 'crashed',
          segmentsOnDisk: true,
        );
        await seedSession('sess-open', status: 'active', segmentsOnDisk: true);

        final offered = await offeredAfterScan();
        expect(offered, isNot(contains('sess-saved')));
        expect(offered, contains('sess-unsaved'));
        expect(offered, contains('sess-crashed'));
        expect(offered, contains('sess-open'));
      },
    );

    test('a recovered recording can be opened and saved', () async {
      // Handing back a row nobody can use is not handing anything back.
      await seedSession(
        'sess-usable',
        status: 'discarded',
        anchorPath: anchorFor('sess-usable'),
      );

      final offered = await offeredAfterScan();
      expect(offered, contains('sess-usable'));

      final notifier = container.read(
        interruptedSessionsNotifierProvider.notifier,
      );
      final result = await notifier.save('sess-usable');
      expect(result, isNotNull);
      expect(File(result!.filePath).existsSync(), isTrue);
      expect(result.durationSeconds, greaterThan(0));

      await notifier.confirmRecovery(
        'sess-usable',
        keepPath: result.filePath,
        durationSeconds: result.durationSeconds,
      );

      expect(
        container.read(interruptedSessionsProvider).map((s) => s.sessionId),
        isNot(contains('sess-usable')),
        reason: 'a confirmed save resolves the session',
      );
      expect(File(anchorFor('sess-usable')).existsSync(), isTrue);
    });
  });
}
