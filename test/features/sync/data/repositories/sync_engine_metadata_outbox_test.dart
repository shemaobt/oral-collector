/// The metadata outbox drains itself (ENG-403).
///
/// An edit made offline was written to the local row (ENG-399) and stopped
/// there forever: no queue carried it, so the only way it ever reached the
/// server was the user redoing it online. `processQueue` now drains it as a
/// third queue alongside storytellers and uploads, on the same reconnect hook.
///
/// These run the real engine against the real repository over an in-memory
/// database, so what the notifier marks and what the drain selects are the two
/// ends of one wire. The PATCH body is read off the wire rather than a fake,
/// because "only the fields this device touched" is a statement about the wire.
library;

import 'dart:convert';

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
import 'package:oral_collector/features/recording/domain/entities/pending_metadata_field.dart';
import 'package:oral_collector/features/storyteller/data/repositories/local_storyteller_repository.dart';
import 'package:oral_collector/features/sync/data/repositories/sync_engine.dart';
import 'package:oral_collector/features/sync/domain/repositories/connectivity_service.dart';

import '../../../../support/sync_engine_api.dart';

class _MockConnectivity extends Mock implements ConnectivityService {}

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

/// Every PATCH the drain issued, as decoded bodies keyed in call order.
class _PatchLog {
  final List<Map<String, dynamic>> bodies = [];
  final List<String> paths = [];

