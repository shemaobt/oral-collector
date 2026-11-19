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
import 'package:oral_collector/features/recording/data/local_recording_to_entity.dart';
import 'package:oral_collector/features/recording/data/repositories/local_recording_repository.dart';
import 'package:oral_collector/features/storyteller/data/repositories/local_storyteller_repository.dart';
import 'package:oral_collector/features/storyteller/domain/entities/storyteller.dart';
import 'package:oral_collector/features/sync/data/repositories/sync_engine.dart';
import 'package:oral_collector/features/sync/domain/repositories/connectivity_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../support/sync_engine_api.dart';

class MockConnectivity extends Mock implements ConnectivityService {}

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

const temporaryId = 'stl_1795065034097_b202a0';
const serverId = '4c038139-9d2e-4f6a-b1c4-7e2f0a9d3b51';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late LocalStorytellerRepository storytellerRepo;
  late LocalRecordingRepository recordingRepo;
  late MockConnectivity connectivity;
  late MockSecureStorage storage;
  late Directory tempDir;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    storytellerRepo = LocalStorytellerRepository(db);
    recordingRepo = LocalRecordingRepository(db);
    connectivity = MockConnectivity();
    storage = MockSecureStorage();
    tempDir = Directory.systemTemp.createTempSync(
      'split_temporary_storyteller',
    );

    when(() => connectivity.isOnline).thenAnswer((_) async => true);
    when(() => connectivity.isOnWifi).thenAnswer((_) async => true);
    when(
      () => storage.read(key: any(named: 'key')),
    ).thenAnswer((_) async => 'test-token');
  });

  tearDown(() async {
    tempDir.deleteSync(recursive: true);
    await db.close();
  });

  Storyteller leilani(String id) => Storyteller(
    id: id,
    projectId: 'proj-1',
    name: 'Leilani Kahale',
    sex: StorytellerSex.female,
    age: 41,
    externalAcceptanceConfirmed: true,
    createdAt: DateTime(2026, 11, 18),
  );

  Future<void> storytellerCreatedOnThePhoneAndSynced() async {
    await storytellerRepo.insertLocal(leilani(temporaryId));
    await storytellerRepo.markUploaded(temporaryId, serverId);
  }

  Future<void> storytellersRefreshedFromTheServer() =>
      storytellerRepo.upsertAll([leilani(serverId)], 'proj-1');

  Future<void> seedUploadedParent() async {
    await recordingRepo.insertRecording(
      LocalRecordingsCompanion(
        id: const Value('parent'),
        projectId: const Value('proj-1'),
        genreId: const Value('g-1'),
        title: const Value('Ruth: the sons marry'),
        description: const Value('Ruth 1:4, told aloud in Hawaiian.'),
        durationSeconds: const Value(10.9),
        fileSizeBytes: const Value(2048),
        format: const Value('m4a'),
        localFilePath: Value('${tempDir.path}/parent.m4a'),
        uploadStatus: const Value('uploaded'),
        serverId: const Value('srv-parent'),
        storytellerId: const Value(temporaryId),
        recordedAt: Value(DateTime(2026, 11, 18)),
      ),
    );
  }

  SplitSegmentSpec part(int index) {
    final file = File('${tempDir.path}/part$index.m4a')
      ..writeAsBytesSync(Uint8List(1024));
    return SplitSegmentSpec(
      id: 'part-$index',
      title: 'Ruth: the sons marry ($index/2)',
      localFilePath: file.path,
      durationSeconds: 5.4,
      fileSizeBytes: 1024,
    );
  }

  Future<void> splitTheParent() async {
    final parent = await recordingRepo.getRecordingById('parent');
    await recordingRepo.splitRecordingReplacingParent(
      parent: localRecordingToEntity(parent!),
      segments: [part(1), part(2)],
    );
  }

  MockClient serverThatKnowsOnly(String knownStorytellerId, List<String?> log) {
    return MockClient((request) async {
      final path = request.url.path;
      if (request.method == 'POST' && path == '/api/oc/recordings') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final storytellerId = body['storyteller_id'] as String?;
        log.add(storytellerId);
        if (storytellerId != null && storytellerId != knownStorytellerId) {
          return http.Response(
            jsonEncode({'detail': 'Storyteller not found'}),
            404,
          );
        }
        return http.Response(jsonEncode({'id': 'srv-${log.length}'}), 201);
      }
      if (request.method == 'POST' && path == '/api/oc/recordings/upload-url') {
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
  }

  SyncEngineImpl buildEngine(MockClient httpClient) {
    final authClient = AuthenticatedClient(
      client: httpClient,
      storage: storage,
    );
    return SyncEngineImpl(
      recordingRepo: recordingRepo,
      storytellerRepo: storytellerRepo,
      connectivity: connectivity,
      client: authClient,
      recordingApi: apiRepoFor(authClient),
    );
  }

  test(
    'the parts of a recording saved under a temporary storyteller upload with '
    'the storyteller the server knows, not the dead temporary id',
    () async {
      await storytellerCreatedOnThePhoneAndSynced();
      await seedUploadedParent();
      await storytellersRefreshedFromTheServer();
      await splitTheParent();

      final sent = <String?>[];
      final client = serverThatKnowsOnly(serverId, sent);
      await buildEngine(client).processQueue();

      expect(
        sent,
        [serverId, serverId],
        reason:
            'the split copied the parent\'s temporary id, which the server '
            'refused with a 404',
      );
      for (final id in ['part-1', 'part-2']) {
        final row = await recordingRepo.getRecordingById(id);
        expect(row!.uploadStatus, 'uploaded');
        final storyteller = await storytellerRepo.getById(row.storytellerId!);
        expect(
          storyteller?.name,
          'Leilani Kahale',
          reason: 'the part read «Unknown storyteller»',
        );
      }
      client.close();
    },
  );

  test('parts split before the storytellers refresh still name the storyteller '
      'after it, instead of an id nothing can find', () async {
    await storytellerCreatedOnThePhoneAndSynced();
    await seedUploadedParent();
    await splitTheParent();
    await storytellersRefreshedFromTheServer();

    for (final id in ['part-1', 'part-2']) {
      final row = await recordingRepo.getRecordingById(id);
      expect(
        row!.storytellerId,
        serverId,
        reason:
            'the refresh dropped the link to the temporary id and left the '
            'part with an id nothing resolves',
      );
    }
  });
}
