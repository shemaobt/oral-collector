import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';

import 'package:oral_collector/core/network/authenticated_client.dart';
import 'package:oral_collector/features/recording/data/services/direct_recording_uploader.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockSecureStorage storage;

  setUpAll(() {
    dotenv.testLoad(fileInput: 'BACKEND_URL=http://localhost:8080');
  });

  setUp(() {
    storage = MockSecureStorage();
    when(
      () => storage.read(key: any(named: 'key')),
    ).thenAnswer((_) async => 'test-token');
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
        expect(body['md5_hash'], isA<String>());
        expect((body['md5_hash'] as String).length, 32);
        return http.Response('{}', 200);
      }
      return http.Response('unexpected', 500);
    });

    final auth = AuthenticatedClient(client: httpClient, storage: storage);
    final uploader = DirectRecordingUploader(auth);

    final serverId = await uploader.upload(bytes: bytes, meta: sampleMeta());
    expect(serverId, 'srv-abc');

    expect(calls, [
      'POST http://localhost:8080/api/oc/recordings',
      'POST http://localhost:8080/api/oc/recordings/upload-url',
      'PUT https://storage.googleapis.com/bucket/object',
      'POST http://localhost:8080/api/oc/recordings/srv-abc/confirm-upload',
    ]);
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
    final uploader = DirectRecordingUploader(auth);

    expect(
      () => uploader.upload(bytes: bytes, meta: sampleMeta()),
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
    final uploader = DirectRecordingUploader(auth);

    expect(
      () => uploader.upload(bytes: bytes, meta: sampleMeta()),
      throwsA(isA<Exception>()),
    );
  });
}
