/// The engine writes the terminal upload statuses, end to end (ENG-377).
///
/// Two failures used to end in a row that the counters call pending and the
/// engine refuses forever: one that spent its retries, and one whose audio file
/// cannot be found. Both left the sync chip lit over a queue that does nothing
/// when tapped, because the badge and the drain disagreed about what "pending"
/// means. Each now ends in a status of its own, outside the queue, where the
/// screen can say what happened and offer the way out.
///
/// These run the real engine against the real repository, so the status one
/// persists and the query the other reads are the same two ends of one wire.
/// The statuses' own query semantics live in
/// `local_recording_repository_conflict_status_test.dart`, and the retry-budget
/// arithmetic in `local_recording_repository_retry_budget_test.dart`.
library;

import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/services.dart' show MethodChannel;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';

import 'package:oral_collector/core/config/upload_retry_policy.dart';
import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/core/network/authenticated_client.dart';
import 'package:oral_collector/features/recording/data/repositories/local_recording_repository.dart';
import 'package:oral_collector/features/storyteller/data/repositories/local_storyteller_repository.dart';
import 'package:oral_collector/features/sync/data/repositories/sync_engine.dart';
import 'package:oral_collector/features/sync/domain/repositories/connectivity_service.dart';

class _MockConnectivity extends Mock implements ConnectivityService {}

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late LocalRecordingRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = LocalRecordingRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('the engine writes them, end to end', () {
    late Directory tempDir;
    late _MockConnectivity connectivity;
    late _MockSecureStorage storage;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('sync_engine_terminal');
      connectivity = _MockConnectivity();
      storage = _MockSecureStorage();
      when(() => connectivity.isOnline).thenAnswer((_) async => true);
      when(
        () => storage.read(key: any(named: 'key')),
      ).thenAnswer((_) async => 'test-token');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    Future<void> insertUploadable(
      String id,
      String localFilePath, {
      String uploadStatus = 'local',
      int retryCount = 0,
    }) async {
      await db
          .into(db.localRecordings)
          .insert(
            LocalRecordingsCompanion.insert(
              id: id,
              projectId: 'proj-1',
              genreId: 'genre-1',
              localFilePath: localFilePath,
              title: const Value('A recording'),
              // Long enough for the create-time description rule (ENG-354), so
              // the pre-flight is not what stops this upload.
              description: const Value(
                'A description with enough substance to be accepted',
              ),
              uploadStatus: Value(uploadStatus),
              retryCount: Value(retryCount),
              recordedAt: DateTime.utc(2026, 5, 1),
            ),
          );
    }

    SyncEngineImpl buildEngine(MockClient httpClient) => SyncEngineImpl(
      recordingRepo: repo,
      storytellerRepo: LocalStorytellerRepository(db),
      connectivity: connectivity,
      client: AuthenticatedClient(client: httpClient, storage: storage),
    );

    test('a permanent refusal leaves the queue for good', () async {
      final file = File('${tempDir.path}/present.m4a')..writeAsBytesSync([0]);
      await insertUploadable('rec-1', file.path);

      var createCalls = 0;
      final httpClient = MockClient((request) async {
        if (request.method == 'POST' &&
            request.url.path == '/api/oc/recordings') {
          createCalls++;
          return http.Response('bad request', 400);
        }
        return http.Response('Not Found', 404);
      });
      final engine = buildEngine(httpClient);

      await engine.processQueue();
      await engine.processQueue();

      expect(
        (await repo.getRecordingById('rec-1'))!.uploadStatus,
        'failed_exhausted',
      );
      expect(await repo.getPendingUploads(), isEmpty);
      expect(createCalls, 1, reason: 'the second pass must not try again');
      httpClient.close();
    });

    test('a recording whose audio is gone leaves the queue for good', () async {
      // _resolveFilePath falls back to the documents directory; point it at an
      // empty one so all three lookups miss, as they do on a device where the
      // file was deleted.
      final docsDir = Directory('${tempDir.path}/docs')..createSync();
      const channel = MethodChannel('plugins.flutter.io/path_provider');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (_) async => docsDir.path);
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

      await insertUploadable('rec-1', '${tempDir.path}/never_written.m4a');

      final httpClient = MockClient(
        (request) async => http.Response('Not Found', 404),
      );
      final engine = buildEngine(httpClient);

      await engine.processQueue();
      await engine.processQueue();

      expect(
        (await repo.getRecordingById('rec-1'))!.uploadStatus,
        'failed_missing_file',
      );
      // The old code left it 'failed' without spending a retry, so it came back
      // here on every pass, forever, and the badge counted it every time.
      expect(await repo.getPendingUploads(), isEmpty);
      httpClient.close();
    });

    test(
      'a failure raised before the row is read still ends the budget',
      () async {
        // Nothing mocks path_provider here, so the documents-directory lookup
        // inside _resolveFilePath throws — a failure raised before the upload has
        // read the row it is retrying. The retry decision must not depend on
        // having got that far, or the last attempt lands on ('failed', ceiling):
        // queued by the counters, refused by the drain, forever.
        await insertUploadable(
          'rec-1',
          '${tempDir.path}/never_written.m4a',
          uploadStatus: 'failed',
          retryCount: kMaxUploadRetries - 1,
        );

        final httpClient = MockClient(
          (request) async => http.Response('Not Found', 404),
        );
        final engine = buildEngine(httpClient);

        await engine.processQueue();

        final row = (await repo.getRecordingById('rec-1'))!;
        expect((
          row.uploadStatus,
          row.retryCount,
        ), isNot(('failed', kMaxUploadRetries)));
        expect(await repo.getPendingUploads(), isEmpty);
        httpClient.close();
      },
    );
  });
}
