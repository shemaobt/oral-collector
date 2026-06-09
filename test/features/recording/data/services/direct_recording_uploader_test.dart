import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';

import 'package:oral_collector/core/config/env.dart';
import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/core/network/authenticated_client.dart';
import 'package:oral_collector/core/platform/file_source.dart';
import 'package:oral_collector/features/recording/data/repositories/local_recording_repository.dart';
import 'package:oral_collector/features/recording/data/services/direct_recording_uploader.dart';
import 'package:oral_collector/features/sync/data/services/resumable_upload_service.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

class MockResumableUploadService extends Mock
    implements ResumableUploadService {}

class MockLocalRecordingRepository extends Mock
    implements LocalRecordingRepository {}

class FakeResumableUploadService extends Fake
    implements ResumableUploadService {
  int attempts = 0;

  @override
  Future<ResumableUploadResult> uploadFromSource({
    required String recordingId,
    required String serverId,
    required FileSource source,
    required String format,
    void Function(int bytesSent, int totalBytes)? onProgress,
  }) async {
    attempts++;
    if (attempts == 1) {
      return const ResumableUploadResult(success: false, error: 'offline');
    }
    return const ResumableUploadResult(success: true, clientCrc32c: 'AAAAAA==');
  }
}

void main() {
  late MockSecureStorage storage;
  late MockResumableUploadService resumable;
  late MockLocalRecordingRepository repo;

  setUp(() {
    storage = MockSecureStorage();
    when(
      () => storage.read(key: any(named: 'key')),
    ).thenAnswer((_) async => 'test-token');
    resumable = MockResumableUploadService();
    repo = MockLocalRecordingRepository();
  });

  DirectUploadMetadata sampleMeta() => DirectUploadMetadata(
    projectId: 'proj-1',
    genreId: 'unclassified',
    subcategoryId: 'unclassified',
    registerId: null,
    storytellerId: 'st-1',
    userId: 'user-1',
    title: 'Web recording',
    description: null,
    durationSeconds: 12.3,
    fileSizeBytes: 10,
    format: 'm4a',
    recordedAt: DateTime.utc(2026, 4, 15, 10, 0, 0),
  );

  FileSource sampleSource(Uint8List bytes) =>
      FileSource.fromBytes(bytes, name: 'test.m4a', mimeType: 'audio/mp4');

  test('runs create, upload-url, PUT, and confirm in order', () async {
    final calls = <String>[];
    final bytes = Uint8List.fromList(List.generate(10, (i) => i));

    final httpClient = MockClient((request) async {
      final method = request.method;
      final path = request.url.path;
      calls.add('$method ${request.url}');

      if (method == 'POST' && path == '/api/oc/recordings') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['project_id'], 'proj-1');
        expect(body['genre_id'], 'unclassified');
        expect(body['subcategory_id'], 'unclassified');
        expect(body.containsKey('register_id'), isFalse);
        expect(body['storyteller_id'], 'st-1');
        return http.Response(jsonEncode({'id': 'srv-abc'}), 201);
      }
      if (method == 'POST' && path == '/api/oc/recordings/upload-url') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['recording_id'], 'srv-abc');
        expect(body['format'], 'm4a');
        return http.Response(
          jsonEncode({
            'upload_url': 'https://storage.googleapis.com/bucket/object',
            'content_type': 'audio/mp4',
          }),
          200,
        );
      }
      if (method == 'PUT' && request.url.host == 'storage.googleapis.com') {
        expect(request.bodyBytes, bytes);
        return http.Response('', 200);
      }
      if (method == 'POST' &&
          path == '/api/oc/recordings/srv-abc/confirm-upload') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body.containsKey('md5_hash'), isFalse);
        expect(body['crc32c'], isA<String>());
        // base64 of 4 bytes always serializes to 8 chars (6 chars + "==").
        expect((body['crc32c'] as String).length, 8);
        return http.Response('{}', 200);
      }
      return http.Response('unexpected', 500);
    });

    final auth = AuthenticatedClient(client: httpClient, storage: storage);
    final uploader = DirectRecordingUploader(
      client: auth,
      resumableUploadService: resumable,
      recordingRepo: repo,
    );

    final serverId = await uploader.upload(
      source: sampleSource(bytes),
      meta: sampleMeta(),
    );
    expect(serverId, 'srv-abc');

    expect(calls, [
      'POST ${Env.backendUrl}/api/oc/recordings',
      'POST ${Env.backendUrl}/api/oc/recordings/upload-url',
      'PUT https://storage.googleapis.com/bucket/object',
      'POST ${Env.backendUrl}/api/oc/recordings/srv-abc/confirm-upload',
    ]);
    verifyZeroInteractions(resumable);
  });

  test('throws when the create step fails', () async {
    final bytes = Uint8List(10);
    final httpClient = MockClient((request) async {
      if (request.url.path == '/api/oc/recordings') {
        return http.Response('project not found', 404);
      }
      return http.Response('unexpected', 500);
    });
    final auth = AuthenticatedClient(client: httpClient, storage: storage);
    final uploader = DirectRecordingUploader(
      client: auth,
      resumableUploadService: resumable,
      recordingRepo: repo,
    );

    expect(
      () => uploader.upload(source: sampleSource(bytes), meta: sampleMeta()),
      throwsA(isA<Exception>()),
    );
  });

  test('throws when GCS PUT fails', () async {
    final bytes = Uint8List(10);
    final httpClient = MockClient((request) async {
      if (request.url.path == '/api/oc/recordings') {
        return http.Response(jsonEncode({'id': 'srv-abc'}), 201);
      }
      if (request.url.path == '/api/oc/recordings/upload-url') {
        return http.Response(
          jsonEncode({
            'upload_url': 'https://storage.googleapis.com/bucket/object',
            'content_type': 'audio/mp4',
          }),
          200,
        );
      }
      if (request.method == 'PUT') {
        return http.Response('forbidden', 403);
      }
      return http.Response('unexpected', 500);
    });
    final auth = AuthenticatedClient(client: httpClient, storage: storage);
    final uploader = DirectRecordingUploader(
      client: auth,
      resumableUploadService: resumable,
      recordingRepo: repo,
    );

    expect(
      () => uploader.upload(source: sampleSource(bytes), meta: sampleMeta()),
      throwsA(isA<Exception>()),
    );
  });

  test('retrying a failed resumable web import does not hit UNIQUE constraint '
      'and completes', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final realRepo = LocalRecordingRepository(db);

    final httpClient = MockClient((request) async {
      final path = request.url.path;
      if (request.method == 'POST' && path == '/api/oc/recordings') {
        return http.Response(jsonEncode({'id': 'srv-A'}), 201);
      }
      if (request.method == 'POST' &&
          path == '/api/oc/recordings/srv-A/confirm-upload') {
        return http.Response('{}', 200);
      }
      return http.Response('unexpected', 500);
    });
    final auth = AuthenticatedClient(client: httpClient, storage: storage);

    final fakeResumable = FakeResumableUploadService();
    final uploader = DirectRecordingUploader(
      client: auth,
      resumableUploadService: fakeResumable,
      recordingRepo: realRepo,
    );

    // Must exceed DirectRecordingUploader's 5 MB small-file threshold so the
    // upload takes the resumable (shadow-row) path under test.
    const bigSize = 5 * 1024 * 1024 + 1;
    DirectUploadMetadata bigMeta() => DirectUploadMetadata(
      projectId: 'proj-1',
      genreId: 'unclassified',
      subcategoryId: 'unclassified',
      userId: 'user-1',
      title: 'Big web recording',
      durationSeconds: 60,
      fileSizeBytes: bigSize,
      format: 'm4a',
      recordedAt: DateTime.utc(2026, 4, 15, 10),
    );
    Uint8List bigBytes() => Uint8List(bigSize);

    // First attempt fails mid-upload, leaving a shadow row behind.
    await expectLater(
      uploader.upload(source: sampleSource(bigBytes()), meta: bigMeta()),
      throwsA(isA<Exception>()),
    );

    // Retry over the surviving shadow row must complete, not crash.
    final serverId = await uploader.upload(
      source: sampleSource(bigBytes()),
      meta: bigMeta(),
    );

    expect(serverId, 'srv-A');
    expect(await realRepo.getRecordingById('web_srv-A'), isNull);
  });

  test('recusa upload-url http inseguro sem fazer PUT', () async {
    final bytes = Uint8List(10);
    final calls = <String>[];
    final httpClient = MockClient((request) async {
      calls.add('${request.method} ${request.url}');
      final path = request.url.path;
      if (request.method == 'POST' && path == '/api/oc/recordings') {
        return http.Response(jsonEncode({'id': 'srv-abc'}), 201);
      }
      if (request.method == 'POST' && path == '/api/oc/recordings/upload-url') {
        return http.Response(
          jsonEncode({
            'upload_url': 'http://evil.com/leak',
            'content_type': 'audio/mp4',
          }),
          200,
        );
      }
      return http.Response('unexpected', 500);
    });
    final auth = AuthenticatedClient(client: httpClient, storage: storage);
    final uploader = DirectRecordingUploader(
      client: auth,
      resumableUploadService: resumable,
      recordingRepo: repo,
    );

    await expectLater(
      uploader.upload(source: sampleSource(bytes), meta: sampleMeta()),
      throwsA(isA<Exception>()),
    );
    expect(calls.any((c) => c.startsWith('PUT')), isFalse);
  });
}
