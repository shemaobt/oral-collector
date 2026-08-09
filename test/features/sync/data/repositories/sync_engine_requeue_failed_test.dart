/// Requeueing a failed upload actually gets it attempted again (ENG-404).
///
/// The recordings list used to answer a failed upload by deleting it, which
/// destroyed the only copy of audio the server never received. It now hands the
/// row back to the queue instead — and "back in the queue" is only worth
/// anything if the drain then picks it up, so these run the real engine against
/// the real repository rather than asserting on the three columns in isolation.
///
/// Both cases are blocked for a different reason before the requeue:
/// `failed_exhausted` is not selected by `getPendingUploads` at all, and a
/// `failed` row that just failed is selected but skipped by the backoff window.
/// The upload is answered with a 400 on purpose — proving the attempt happened
/// is the point; a happy path would only add plumbing.
library;

import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
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

import '../../../../support/sync_engine_api.dart';

class _MockConnectivity extends Mock implements ConnectivityService {}

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late LocalRecordingRepository repo;
  late Directory tempDir;
  late _MockConnectivity connectivity;
  late _MockSecureStorage storage;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = LocalRecordingRepository(db);
    tempDir = Directory.systemTemp.createTempSync('sync_engine_requeue');
    connectivity = _MockConnectivity();
    storage = _MockSecureStorage();
    when(() => connectivity.isOnline).thenAnswer((_) async => true);
    when(
      () => storage.read(key: any(named: 'key')),
    ).thenAnswer((_) async => 'test-token');
  });

  tearDown(() async {
    await db.close();
    tempDir.deleteSync(recursive: true);
  });

  Future<void> insertUploadable(
    String id,
    String localFilePath, {
    required String uploadStatus,
    required int retryCount,
    DateTime? lastRetryAt,
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
            lastRetryAt: Value(lastRetryAt),
            recordedAt: DateTime.utc(2026, 5, 1),
          ),
        );
  }

  /// Counts create attempts and refuses them, so an attempt is observable
  /// without standing up the upload/confirm legs.
  ({MockClient client, int Function() creates}) countingClient() {
    var creates = 0;
    final client = MockClient((request) async {
      if (request.method == 'POST' &&
          request.url.path == '/api/oc/recordings') {
        creates++;
        return http.Response('bad request', 400);
      }
      return http.Response('Not Found', 404);
    });
    return (client: client, creates: () => creates);
  }

  SyncEngineImpl buildEngine(MockClient httpClient) {
    final authClient = AuthenticatedClient(
      client: httpClient,
      storage: storage,
    );
    return SyncEngineImpl(
      recordingRepo: repo,
      storytellerRepo: LocalStorytellerRepository(db),
      connectivity: connectivity,
      client: authClient,
      recordingApi: apiRepoFor(authClient),
    );
  }

  test('a spent-budget recording is attempted again once requeued', () async {
    final file = File('${tempDir.path}/exhausted.m4a')..writeAsBytesSync([0]);
    await insertUploadable(
      'rec-1',
      file.path,
      uploadStatus: 'failed_exhausted',
      retryCount: kMaxUploadRetries,
    );
    final probe = countingClient();
    final engine = buildEngine(probe.client);

    await engine.processQueue();
    expect(
      probe.creates(),
      0,
      reason: 'failed_exhausted is out of the queue on its own',
    );

    await repo.requeueFailedUploads('proj-1');
    await engine.processQueue();

    expect(probe.creates(), 1);
    expect(
      await repo.getRecordingById('rec-1'),
      isNotNull,
      reason: 'the row survives the action that used to delete it',
    );
    expect(file.existsSync(), isTrue, reason: 'and so does its audio');
    probe.client.close();
  });

  test('a failed recording is unstuck from its backoff window', () async {
    final file = File('${tempDir.path}/backing-off.m4a')..writeAsBytesSync([0]);
    await insertUploadable(
      'rec-1',
      file.path,
      uploadStatus: 'failed',
      retryCount: 1,
      lastRetryAt: DateTime.now(),
    );
    final probe = countingClient();
    final engine = buildEngine(probe.client);

    await engine.processQueue();
    expect(probe.creates(), 0, reason: 'still inside the backoff window');

    await repo.requeueFailedUploads('proj-1');
    await engine.processQueue();

    expect(probe.creates(), 1);
    expect(await repo.getRecordingById('rec-1'), isNotNull);
    expect(file.existsSync(), isTrue);
    probe.client.close();
  });
}
