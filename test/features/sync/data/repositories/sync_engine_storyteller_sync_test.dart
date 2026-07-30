import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
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

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    storytellerRepo = LocalStorytellerRepository(db);
    recordingRepo = LocalRecordingRepository(db);
    mockConnectivity = MockConnectivity();
    mockStorage = MockSecureStorage();
    tempDir = Directory.systemTemp.createTempSync('sync_storyteller_test');

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

  Storyteller makeStoryteller({
    String id = 'stl_local_1',
    String projectId = 'proj-1',
    String name = 'João',
  }) {
    return Storyteller(
      id: id,
      projectId: projectId,
      name: name,
      sex: StorytellerSex.male,
      externalAcceptanceConfirmed: true,
      createdAt: DateTime(2026, 1, 1),
    );
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

  group('storyteller sync', () {
    test(
      'pending storyteller is POSTed and gets serverId on success',
      () async {
        await storytellerRepo.insertLocal(
          makeStoryteller(id: 'stl_pending', name: 'João'),
          syncStatus: 'local',
        );

        final receivedBodies = <Map<String, dynamic>>[];
        final httpClient = MockClient((request) async {
          if (request.method == 'POST' &&
              request.url.path == '/api/oc/projects/proj-1/storytellers') {
            receivedBodies.add(
              jsonDecode(request.body) as Map<String, dynamic>,
            );
            return http.Response(
              jsonEncode({
                'id': 'srv-storyteller-1',
                'project_id': 'proj-1',
                'name': 'João',
                'sex': 'male',
                'external_acceptance_confirmed': true,
                'created_at': DateTime(2026, 1, 1).toIso8601String(),
              }),
              201,
            );
          }
          return http.Response('Not Found', 404);
        });

        final engine = buildEngine(httpClient);
        await engine.processQueue();

        expect(receivedBodies.length, 1);
        expect(receivedBodies.single['name'], 'João');

        final pendingAfter = await storytellerRepo.getPendingSyncs();
        expect(pendingAfter, isEmpty);

        final all = await storytellerRepo.getByProject('proj-1');
        expect(all.length, 1);

        httpClient.close();
      },
    );

    test('storyteller sync runs BEFORE recording uploads', () async {
      await storytellerRepo.insertLocal(
        makeStoryteller(id: 'stl_first', name: 'First'),
        syncStatus: 'local',
      );

      final testFile = File('${tempDir.path}/order_test.m4a');
      testFile.writeAsBytesSync(Uint8List(1024));

      await recordingRepo.insertRecording(
        LocalRecordingsCompanion(
          id: const Value('rec_after'),
          projectId: const Value('proj-1'),
          genreId: const Value('g-1'),
          title: const Value('Rec After Storyteller'),
          // Long enough for the create-time description rule (ENG-354), which
          // would otherwise stop the recording before its create is issued.
          description: const Value('A description with enough substance'),
          durationSeconds: const Value(10.0),
          fileSizeBytes: const Value(1024),
          format: const Value('m4a'),
          localFilePath: Value(testFile.path),
          uploadStatus: const Value('local'),
          storytellerId: const Value('stl_first'),
          recordedAt: Value(DateTime(2026, 1, 1)),
        ),
      );

      final order = <String>[];
      final httpClient = MockClient((request) async {
        final path = request.url.path;

        if (request.method == 'POST' &&
            path == '/api/oc/projects/proj-1/storytellers') {
          order.add('storyteller');
          return http.Response(
            jsonEncode({
              'id': 'srv-first',
              'project_id': 'proj-1',
              'name': 'First',
              'sex': 'male',
              'external_acceptance_confirmed': true,
              'created_at': DateTime(2026, 1, 1).toIso8601String(),
            }),
            201,
          );
        }

        if (request.method == 'POST' && path == '/api/oc/recordings') {
          order.add('recording-create');
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

      expect(
        order.indexOf('storyteller'),
        lessThan(order.indexOf('recording-create')),
        reason: 'storyteller sync must happen before recording upload',
      );

      httpClient.close();
    });

    test('failed POST increments retryCount and keeps row pending', () async {
      await storytellerRepo.insertLocal(
        makeStoryteller(id: 'stl_fail', name: 'WillFail'),
        syncStatus: 'local',
      );

      final httpClient = MockClient((request) async {
        if (request.method == 'POST' &&
            request.url.path == '/api/oc/projects/proj-1/storytellers') {
          return http.Response('boom', 500);
        }
        return http.Response('Not Found', 404);
      });

      final engine = buildEngine(httpClient);
      await engine.processQueue();

      final pending = await storytellerRepo.getPendingSyncs();
      expect(pending.length, 1);
      expect(pending.single.retryCount, 1);
      expect(pending.single.syncStatus, 'failed');

      httpClient.close();
    });

    test(
      'storyteller failure does NOT abort processing of other storytellers',
      () async {
        await storytellerRepo.insertLocal(
          makeStoryteller(id: 'stl_bad', name: 'Bad', projectId: 'proj-1'),
          syncStatus: 'local',
        );
        await storytellerRepo.insertLocal(
          makeStoryteller(id: 'stl_good', name: 'Good', projectId: 'proj-2'),
          syncStatus: 'local',
        );

        final httpClient = MockClient((request) async {
          final path = request.url.path;
          if (request.method == 'POST' &&
              path == '/api/oc/projects/proj-1/storytellers') {
            return http.Response('boom', 500);
          }
          if (request.method == 'POST' &&
              path == '/api/oc/projects/proj-2/storytellers') {
            return http.Response(
              jsonEncode({
                'id': 'srv-good',
                'project_id': 'proj-2',
                'name': 'Good',
                'sex': 'male',
                'external_acceptance_confirmed': true,
                'created_at': DateTime(2026, 1, 1).toIso8601String(),
              }),
              201,
            );
          }
          return http.Response('Not Found', 404);
        });

        final engine = buildEngine(httpClient);
        await engine.processQueue();

        final pending = await storytellerRepo.getPendingSyncs();
        expect(pending.length, 1);
        expect(pending.single.id, 'stl_bad');

        httpClient.close();
      },
    );
  });
}
