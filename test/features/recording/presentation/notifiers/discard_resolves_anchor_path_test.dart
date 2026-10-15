/// ENG-528: the deliberate discard deletes the file the predicate can see.
///
/// `discard()` used to delete by the **stored** anchor path and then ask a
/// predicate that resolves by **basename** in the current documents directory.
/// When the app container moves — reinstall or restore on iOS, the case
/// `resolveRecordingPath` exists for — the stored path stops resolving, the
/// delete finds nothing and does not throw, the predicate finds the file, and
/// the terminal status is never written. No audio is lost; deleting becomes
/// impossible.
///
/// Every case seeds a real row and real files in a temp directory, drives the
/// public discard, and looks at the disk and at the unsaved list. None asserts
/// which path was used internally.
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
import 'package:oral_collector/features/recording/data/services/recovery_disk.dart';
import 'package:oral_collector/features/recording/data/services/segment_paths.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/interrupted_sessions_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory docs;
  late AppDatabase db;
  late RecordingSessionRepository sessions;
  late Set<String> undeletable;
  late ProviderContainer container;

  /// The container the app ran under before it was reinstalled or restored.
  /// It does not exist any more, which is the whole point.
  const oldContainer = '/var/mobile/Containers/Data/Application/OLD-UUID/docs';

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    docs = await Directory.systemTemp.createTemp('eng528_discard_');

    const channel = MethodChannel('plugins.flutter.io/path_provider');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (_) async => docs.path);
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    db = AppDatabase.forTesting(NativeDatabase.memory());
    sessions = RecordingSessionRepository(db);
    undeletable = <String>{};
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        recoveryCoordinatorProvider.overrideWith(
          (ref) => RecoveryCoordinator(
            ref,
            disk: RecoveryDisk(documentsPath: () async => docs.path),
          ),
        ),
        deleteFileProvider.overrideWithValue((path) async {
          if (undeletable.contains(path)) {
            throw const FileSystemException('refusing to delete');
          }
          await file_ops.deleteFile(path);
        }),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
    if (docs.existsSync()) docs.deleteSync(recursive: true);
  });

  String basenameFor(String sessionId) => 'recording_$sessionId.m4a';
  String liveAudioFor(String sessionId) =>
      '${docs.path}/${basenameFor(sessionId)}';

  /// A session sitting in the unsaved list on the strength of its finalized
  /// audio, with its source segments still around. [storedAnchorDir] is where
  /// the row *says* the audio is; the file itself is always written under the
  /// current documents directory, which is where the app would find it today.
  Future<void> seedUnsavedSession(
    String sessionId, {
    required String storedAnchorDir,
    int segmentCount = 2,
  }) async {
    final paths = <String>[];
    for (var i = 0; i < segmentCount; i++) {
      final path = SegmentPaths.forSegment(docs.path, sessionId, i);
      await File(path).writeAsString('segment $i');
      paths.add(path);
    }
    await sessions.insertSession(
      RecordingSessionsCompanion.insert(
        id: sessionId,
        projectId: 'proj-1',
        genreId: 'genre-1',
        subcategoryId: const Value('sub-1'),
        startedAt: DateTime(2026, 8, 12),
        segmentPathsJson: Value(jsonEncode(paths)),
        totalDurationSeconds: Value(segmentCount.toDouble()),
        lastSegmentIndex: Value(segmentCount - 1),
      ),
    );
    await File(liveAudioFor(sessionId)).writeAsString('finalized audio');
    await sessions.completeWithFinalizedAudio(
      sessionId,
      filePath: '$storedAnchorDir/${basenameFor(sessionId)}',
      durationSeconds: segmentCount.toDouble(),
    );
    await sessions.markCrashed(sessionId);
  }

  Future<List<String>> offered() async {
    await container.read(recoveryCoordinatorProvider).refresh();
    return container
        .read(interruptedSessionsProvider)
        .map((s) => s.sessionId)
        .toList();
  }

  Future<void> discard(String sessionId) => container
      .read(interruptedSessionsNotifierProvider.notifier)
      .discard(sessionId);

  group('ENG-528: discarding deletes the file the predicate sees', () {
    test(
      'a stored anchor path from a moved container still gets deleted',
      () async {
        await seedUnsavedSession('sess-moved', storedAnchorDir: oldContainer);
        expect(await offered(), contains('sess-moved'));

        await discard('sess-moved');

        expect(
          File(liveAudioFor('sess-moved')).existsSync(),
          isFalse,
          reason: 'the person asked for the audio to go',
        );
        expect(await offered(), isNot(contains('sess-moved')));
      },
    );

    test(
      'a stored anchor path that still resolves literally is unaffected',
      () async {
        await seedUnsavedSession('sess-normal', storedAnchorDir: docs.path);
        expect(await offered(), contains('sess-normal'));

        await discard('sess-normal');

        expect(File(liveAudioFor('sess-normal')).existsSync(), isFalse);
        expect(await offered(), isNot(contains('sess-normal')));
      },
    );

    test(
      'a delete that genuinely fails still leaves the session in the list',
      () async {
        // The ENG-521 guarantee: the terminal status waits on the deletion
        // having worked. Only the anchor refuses here, so the segments go and
        // the anchor is the sole reason the session survives.
        await seedUnsavedSession('sess-stuck', storedAnchorDir: docs.path);
        undeletable.add(liveAudioFor('sess-stuck'));

        await discard('sess-stuck');

        expect(File(liveAudioFor('sess-stuck')).existsSync(), isTrue);
        expect(await offered(), contains('sess-stuck'));
      },
    );

    test(
      'pressing discard twice converges instead of doing nothing twice',
      () async {
        // The symptom the person would report: pressing discard and nothing
        // happening, over and over.
        await seedUnsavedSession('sess-twice', storedAnchorDir: oldContainer);

        await discard('sess-twice');
        await discard('sess-twice');

        expect(File(liveAudioFor('sess-twice')).existsSync(), isFalse);
        expect(await offered(), isNot(contains('sess-twice')));
      },
    );
  });
}
