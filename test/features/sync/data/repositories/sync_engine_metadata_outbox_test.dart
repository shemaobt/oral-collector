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
    String? storytellerId,
  }) async {
    await repo.insertRecording(
      LocalRecordingsCompanion(
        id: Value(id),
        projectId: const Value('proj'),
        genreId: Value(genreId),
        subcategoryId: const Value('sub-1'),
        registerId: const Value('reg-1'),
        serverId: Value(serverId),
        storytellerId: Value(storytellerId),
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

  /// ENG-411: the storyteller is the sixth field the drain carries.
  group('the drain carries a change of storyteller', () {
    test('an offline change goes up on its own, alone', () async {
      await seedVerified(storytellerId: 'st-9');
      await repo.markMetadataPending('rec-1', {
        PendingMetadataField.storyteller,
      });

      final (client, log) = patchClient();
      await buildEngine(client).processQueue();

      expect(log.count, 1);
      expect(log.paths.single, '/api/oc/recordings/srv-1');
      expect(log.only, {'storyteller_id': 'st-9'});
      expect((await row()).metadataSyncStatus, MetadataSyncStatus.synced);
      client.close();
    });

    test('a removed storyteller goes up as a clear', () async {
      // A null column would be omitted from the body, and the PATCH would say
      // nothing at all — the server would keep the storyteller the user removed.
      await seedVerified();
      await repo.markMetadataPending('rec-1', {
        PendingMetadataField.storyteller,
      });

      final (client, log) = patchClient();
      await buildEngine(client).processQueue();

      expect(log.only, {'storyteller_id': ''});
      client.close();
    });

    test('an expired session costs the change no budget', () async {
      await seedVerified(storytellerId: 'st-9');
      await repo.markMetadataPending('rec-1', {
        PendingMetadataField.storyteller,
      });

      final (client, _) = patchClient(status: 401);
      await buildEngine(client).processQueue();

      final r = await row();
      expect(r.metadataSyncStatus, MetadataSyncStatus.pending);
      expect(r.metadataRetryCount, 0);
      expect(await repo.getPendingMetadataSyncs(), hasLength(1));
      client.close();
    });

    test('and goes up once the session recovers', () async {
      await seedVerified(storytellerId: 'st-9');
      await repo.markMetadataPending('rec-1', {
        PendingMetadataField.storyteller,
      });

      final (client, log) = patchClient(
        statusByCall: (call) => call == 1 ? 401 : 200,
      );
      final engine = buildEngine(client);
      await engine.processQueue();
      await engine.processQueue();

      expect(log.count, 2);
      expect(log.bodies.last, {'storyteller_id': 'st-9'});
      expect((await row()).metadataSyncStatus, MetadataSyncStatus.synced);
      client.close();
    });
  });

  group('an edit made while the write is in flight', () {
    /// Renames the row mid-request, the way the user does when the drain fires
    /// on reconnect and they are still editing on a shaky link.
    (MockClient, _PatchLog) racingClient(String newTitle) {
      final log = _PatchLog();
      return (
        MockClient((request) async {
          log.paths.add(request.url.path);
          log.bodies.add(jsonDecode(request.body) as Map<String, dynamic>);
          await repo.updateRecording(
            'rec-1',
            LocalRecordingsCompanion(title: Value(newTitle)),
          );
          await repo.markMetadataPending('rec-1', {PendingMetadataField.title});
          return http.Response('{}', 200);
        }),
        log,
      );
    }

    test('stays owed, because the server has the older value', () async {
      // Clearing what was *sent* rather than what is still *unchanged* strands
      // the two apart with nothing left to reconcile them: the server keeps
      // 'Old', the device shows 'Newer', and the row says it owes nothing.
      await seedVerified(title: 'Old');
      await repo.markMetadataPending('rec-1', {PendingMetadataField.title});

      final (client, log) = racingClient('Newer');
      await buildEngine(client).processQueue();

      expect(log.only['title'], 'Old');
      final r = await row();
      expect(r.title, 'Newer');
      expect(decodePendingMetadataFields(r.pendingMetadataJson), {
        PendingMetadataField.title,
      });
      expect(r.metadataSyncStatus, MetadataSyncStatus.pending);
      client.close();
    });

    test('goes up on the next pass, at its newer value', () async {
      await seedVerified(title: 'Old');
      await repo.markMetadataPending('rec-1', {PendingMetadataField.title});
      final (racing, _) = racingClient('Newer');
      await buildEngine(racing).processQueue();
      racing.close();

      final (client, log) = patchClient();
      await buildEngine(client).processQueue();

      expect(log.only['title'], 'Newer');
      expect((await row()).metadataSyncStatus, MetadataSyncStatus.synced);
      client.close();
    });

    test('a field nobody touched mid-flight is still settled', () async {
      // The compare is per field: a racing rename must not keep an unrelated
      // cleaning edit owed and re-sent forever.
      await seedVerified(title: 'Old', cleaningStatus: 'needs_cleaning');
      await repo.markMetadataPending('rec-1', {
        PendingMetadataField.title,
        PendingMetadataField.cleaningStatus,
      });

      final (client, _) = racingClient('Newer');
      await buildEngine(client).processQueue();

      expect(decodePendingMetadataFields((await row()).pendingMetadataJson), {
        PendingMetadataField.title,
      });
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

  group('when the recording is gone from the server', () {
    test('the pendency dies with the row, which is right', () async {
      // The ENG-400 sweep hard-deletes a row whose absence a 404 confirmed. The
      // outbox lives in that row's columns, so it goes too — correctly: there
      // is no recording left to update.
      await seedVerified();
      await repo.markMetadataPending('rec-1', {PendingMetadataField.title});

      await repo.deleteRecording('rec-1');

      expect(await repo.getPendingMetadataSyncs(), isEmpty);
    });

    test('a 404 retires the row instead of retrying forever', () async {
      // If the sweep has not run yet, the drain PATCHes a recording the server
      // no longer has. `updateRecording` reports 404 as a plain unsuccessful
      // write, indistinguishable from a 500, so it spends the budget rather
      // than being read as terminal — bounded, not a leak. See the report: a
      // dedicated terminal read would need the status code on
      // `UpdateRecordingOutcome`, which every caller constructs.
      await seedVerified();
      await repo.markMetadataPending('rec-1', {PendingMetadataField.title});

      final (client, log) = patchClient(status: 404);
      final engine = buildEngine(client);
      for (var i = 0; i < kMaxUploadRetries + 2; i++) {
        await repo.updateRecording(
          'rec-1',
          const LocalRecordingsCompanion(metadataLastRetryAt: Value(null)),
        );
        await engine.processQueue();
      }

      expect(log.count, kMaxUploadRetries);
      expect(
        (await row()).metadataSyncStatus,
        MetadataSyncStatus.failedExhausted,
      );
      expect(await repo.getPendingMetadataSyncs(), isEmpty);
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

    test('Wi-Fi-only does not hold the edit back', () async {
      // The preference exists to keep megabytes of audio off a metered
      // connection; a metadata PATCH is a few hundred bytes. The product
      // decision is "the edit goes up when the connection returns", not "when
      // Wi-Fi returns" — so the edit goes and the audio waits.
      await seedVerified();
      await repo.markMetadataPending('rec-1', {PendingMetadataField.title});
      await repo.insertRecording(
        LocalRecordingsCompanion(
          id: const Value('rec-audio'),
          projectId: const Value('proj'),
          genreId: const Value('genre-1'),
          localFilePath: const Value('/audio/rec-audio.m4a'),
          durationSeconds: const Value(30),
          fileSizeBytes: const Value(1000),
          uploadStatus: const Value('local'),
          recordedAt: Value(DateTime.utc(2026, 5, 1)),
        ),
      );
      when(() => connectivity.isOnWifi).thenAnswer((_) async => false);

      final (client, log) = patchClient();
      await buildEngine(client).processQueue(wifiOnly: true);

      expect(log.count, 1, reason: 'the edit is not what the gate protects');
      expect((await row()).metadataSyncStatus, MetadataSyncStatus.synced);
      // Untouched: had the upload drain run, this row would have left `local`
      // (its audio file does not exist).
      final audio = await row('rec-audio');
      expect(audio.uploadStatus, 'local');
      expect(audio.retryCount, 0);
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
