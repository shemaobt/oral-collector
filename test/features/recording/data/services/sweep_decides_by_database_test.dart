/// ENG-420 slice 2: the startup sweep classifies a session by what the
/// database holds, not by whether fire-and-forget deletions have landed yet.
///
/// Every case here seeds a real session row and real files, runs the real
/// `scanOnStartup`, and observes what the user is offered — never how the
/// sweep decides internally.
library;

import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/core/database/database_provider.dart';
import 'package:oral_collector/features/recording/data/repositories/local_recording_repository.dart';
import 'package:oral_collector/features/recording/data/repositories/recording_session_repository.dart';
import 'package:oral_collector/features/recording/data/services/recovery_coordinator.dart';
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
    docs = await Directory.systemTemp.createTemp('eng420_sweep2_');
    db = AppDatabase.forTesting(NativeDatabase.memory());
    sessions = RecordingSessionRepository(db);
    recordings = LocalRecordingRepository(db);
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        recoveryCoordinatorProvider.overrideWith(
          (ref) =>
              RecoveryCoordinator(ref, directoryResolver: () async => docs),
        ),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
    if (docs.existsSync()) docs.deleteSync(recursive: true);
  });

  /// A session that reached the stop button. [segmentsOnDisk] controls whether
  /// the source segments are still there — i.e. whether the fire-and-forget
  /// deletions have landed.
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
      final p = SegmentPaths.forSegment(docs.path, sessionId, i);
      paths.add(p);
      if (segmentsOnDisk) await File(p).writeAsString('segment');
    }
    await sessions.insertSession(
      RecordingSessionsCompanion.insert(
        id: sessionId,
        projectId: 'proj-1',
        genreId: 'genre-1',
        startedAt: DateTime(2026, 8, 12),
        // An anchored session reaches its status through the repository call
        // the app uses, so the row is built the way production builds it.
        status: Value(anchorPath == null ? status : 'active'),
        segmentPathsJson: Value(jsonEncode(paths)),
        totalDurationSeconds: const Value(1080.0),
        lastSegmentIndex: Value(segmentCount - 1),
      ),
    );
    if (anchorPath == null) return;

    if (anchorFileExists) await File(anchorPath).writeAsString('final audio');
    if (status == 'recovered') {
      await sessions.recoverWithFinalizedAudio(
        sessionId,
        filePath: anchorPath,
        durationSeconds: 1080.0,
      );
    } else {
      await sessions.completeWithFinalizedAudio(
        sessionId,
        filePath: anchorPath,
        durationSeconds: 1080.0,
      );
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

  String anchorFor(String sessionId) => '${docs.path}/recording_$sessionId.m4a';

  group('ENG-420: the sweep decides by the database', () {
    test('a finalized, unsaved session is offered even with every source '
        'segment already deleted', () async {
      // The silent-loss case: 18 minutes of audio on disk, no saved row, and
      // nothing left on disk that looks like a segment.
      await seedSession(
        'sess-gone',
        status: 'completed',
        anchorPath: anchorFor('sess-gone'),
      );

      expect(await offeredAfterScan(), contains('sess-gone'));
    });

    test(
      'a session whose anchored file no longer exists is not offered',
      () async {
        // The common case: the user discarded from the save form, which deletes
        // the audio and never touches the session row. Offering a recovery that
        // cannot succeed is worse than offering nothing.
        await seedSession(
          'sess-rotten',
          status: 'completed',
          anchorPath: anchorFor('sess-rotten'),
          anchorFileExists: false,
        );

        expect(await offeredAfterScan(), isNot(contains('sess-rotten')));
      },
    );

    test('a session that ended as recovered is treated like any other '
        'finalized session', () async {
      await seedSession(
        'sess-resumed',
        status: 'recovered',
        anchorPath: anchorFor('sess-resumed'),
      );

      expect(await offeredAfterScan(), contains('sess-resumed'));
    });

    test(
      'a session that already has its saved recording stays quiet',
      () async {
        await seedSession(
          'sess-saved',
          status: 'completed',
          anchorPath: anchorFor('sess-saved'),
        );
        await seedSavedRecording('sess-saved');

        expect(await offeredAfterScan(), isNot(contains('sess-saved')));
      },
    );

    test('a pre-migration row with no anchor is still found by its leftover '
        'segments', () async {
      // Rows written before schema v14 carry no anchor. The old disk-scanning
      // predicate stays as their fallback, or upgrading would silently drop
      // the recordings it was meant to protect.
      await seedSession(
        'sess-legacy',
        status: 'completed',
        segmentsOnDisk: true,
      );

      expect(await offeredAfterScan(), contains('sess-legacy'));
    });

    test('a pre-migration row with nothing left on disk stays quiet', () async {
      await seedSession('sess-legacy-empty', status: 'completed');

      expect(await offeredAfterScan(), isNot(contains('sess-legacy-empty')));
    });

    test('a recovered session with no anchor is still found by its leftover '
        'segments', () async {
      // Reachable today: recoverSessionFromDisk marks the row recovered
      // BEFORE finalization runs, so being killed during an 18-minute concat
      // leaves exactly this shape — and its segments are all still there.
      await seedSession(
        'sess-recovered-legacy',
        status: 'recovered',
        segmentsOnDisk: true,
      );

      expect(await offeredAfterScan(), contains('sess-recovered-legacy'));
    });

    test(
      'a recovered session whose anchored file is gone stays quiet',
      () async {
        await seedSession(
          'sess-recovered-rotten',
          status: 'recovered',
          anchorPath: anchorFor('sess-recovered-rotten'),
          anchorFileExists: false,
        );

        expect(
          await offeredAfterScan(),
          isNot(contains('sess-recovered-rotten')),
        );
      },
    );

    test('an anchor whose absolute path went stale still finds its audio in '
        'the current documents directory', () async {
      // The documents container moves on iOS reinstall/restore, so a path
      // stored earlier stops resolving while the file is still there. Judging
      // such a session "no audio" would drop a real recording.
      const staleDir = '/var/mobile/Containers/Data/Application/OLD-UUID/docs';
      await seedSession(
        'sess-moved',
        status: 'completed',
        anchorPath: '$staleDir/recording_sess-moved.m4a',
        anchorFileExists: false,
      );
      await File(anchorFor('sess-moved')).writeAsString('final audio');

      expect(await offeredAfterScan(), contains('sess-moved'));
    });

    test('accepting an offer whose segments are gone must not throw the '
        'finalized audio away', () async {
      // save() re-derives from the source segments, and the sessions this
      // sweep newly surfaces are exactly the ones with none left. Marking the
      // row discarded would put it in a state no sweep queries, losing the
      // audio for good — a session still holding a durable artifact must never
      // reach a terminal state. The recovery does not succeed yet, but the
      // offer survives to be tried again.
      await seedSession(
        'sess-trap',
        status: 'completed',
        anchorPath: anchorFor('sess-trap'),
      );
      await offeredAfterScan();

      final result = await container
          .read(interruptedSessionsNotifierProvider.notifier)
          .save('sess-trap');

      expect(result, isNull, reason: 'nothing to re-derive from yet');
      expect((await sessions.getById('sess-trap'))?.status, isNot('discarded'));
      expect(File(anchorFor('sess-trap')).existsSync(), isTrue);
      expect(
        await offeredAfterScan(),
        contains('sess-trap'),
        reason: 'the offer has to come back rather than vanish',
      );
    });

    test(
      'discarding an anchored session takes its finalized audio with it',
      () async {
        // Anchored sessions only started reaching the recovery banner in this
        // slice, so discarding one used to be impossible; leaving the file
        // behind would leak 18 minutes of audio for good.
        await seedSession(
          'sess-discard',
          status: 'completed',
          anchorPath: anchorFor('sess-discard'),
        );
        await offeredAfterScan();

        await container
            .read(interruptedSessionsNotifierProvider.notifier)
            .discard('sess-discard');

        expect(File(anchorFor('sess-discard')).existsSync(), isFalse);
      },
    );
  });
}
