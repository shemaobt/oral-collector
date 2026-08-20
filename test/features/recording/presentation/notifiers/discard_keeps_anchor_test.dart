/// ENG-521: audio nobody saved stays reachable, and audio the person asked to
/// delete goes.
///
/// ENG-420 established that a session still holding finalized audio never
/// reaches `discarded` — no sweep queries that status, so a row that lands
/// there takes its recording out of reach for good. Two paths on the session
/// notifier never got the guard: resuming a session whose segments are gone,
/// and abandoning a resumed one. Both wrote the terminal status without ever
/// asking about the anchor.
///
/// Every case seeds a real session row and real files, drives the real public
/// entry point, and observes the two things the person can see: whether the
/// recording is still offered in the unsaved list, and whether its audio is
/// still on disk. None of them asserts which status was written — the guard can
/// change shape without rewriting the tests.
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
import 'package:oral_collector/core/platform/file_ops.dart' as file_ops;
import 'package:oral_collector/features/recording/data/providers.dart';
import 'package:oral_collector/features/recording/data/repositories/recording_session_repository.dart';
import 'package:oral_collector/features/recording/data/services/recovery_coordinator.dart';
import 'package:oral_collector/features/recording/data/services/segment_paths.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/interrupted_sessions_notifier.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recording_session_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory docs;
  late AppDatabase db;
  late RecordingSessionRepository sessions;
  late ProviderContainer container;

  /// Set inside a test to drive a delete that refuses; null keeps the real one.
  Future<void> Function(String path)? deleteOverride;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    docs = await Directory.systemTemp.createTemp('eng521_');

    // The anchor is resolved by basename in the current documents directory,
    // so the production lookup has to land in this temp directory too.
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (_) async => docs.path);
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    db = AppDatabase.forTesting(NativeDatabase.memory());
    sessions = RecordingSessionRepository(db);
    deleteOverride = null;
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        recoveryCoordinatorProvider.overrideWith(
          (ref) =>
              RecoveryCoordinator(ref, directoryResolver: () async => docs),
        ),
        deleteFileProvider.overrideWithValue(
          (path) => (deleteOverride ?? file_ops.deleteFile)(path),
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

  /// A session sitting in the unsaved list. [anchorPath] is the finalized audio
  /// the row points at; [segmentsOnDisk] whether the source segments the
  /// resume would rebuild from survived.
  Future<void> seedCrashedSession(
    String sessionId, {
    String? anchorPath,
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
        startedAt: DateTime(2026, 8, 20),
        status: const Value('active'),
        segmentPathsJson: Value(jsonEncode(paths)),
        totalDurationSeconds: const Value(1080.0),
        lastSegmentIndex: Value(segmentCount - 1),
      ),
    );
    if (anchorPath != null) {
      await File(anchorPath).writeAsString('finished audio');
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

  RecordingSessionNotifier sessionNotifier() =>
      container.read(recordingSessionNotifierProvider.notifier);

  InterruptedSessionsNotifier interruptedNotifier() =>
      container.read(interruptedSessionsNotifierProvider.notifier);

  List<String> unsavedIds() => container
      .read(interruptedSessionsProvider)
      .map((s) => s.sessionId)
      .toList();

  group('ENG-521: discarding keeps audio nobody saved', () {
    test('resuming a session whose segments are gone does not swallow its '
        'audio', () async {
      // The session the startup sweep surfaces: 18 minutes of finished audio on
      // disk and not one source segment left. Tapping "resume" cannot rebuild
      // anything, but the recording has to stay on offer.
      await seedCrashedSession(
        'sess-resume',
        anchorPath: anchorFor('sess-resume'),
      );

      final resumed = await sessionNotifier().loadInterruptedSession(
        'sess-resume',
      );

      expect(resumed, isFalse, reason: 'there is nothing to resume from');
      expect(unsavedIds(), contains('sess-resume'));
      expect(File(anchorFor('sess-resume')).existsSync(), isTrue);
    });

    test('abandoning a resumed session does not swallow its audio', () async {
      // Reaching the abandon path needs a session that could be resumed, so the
      // segments are on disk; what makes it the same case is the anchor the
      // path never reads.
      await seedCrashedSession(
        'sess-abandon',
        anchorPath: anchorFor('sess-abandon'),
        segmentsOnDisk: true,
      );
      expect(
        await sessionNotifier().loadInterruptedSession('sess-abandon'),
        isTrue,
      );

      await sessionNotifier().discardRecording();

      expect(unsavedIds(), contains('sess-abandon'));
      expect(File(anchorFor('sess-abandon')).existsSync(), isTrue);
    });

    test('discarding on purpose still deletes the audio and clears the '
        'session', () async {
      // The net under the fix: the obvious guard — never discard while the
      // anchor column is set — would turn this path into never-discards, and
      // the app would pile up dead sessions nothing ever cleans.
      await seedCrashedSession(
        'sess-discard',
        anchorPath: anchorFor('sess-discard'),
        segmentsOnDisk: true,
      );

      await interruptedNotifier().discard('sess-discard');

      expect(File(anchorFor('sess-discard')).existsSync(), isFalse);
      expect(unsavedIds(), isNot(contains('sess-discard')));
    });

    test('a session holding no audio at all is still cleared', () async {
      // No anchor, no surviving segment: there is nothing to keep reachable,
      // and leaving the row behind would just leak it.
      await seedCrashedSession('sess-empty');

      final resumed = await sessionNotifier().loadInterruptedSession(
        'sess-empty',
      );

      expect(resumed, isFalse);
      expect(unsavedIds(), isNot(contains('sess-empty')));
    });

    test(
      'a delete that fails leaves the session reachable to try again',
      () async {
        await seedCrashedSession(
          'sess-stuck',
          anchorPath: anchorFor('sess-stuck'),
          segmentsOnDisk: true,
        );
        deleteOverride = (path) async =>
            throw const FileSystemException('refused');

        await interruptedNotifier().discard('sess-stuck');

        expect(unsavedIds(), contains('sess-stuck'));
        expect(File(anchorFor('sess-stuck')).existsSync(), isTrue);
      },
    );
  });
}
