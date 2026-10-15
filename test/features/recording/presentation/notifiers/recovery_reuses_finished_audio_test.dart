/// ENG-420 slice 3: accepting a recovery hands over the audio that is already
/// finished, instead of rebuilding it from source segments that may be gone.
///
/// Slice 2 made the sweep offer sessions on the strength of their anchor alone,
/// and those are exactly the ones whose segments the fire-and-forget deletions
/// already removed. Every case here seeds a real session row and real files,
/// runs the real `save`/`discard`, and observes which audio the person ends up
/// with and what is left in the database and on disk — never how the choice was
/// made internally.
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
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    docs = await Directory.systemTemp.createTemp('eng420_slice3_');

    // The anchor is resolved by basename in the current documents directory,
    // so the production lookup has to land in this temp directory too.
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
  });

  tearDown(() async {
    container.dispose();
    await db.close();
    if (docs.existsSync()) docs.deleteSync(recursive: true);
  });

  String anchorFor(String sessionId) => '${docs.path}/recording_$sessionId.m4a';

  /// A crashed session sitting in the recovery banner. [segmentsOnDisk] says
  /// whether the source segments survived; [anchorFileExists] whether the
  /// finalized audio the row points at is still there.
  Future<void> seedCrashedSession(
    String sessionId, {
    String? anchorPath,
    bool anchorFileExists = true,
    bool segmentsOnDisk = false,
    int segmentCount = 1,
  }) async {
    final paths = <String>[];
    for (var i = 0; i < segmentCount; i++) {
      final path = SegmentPaths.forSegment(docs.path, sessionId, i);
      paths.add(path);
      if (segmentsOnDisk) await File(path).writeAsString('segment $i');
    }
    await sessions.insertSession(
      RecordingSessionsCompanion.insert(
        id: sessionId,
        projectId: 'proj-1',
        genreId: 'genre-1',
        startedAt: DateTime(2026, 8, 12),
        status: const Value('active'),
        segmentPathsJson: Value(jsonEncode(paths)),
        totalDurationSeconds: const Value(1080.0),
        lastSegmentIndex: Value(segmentCount - 1),
      ),
    );
    if (anchorPath != null) {
      if (anchorFileExists) {
        await File(anchorPath).writeAsString('finished audio');
      }
      // Reached through the repository call production uses, so the row is
      // built the way production builds it.
      await sessions.completeWithFinalizedAudio(
        sessionId,
        filePath: anchorPath,
        durationSeconds: 1080.0,
      );
    }
    await sessions.markCrashed(sessionId);
  }

  InterruptedSessionsNotifier notifier() =>
      container.read(interruptedSessionsNotifierProvider.notifier);

  group('ENG-420: recovery reuses the finished audio', () {
    test('a session whose sources are gone is recovered from the finished '
        'file', () async {
      // The silent-loss case slice 2 surfaces: 18 minutes of finished audio on
      // disk and not one source segment left to rebuild from.
      await seedCrashedSession('sess-gone', anchorPath: anchorFor('sess-gone'));

      final result = await notifier().save('sess-gone');

      expect(result, isNotNull);
      expect(result!.filePath, anchorFor('sess-gone'));
      expect(result.durationSeconds, 1080.0);
      expect(File(anchorFor('sess-gone')).existsSync(), isTrue);
    });

    test('a session with sources and no finished file is still rebuilt from '
        'the sources', () async {
      // The path that has always existed, and the one that is right when the
      // original finalization failed: there is no finished file to trust.
      await seedCrashedSession('sess-sources', segmentsOnDisk: true);

      final result = await notifier().save('sess-sources');

      expect(result, isNotNull);
      expect(
        result!.filePath,
        SegmentPaths.forSegment(docs.path, 'sess-sources', 0),
      );
    });

    test('with both available the finished file wins', () async {
      await seedCrashedSession(
        'sess-both',
        anchorPath: anchorFor('sess-both'),
        segmentsOnDisk: true,
      );

      final result = await notifier().save('sess-both');

      expect(result!.filePath, anchorFor('sess-both'));
      expect(
        result.filePath,
        isNot(SegmentPaths.forSegment(docs.path, 'sess-both', 0)),
      );
    });

    test('an anchor pointing at a file that is gone falls back to the '
        'sources', () async {
      // The anchor is a pointer, not a guarantee: discarding from the save
      // form deletes the audio and never touches the row.
      await seedCrashedSession(
        'sess-rotten',
        anchorPath: anchorFor('sess-rotten'),
        anchorFileExists: false,
        segmentsOnDisk: true,
      );

      final result = await notifier().save('sess-rotten');

      expect(result, isNotNull);
      expect(
        result!.filePath,
        SegmentPaths.forSegment(docs.path, 'sess-rotten', 0),
      );
    });

    test(
      'when neither path yields audio the session stays reachable',
      () async {
        // Nothing to hand over, but the row must not land in a status no sweep
        // queries — that would put it out of reach for good.
        await seedCrashedSession(
          'sess-nothing',
          anchorPath: anchorFor('sess-nothing'),
          anchorFileExists: false,
        );

        final result = await notifier().save('sess-nothing');

        expect(result, isNull);
        expect(
          (await sessions.getById('sess-nothing'))?.status,
          isNot('discarded'),
        );
        expect(
          await sessions.findCrashedSessions(),
          contains(
            isA<RecordingSession>().having((s) => s.id, 'id', 'sess-nothing'),
          ),
        );
      },
    );

    test(
      'discarding on purpose still takes the finished audio with it',
      () async {
        await seedCrashedSession(
          'sess-discard',
          anchorPath: anchorFor('sess-discard'),
          segmentsOnDisk: true,
        );

        await notifier().discard('sess-discard');

        expect(File(anchorFor('sess-discard')).existsSync(), isFalse);
        expect(
          File(
            SegmentPaths.forSegment(docs.path, 'sess-discard', 0),
          ).existsSync(),
          isFalse,
        );
        expect((await sessions.getById('sess-discard'))?.status, 'discarded');
      },
    );
  });
}
