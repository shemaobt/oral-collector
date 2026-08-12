/// A boosted recording replaces its audio on the server it already lives on
/// (ENG-402).
///
/// Raising the volume of an uploaded story used to go up as a *new* recording
/// while a best-effort DELETE tried to retire the old one. Offline that DELETE
/// never happened, so the server kept both and the project counted the story
/// twice.
///
/// These run the real engine and the real boost persister against the real
/// repository over an in-memory database, and the MockClient stands in for the
/// server by holding the set of recordings it knows about — so the question
/// "how many recordings does the server have now" is answered by state, not by
/// which methods a fake saw.
library;

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
import 'package:oral_collector/features/recording/data/services/recording_boost_persister.dart';
import 'package:oral_collector/features/storyteller/data/repositories/local_storyteller_repository.dart';
import 'package:oral_collector/features/sync/data/repositories/sync_engine.dart';
import 'package:oral_collector/features/sync/data/services/upload_downloader.dart';
import 'package:oral_collector/features/sync/domain/repositories/connectivity_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../support/sync_engine_api.dart';

class _MockConnectivity extends Mock implements ConnectivityService {}

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

/// One recording as the server holds it.
class _ServerRecording {
  _ServerRecording({
    required this.durationSeconds,
    required this.fileSizeBytes,
  });

  double durationSeconds;
  int fileSizeBytes;
}

/// The transfer itself is not what these tests are about; the device's
/// background uploader needs a platform channel, so the bytes always land.
class _AlwaysOkDownloader implements UploadDownloader {
  const _AlwaysOkDownloader();

  @override
  Future<UploadResult> putChunk({
    required String taskId,
    required String url,
    required String filePath,
    required int offset,
    required int end,
    required Map<String, String> headers,
  }) async => const UploadResult(statusCode: 200);

  @override
  Future<void> cancel(String taskId) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> resumeAfterCancel() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const boostedSize = 4096;
  const boostedDuration = 59.5;

  late Directory tempDir;
  late File audioFile;
  late AppDatabase db;
  late LocalRecordingRepository repo;
  late _MockConnectivity connectivity;
  late _MockSecureStorage storage;
  late Map<String, _ServerRecording> server;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    tempDir = Directory.systemTemp.createTempSync('eng402');
    audioFile = File('${tempDir.path}/boosted.m4a')
      ..writeAsBytesSync(Uint8List(boostedSize));
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = LocalRecordingRepository(db);
    connectivity = _MockConnectivity();
    storage = _MockSecureStorage();
    when(
      () => storage.read(key: any(named: 'key')),
    ).thenAnswer((_) async => 'test-token');
    server = {
      'srv-1': _ServerRecording(durationSeconds: 60, fileSizeBytes: 100000),
    };
  });

  tearDown(() async {
    await db.close();
    tempDir.deleteSync(recursive: true);
  });

  void setOnline({required bool online}) {
    when(() => connectivity.isOnline).thenAnswer((_) async => online);
    when(() => connectivity.isOnWifi).thenAnswer((_) async => online);
  }

  /// The server: it creates a recording on POST, retires one on DELETE, takes
  /// the audio facts on PATCH, and refuses to confirm an upload whose bytes do
  /// not match the size it holds — which is what the real endpoint verifies the
  /// blob against.
  MockClient serverClient() {
    var created = 0;
    return MockClient((request) async {
      final path = request.url.path;
      final method = request.method;

      if (request.url.host == 'storage.googleapis.com') {
        return http.Response('', 200);
      }
      if (method == 'POST' && path == '/api/oc/recordings') {
        created++;
        final id = 'srv-new-$created';
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        server[id] = _ServerRecording(
          durationSeconds: (body['duration_seconds'] as num).toDouble(),
          fileSizeBytes: body['file_size_bytes'] as int,
        );
        return http.Response(jsonEncode({'id': id}), 201);
      }
      if (method == 'POST' && path == '/api/oc/recordings/upload-url') {
        return http.Response(
          jsonEncode({
            'upload_url': 'https://storage.googleapis.com/test',
            'content_type': 'audio/mp4',
          }),
          200,
        );
      }
      if (method == 'POST' && path.endsWith('/confirm-upload')) {
        final id = path.split('/')[4];
        final record = server[id];
        if (record == null) return http.Response('Not Found', 404);
        // What the real endpoint verifies the blob against, and the reason the
        // new size has to reach the server before the bytes do.
        if (record.fileSizeBytes != audioFile.lengthSync()) {
          return http.Response('size mismatch', 400);
        }
        return http.Response(
          jsonEncode({'gcs_url': 'https://storage.googleapis.com/b/$id.m4a'}),
          200,
        );
      }
      if (method == 'PATCH' && path.startsWith('/api/oc/recordings/')) {
        final id = path.split('/').last;
        final record = server[id];
        if (record == null) return http.Response('Not Found', 404);
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        if (body['duration_seconds'] != null) {
          record.durationSeconds = (body['duration_seconds'] as num).toDouble();
        }
        if (body['file_size_bytes'] != null) {
          record.fileSizeBytes = body['file_size_bytes'] as int;
        }
        return http.Response(jsonEncode({'id': id}), 200);
      }
      if (method == 'DELETE' && path.startsWith('/api/oc/recordings/')) {
        server.remove(path.split('/').last);
        return http.Response('', 204);
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
      recordingRepo: repo,
      storytellerRepo: LocalStorytellerRepository(db),
      connectivity: connectivity,
      client: authClient,
      recordingApi: apiRepoFor(authClient),
      uploadDownloader: const _AlwaysOkDownloader(),
    );
  }

  /// A story already uploaded and verified, sitting on the device.
  Future<void> seedUploaded() async {
    await repo.insertRecording(
      LocalRecordingsCompanion(
        id: const Value('rec-1'),
        projectId: const Value('proj'),
        genreId: const Value('genre-1'),
        subcategoryId: const Value('sub-1'),
        serverId: const Value('srv-1'),
        title: const Value('Story'),
        description: const Value('a description with enough substance'),
        durationSeconds: const Value(60),
        fileSizeBytes: const Value(100000),
        format: const Value('m4a'),
        localFilePath: Value('${tempDir.path}/original.m4a'),
        uploadStatus: const Value('verified'),
        cleaningStatus: const Value('none'),
        recordedAt: Value(DateTime.utc(2026, 5, 1)),
      ),
    );
  }

  /// Applies the boost the way the trim editor does on the device.
  Future<void> applyBoostOffline() async {
    final recording = localRecordingToEntity(
      (await repo.getRecordingById('rec-1'))!,
    );
    await RecordingBoostPersister(
      localRepo: repo,
      triggerUpload: () async {},
    ).persist(
      recording: recording,
      newFilePath: audioFile.path,
      newDurationSeconds: boostedDuration,
      newFileSizeBytes: boostedSize,
    );
  }

  test('a boost applied offline reaches the server on reconnect, and the '
      'server still knows one recording', () async {
    await seedUploaded();
    setOnline(online: false);
    await applyBoostOffline();

    final client = serverClient();
    // Offline: the pass must not lose the edit.
    await buildEngine(client).processQueue();
    expect(server['srv-1']!.fileSizeBytes, 100000);

    setOnline(online: true);
    await buildEngine(client).processQueue();

    expect(server.keys, ['srv-1']);
    expect(server['srv-1']!.fileSizeBytes, boostedSize);
    expect(server['srv-1']!.durationSeconds, boostedDuration);

    final row = (await repo.getRecordingById('rec-1'))!;
    expect(row.uploadStatus, 'uploaded');
    expect(row.serverId, 'srv-1');
    client.close();
  });
}
