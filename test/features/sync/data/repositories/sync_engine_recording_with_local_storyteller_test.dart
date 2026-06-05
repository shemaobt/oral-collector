import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/core/network/authenticated_client.dart';
import 'package:oral_collector/features/recording/data/repositories/local_recording_repository.dart';
import 'package:oral_collector/features/storyteller/data/repositories/local_storyteller_repository.dart';
import 'package:oral_collector/features/storyteller/domain/entities/storyteller.dart';
import 'package:oral_collector/features/sync/data/repositories/sync_engine.dart';
import 'package:oral_collector/features/sync/domain/repositories/connectivity_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockConnectivity extends Mock implements ConnectivityService {}

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late LocalStorytellerRepository storytellerRepo;
  late LocalRecordingRepository recordingRepo;
  late MockConnectivity mockConnectivity;
  late MockSecureStorage mockStorage;
  late Directory tempDir;

  setUpAll(() {
    dotenv.testLoad(fileInput: 'BACKEND_URL=http://localhost:8080');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    storytellerRepo = LocalStorytellerRepository(db);
    recordingRepo = LocalRecordingRepository(db);
    mockConnectivity = MockConnectivity();
    mockStorage = MockSecureStorage();
    tempDir = Directory.systemTemp.createTempSync('storyteller_recon_test');

    when(() => mockConnectivity.isOnline).thenAnswer((_) async => true);
    when(() => mockConnectivity.isOnWifi).thenAnswer((_) async => true);
    when(
      () => mockStorage.read(key: any(named: 'key')),
    ).thenAnswer((_) async => 'test-token');
  });

  tearDown(() async {
    tempDir.deleteSync(recursive: true);
    await db.close();
  });

  Future<void> seedLocalStoryteller(String id) async {
    await storytellerRepo.insertLocal(
      Storyteller(
        id: id,
        projectId: 'proj-1',
        name: 'Pendente $id',
        sex: StorytellerSex.male,
        externalAcceptanceConfirmed: true,
        createdAt: DateTime(2026, 1, 1),
      ),
      syncStatus: 'local',
    );
  }

  Future<File> seedRecordingWithStoryteller({
    required String recordingId,
    required String storytellerLocalId,
  }) async {
    final f = File('${tempDir.path}/$recordingId.m4a');
    f.writeAsBytesSync(Uint8List(1024));

    await recordingRepo.insertRecording(
      LocalRecordingsCompanion(
        id: Value(recordingId),
        projectId: const Value('proj-1'),
        genreId: const Value('g-1'),
        title: const Value('Rec'),
        durationSeconds: const Value(10.0),
        fileSizeBytes: const Value(1024),
        format: const Value('m4a'),
        localFilePath: Value(f.path),
        uploadStatus: const Value('local'),
        storytellerId: Value(storytellerLocalId),
        recordedAt: Value(DateTime(2026, 1, 1)),
      ),
    );
    return f;
  }

  SyncEngineImpl buildEngine(MockClient httpClient) {
    final authClient = AuthenticatedClient(
      client: httpClient,
      storage: mockStorage,
    );
    return SyncEngineImpl(
      recordingRepo: recordingRepo,
      storytellerRepo: storytellerRepo,
      connectivity: mockConnectivity,
      client: authClient,
    );
  }

  test(
    'recording payload uses server id when storyteller syncs first',
    () async {
      const localId = 'stl_pending_1';
      await seedLocalStoryteller(localId);
      await seedRecordingWithStoryteller(
        recordingId: 'rec_with_local',
        storytellerLocalId: localId,
      );

      String? storytellerIdInPayload;

      final httpClient = MockClient((request) async {
        final path = request.url.path;

        if (request.method == 'POST' &&
            path == '/api/oc/projects/proj-1/storytellers') {
          return http.Response(
            jsonEncode({
              'id': 'srv-RECONCILED',
              'project_id': 'proj-1',
              'name': 'Pendente $localId',
              'sex': 'male',
              'external_acceptance_confirmed': true,
              'created_at': DateTime(2026, 1, 1).toIso8601String(),
            }),
            201,
          );
        }

        if (request.method == 'POST' && path == '/api/oc/recordings') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          storytellerIdInPayload = body['storyteller_id'] as String?;
          return http.Response(jsonEncode({'id': 'srv-rec-1'}), 201);
        }

        if (request.method == 'POST' &&
            path == '/api/oc/recordings/upload-url') {
          return http.Response(
            jsonEncode({
              'upload_url': 'https://storage.googleapis.com/test',
              'content_type': 'audio/mp4',
            }),
            200,
          );
        }

        if (request.url.host == 'storage.googleapis.com') {
          return http.Response('', 200);
        }

        if (request.method == 'POST' && path.contains('/confirm-upload')) {
          return http.Response(
            jsonEncode({'gcs_url': 'https://example/file'}),
            200,
          );
        }

        return http.Response('Not Found', 404);
      });

      final engine = buildEngine(httpClient);
      await engine.processQueue();

      expect(
        storytellerIdInPayload,
        'srv-RECONCILED',
        reason:
            'recording must reference the server-assigned id, not the local id',
      );

      httpClient.close();
    },
  );

  test(
    'recording.storytellerId is rewritten in local DB after storyteller sync',
    () async {
      const localId = 'stl_to_be_rewritten';
      await seedLocalStoryteller(localId);
      await seedRecordingWithStoryteller(
        recordingId: 'rec_rewrite',
        storytellerLocalId: localId,
      );

      final httpClient = MockClient((request) async {
        final path = request.url.path;

        if (request.method == 'POST' &&
            path == '/api/oc/projects/proj-1/storytellers') {
          return http.Response(
            jsonEncode({
              'id': 'srv-REWRITTEN',
              'project_id': 'proj-1',
              'name': 'Pendente $localId',
              'sex': 'male',
              'external_acceptance_confirmed': true,
              'created_at': DateTime(2026, 1, 1).toIso8601String(),
            }),
            201,
          );
        }
        if (request.method == 'POST' && path == '/api/oc/recordings') {
          return http.Response(jsonEncode({'id': 'srv-rec'}), 201);
        }
        if (request.method == 'POST' &&
            path == '/api/oc/recordings/upload-url') {
          return http.Response(
            jsonEncode({
              'upload_url': 'https://storage.googleapis.com/test',
              'content_type': 'audio/mp4',
            }),
            200,
          );
        }
        if (request.url.host == 'storage.googleapis.com') {
          return http.Response('', 200);
        }
        if (request.method == 'POST' && path.contains('/confirm-upload')) {
          return http.Response(
            jsonEncode({'gcs_url': 'https://example/file'}),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final engine = buildEngine(httpClient);
      await engine.processQueue();

      final updatedRec = await recordingRepo.getRecordingById('rec_rewrite');
      expect(
        updatedRec?.storytellerId,
        'srv-REWRITTEN',
        reason:
            'after storyteller sync, recordings pointing to the local id must '
            'be rewritten so future fetches of the recording dont reference '
            'a stale local id',
      );

      httpClient.close();
    },
  );

  test(
    'recording is skipped when its storyteller failed to sync this round',
    () async {
      const localId = 'stl_will_fail';
      await seedLocalStoryteller(localId);
      await seedRecordingWithStoryteller(
        recordingId: 'rec_blocked',
        storytellerLocalId: localId,
      );

      var recordingCreateCalls = 0;

      final httpClient = MockClient((request) async {
        final path = request.url.path;

        if (request.method == 'POST' &&
            path == '/api/oc/projects/proj-1/storytellers') {
          return http.Response('boom', 500);
        }

        if (request.method == 'POST' && path == '/api/oc/recordings') {
          recordingCreateCalls++;
          return http.Response(jsonEncode({'id': 'srv-rec-x'}), 201);
        }

        if (request.method == 'POST' &&
            path == '/api/oc/recordings/upload-url') {
          return http.Response(
            jsonEncode({
              'upload_url': 'https://storage.googleapis.com/test',
              'content_type': 'audio/mp4',
            }),
            200,
          );
        }

        if (request.url.host == 'storage.googleapis.com') {
          return http.Response('', 200);
        }

        if (request.method == 'POST' && path.contains('/confirm-upload')) {
          return http.Response(
            jsonEncode({'gcs_url': 'https://example/file'}),
            200,
          );
        }

        return http.Response('Not Found', 404);
      });

      final engine = buildEngine(httpClient);
      await engine.processQueue();

      expect(
        recordingCreateCalls,
        0,
        reason:
            'recording referencing an unsynced local storyteller must NOT call recording-create',
      );

      httpClient.close();
    },
  );
}