  int get count => bodies.length;
  Map<String, dynamic> get only => bodies.single;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late LocalRecordingRepository repo;
  late _MockConnectivity connectivity;
  late _MockSecureStorage storage;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = LocalRecordingRepository(db);
    connectivity = _MockConnectivity();
    storage = _MockSecureStorage();
    when(() => connectivity.isOnline).thenAnswer((_) async => true);
    when(() => connectivity.isOnWifi).thenAnswer((_) async => true);
    when(
      () => storage.read(key: any(named: 'key')),
    ).thenAnswer((_) async => 'test-token');
  });
  tearDown(() => db.close());

  Future<void> seedVerified({
    String id = 'rec-1',
    String serverId = 'srv-1',
    String title = 'Story',
    String cleaningStatus = 'none',
    String genreId = 'genre-1',
  }) async {
    await repo.insertRecording(
      LocalRecordingsCompanion(
        id: Value(id),
        projectId: const Value('proj'),
        genreId: Value(genreId),
        subcategoryId: const Value('sub-1'),
        registerId: const Value('reg-1'),
        serverId: Value(serverId),
        title: Value(title),
        description: const Value('a description with enough substance'),
        durationSeconds: const Value(30),
        fileSizeBytes: const Value(1000),
        localFilePath: Value('/audio/$id.m4a'),
        uploadStatus: const Value('verified'),
        cleaningStatus: Value(cleaningStatus),
        recordedAt: Value(DateTime.utc(2026, 5, 1)),
      ),
    );
  }

  /// A client that answers every PATCH with [status] and records what it saw.
  /// Anything else 404s, so a stray call is visible rather than absorbed.
  (MockClient, _PatchLog) patchClient({
    int status = 200,
    String body = '{}',
    int Function(int call)? statusByCall,
  }) {
    final log = _PatchLog();
    final client = MockClient((request) async {
      if (request.method != 'PATCH') {
        return http.Response('Not Found', 404);
      }
      log.paths.add(request.url.path);
      log.bodies.add(jsonDecode(request.body) as Map<String, dynamic>);
      final code = statusByCall?.call(log.count) ?? status;
      return http.Response(code == 200 ? body : 'error', code);
    });
    return (client, log);
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

  Future<LocalRecording> row([String id = 'rec-1']) async =>
      (await repo.getRecordingById(id))!;

  group('the drain carries an edit the server never got', () {
    test('an edit made offline goes up on its own', () async {
      await seedVerified(cleaningStatus: 'needs_cleaning');
      await repo.markMetadataPending('rec-1', {
        PendingMetadataField.cleaningStatus,
      });

      final (client, log) = patchClient();
      await buildEngine(client).processQueue();

      expect(log.count, 1);
      expect(log.paths.single, '/api/oc/recordings/srv-1');
      expect(log.only['cleaning_status'], 'needs_cleaning');
      client.close();
    });

    test('sends only the fields this device touched', () async {
      // The row also holds a title, a genre and a description. Sending them
      // would overwrite another device's edits with values nobody changed —
      // there is no ETag on this endpoint, so the only defence is a narrow body.
      await seedVerified(cleaningStatus: 'needs_cleaning', title: 'Old Title');
      await repo.markMetadataPending('rec-1', {
        PendingMetadataField.cleaningStatus,
      });

      final (client, log) = patchClient();
      await buildEngine(client).processQueue();

      expect(log.only.keys, ['cleaning_status']);
      client.close();
    });

    test('reads the latest value, so two edits go up as one', () async {
      await seedVerified(cleaningStatus: 'none');
      await repo.markMetadataPending('rec-1', {
        PendingMetadataField.cleaningStatus,
      });
      await repo.updateCleaningStatus('rec-1', 'needs_cleaning');
      await repo.markMetadataPending('rec-1', {
        PendingMetadataField.cleaningStatus,
      });

      final (client, log) = patchClient();
      await buildEngine(client).processQueue();

      expect(log.count, 1);
      expect(log.only['cleaning_status'], 'needs_cleaning');
      client.close();
    });

    test('a cleared secondary classification goes up as a clear', () async {
      // All three secondary columns are null, which on this endpoint can only
      // be said with the explicit-null form.
      await seedVerified();
      await repo.markMetadataPending('rec-1', {PendingMetadataField.secondary});

      final (client, log) = patchClient();
      await buildEngine(client).processQueue();

      expect(log.only, {
        'secondary_genre_id': null,
        'secondary_subcategory_id': null,
        'secondary_register_id': null,
      });
      client.close();
    });

    test('stops owing it once it lands, and never resends', () async {
      await seedVerified(cleaningStatus: 'needs_cleaning');
      await repo.markMetadataPending('rec-1', {
        PendingMetadataField.cleaningStatus,
      });

      final (client, log) = patchClient();
      final engine = buildEngine(client);
      await engine.processQueue();
      await engine.processQueue();

      expect(log.count, 1, reason: 'the second pass has nothing to send');
      expect((await row()).metadataSyncStatus, MetadataSyncStatus.synced);
      expect((await row()).pendingMetadataJson, '[]');
      expect(await repo.getPendingMetadataSyncs(), isEmpty);
      client.close();
    });

    test('stores what the server says the recording still owes', () async {
      await seedVerified();
      await repo.markMetadataPending('rec-1', {PendingMetadataField.title});

      final (client, _) = patchClient(
        body: jsonEncode({
          'review_flags': [
            {'code': 'insufficient_description', 'origin': 'server'},
          ],
        }),
      );
      await buildEngine(client).processQueue();

      expect(
        (await row()).reviewFlagsJson,
        contains('insufficient_description'),
      );
      client.close();
    });
  });

  group('what ends the attempt for good', () {
    test('a permission refusal is terminal', () async {
      await seedVerified();
      await repo.markMetadataPending('rec-1', {
        PendingMetadataField.cleaningStatus,
      });

      final (client, log) = patchClient(status: 403);
      final engine = buildEngine(client);
      await engine.processQueue();
      await engine.processQueue();

      expect(
        (await row()).metadataSyncStatus,
        MetadataSyncStatus.failedForbidden,
      );
      expect(log.count, 1, reason: 'insisting cannot grant permission');
      expect(await repo.getPendingMetadataSyncs(), isEmpty);
      client.close();
    });

    test('a title clash parks the row where a rename can free it', () async {
      await seedVerified();
      await repo.markMetadataPending('rec-1', {PendingMetadataField.title});

      final (client, log) = patchClient(status: 409);
      final engine = buildEngine(client);
      await engine.processQueue();
      await engine.processQueue();

      expect(
        (await row()).metadataSyncStatus,
        MetadataSyncStatus.failedConflict,
      );
      expect(log.count, 1);
      client.close();
    });

    test('a spent budget retires the row', () async {
      await seedVerified();
      await repo.markMetadataPending('rec-1', {PendingMetadataField.title});

      final (client, log) = patchClient(status: 500);
      final engine = buildEngine(client);
      for (var i = 0; i < kMaxUploadRetries; i++) {
        // Each pass would otherwise be refused by its own backoff window; the
        // point here is the budget, not the wait.
        await repo.updateRecording(
          'rec-1',
          const LocalRecordingsCompanion(metadataLastRetryAt: Value(null)),
        );
        await engine.processQueue();
      }

      expect(
        (await row()).metadataSyncStatus,
        MetadataSyncStatus.failedExhausted,
      );
      expect(log.count, kMaxUploadRetries);
      expect(await repo.getPendingMetadataSyncs(), isEmpty);
      // The edit itself is kept — the user typed it, and the screen reads the
      // row to say what is stuck.
      expect(decodePendingMetadataFields((await row()).pendingMetadataJson), {
        PendingMetadataField.title,
      });
      client.close();
    });
  });

  group('what only postpones it', () {
    test('an expired session costs the edit no budget', () async {
      // The token can still refresh; charging this to the edit would burn a
      // budget that has nothing to do with it, and 401 is how _pushMetadata
      // reports an unreachable server in the first place.
      await seedVerified();
      await repo.markMetadataPending('rec-1', {PendingMetadataField.title});

      final (client, _) = patchClient(status: 401);
      await buildEngine(client).processQueue();

      final r = await row();
      expect(r.metadataSyncStatus, MetadataSyncStatus.pending);
      expect(r.metadataRetryCount, 0);
      expect(await repo.getPendingMetadataSyncs(), hasLength(1));
      client.close();
    });

    test('a session that recovers lets the edit through', () async {
      await seedVerified();
      await repo.markMetadataPending('rec-1', {PendingMetadataField.title});

      final (client, log) = patchClient(
        statusByCall: (call) => call == 1 ? 401 : 200,
      );
      final engine = buildEngine(client);
      await engine.processQueue();
      await engine.processQueue();

      expect(log.count, 2);
      expect((await row()).metadataSyncStatus, MetadataSyncStatus.synced);
      client.close();
    });

    test('a server error spends one retry and then backs off', () async {
      await seedVerified();
      await repo.markMetadataPending('rec-1', {PendingMetadataField.title});

      final (client, log) = patchClient(status: 500);
      final engine = buildEngine(client);
      await engine.processQueue();
      // Immediately again: the row is inside its backoff window, so the drain
      // must leave it alone rather than hammer the server.
      await engine.processQueue();

      final r = await row();
      expect(r.metadataSyncStatus, MetadataSyncStatus.pending);
      expect(r.metadataRetryCount, 1);
      expect(log.count, 1);
      client.close();
    });

    test('an offline pass sends nothing and keeps the edit owed', () async {
      await seedVerified();
      await repo.markMetadataPending('rec-1', {PendingMetadataField.title});
      when(() => connectivity.isOnline).thenAnswer((_) async => false);

      final (client, log) = patchClient();
      await buildEngine(client).processQueue();

      expect(log.count, 0);
      expect((await row()).metadataSyncStatus, MetadataSyncStatus.pending);
      client.close();
    });
  });
}
