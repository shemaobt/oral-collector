import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';

import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/core/network/authenticated_client.dart';
import 'package:oral_collector/features/recording/data/repositories/local_recording_repository.dart';
import 'package:oral_collector/features/sync/data/repositories/sync_engine.dart';
import 'package:oral_collector/features/sync/domain/repositories/connectivity_service.dart';

class MockRecordingRepo extends Mock implements LocalRecordingRepository {}

class MockConnectivity extends Mock implements ConnectivityService {}

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

class FakeLocalRecordingsCompanion extends Fake
    implements LocalRecordingsCompanion {}

LocalRecording makeRecording({
  String id = 'rec-1',
  String projectId = 'proj-1',
  String genreId = 'genre-1',
  String? subcategoryId,
  String? title = 'Test Recording',
  double durationSeconds = 60.0,
  int fileSizeBytes = 1024,
  String format = 'm4a',
  String localFilePath = '/tmp/test.m4a',
  String uploadStatus = 'local',
  String? serverId,
  String? gcsUrl,
  String? registerId,
  String cleaningStatus = 'none',
  DateTime? recordedAt,
  DateTime? createdAt,
  int retryCount = 0,
  DateTime? lastRetryAt,
  String? resumableSessionUri,
  int uploadedBytes = 0,
  String? md5Hash,
}) {
  return LocalRecording(
    id: id,
    projectId: projectId,
    genreId: genreId,
    subcategoryId: subcategoryId,
    title: title,
    durationSeconds: durationSeconds,
    fileSizeBytes: fileSizeBytes,
    format: format,
    localFilePath: localFilePath,
    uploadStatus: uploadStatus,
    serverId: serverId,
    gcsUrl: gcsUrl,
    registerId: registerId,
    cleaningStatus: cleaningStatus,
    recordedAt: recordedAt ?? DateTime(2024, 1, 1),
    createdAt: createdAt ?? DateTime(2024, 1, 1),
    retryCount: retryCount,
    lastRetryAt: lastRetryAt,
    resumableSessionUri: resumableSessionUri,
    uploadedBytes: uploadedBytes,
    md5Hash: md5Hash,
  );
}

void main() {
  late Directory tempDir;
  late MockRecordingRepo mockRepo;
  late MockConnectivity mockConnectivity;
  late MockSecureStorage mockStorage;

  setUpAll(() {
    registerFallbackValue(FakeLocalRecordingsCompanion());
    registerFallbackValue('');
    dotenv.testLoad(fileInput: 'BACKEND_URL=http://localhost:8080');
  });

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('sync_engine_test');
    mockRepo = MockRecordingRepo();
    mockConnectivity = MockConnectivity();
    mockStorage = MockSecureStorage();

    when(
      () => mockStorage.read(key: any(named: 'key')),
    ).thenAnswer((_) async => 'test-token');
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  SyncEngineImpl buildEngine(MockClient httpClient) {
    final authClient = AuthenticatedClient(
      client: httpClient,
      storage: mockStorage,
    );
    return SyncEngineImpl(
      recordingRepo: mockRepo,
      connectivity: mockConnectivity,
      client: authClient,
    );
  }

  MockClient buildSuccessClient() {
    return MockClient((request) async {
      final path = request.url.path;

      if (request.method == 'POST' && path == '/api/oc/recordings') {
        return http.Response(jsonEncode({'id': 'srv-1'}), 201);
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
        return http.Response('', 200);
      }

      if (request.method == 'GET' &&
          path.startsWith('/api/oc/recordings/srv-')) {
        return http.Response(
          jsonEncode({
            'upload_status': 'verified',
            'gcs_url': 'https://storage.googleapis.com/bucket/file.m4a',
          }),
          200,
        );
      }

      return http.Response('Not Found', 404);
    });
  }

  void stubRepoForUpload(String filePath, {String id = 'rec-1'}) {
    final rec = makeRecording(id: id, localFilePath: filePath);

    when(() => mockRepo.getRecordingById(id)).thenAnswer((_) async => rec);
    when(() => mockRepo.markAsUploading(id)).thenAnswer((_) async => true);
    when(
      () => mockRepo.markAsUploaded(id, any(), any()),
    ).thenAnswer((_) async => true);
    when(
      () => mockRepo.markAsFailed(
        id,
        incrementRetry: any(named: 'incrementRetry'),
      ),
    ).thenAnswer((_) async => true);
    when(
      () => mockRepo.updateRecording(id, any()),
    ).thenAnswer((_) async => true);
    when(() => mockRepo.resetRetryCount(id)).thenAnswer((_) async => true);
  }

  group('processQueue - basic flow', () {
    test('returns immediately when already processing', () async {
      final testFile = File('${tempDir.path}/test.m4a');
      testFile.writeAsBytesSync(Uint8List(1024));

      when(() => mockConnectivity.isOnline).thenAnswer((_) async => true);
      when(() => mockRepo.getPendingUploads()).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return [];
      });

      final httpClient = buildSuccessClient();
      final engine = buildEngine(httpClient);

      final first = engine.processQueue();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final second = engine.processQueue();

      await first;
      await second;

      verify(() => mockRepo.getPendingUploads()).called(1);
      httpClient.close();
    });

    test('returns when offline', () async {
      when(() => mockConnectivity.isOnline).thenAnswer((_) async => false);

      final httpClient = buildSuccessClient();
      final engine = buildEngine(httpClient);

      await engine.processQueue();

      verifyNever(() => mockRepo.getPendingUploads());
      httpClient.close();
    });

    test('returns when wifiOnly and not on WiFi', () async {
      when(() => mockConnectivity.isOnline).thenAnswer((_) async => true);
      when(() => mockConnectivity.isOnWifi).thenAnswer((_) async => false);

      final httpClient = buildSuccessClient();
      final engine = buildEngine(httpClient);

      await engine.processQueue(wifiOnly: true);

      verifyNever(() => mockRepo.getPendingUploads());
      httpClient.close();
    });

    test('processes empty queue', () async {
      when(() => mockConnectivity.isOnline).thenAnswer((_) async => true);
      when(() => mockRepo.getPendingUploads()).thenAnswer((_) async => []);

      final httpClient = buildSuccessClient();
      final engine = buildEngine(httpClient);

      await engine.processQueue();

      verify(() => mockRepo.getPendingUploads()).called(1);
      expect(engine.isProcessing, isFalse);
      httpClient.close();
    });

    test('single recording upload success', () async {
      final testFile = File('${tempDir.path}/success.m4a');
      testFile.writeAsBytesSync(Uint8List(1024));

      final rec = makeRecording(localFilePath: testFile.path);

      when(() => mockConnectivity.isOnline).thenAnswer((_) async => true);
      when(() => mockRepo.getPendingUploads()).thenAnswer((_) async => [rec]);
      stubRepoForUpload(testFile.path);

      final httpClient = buildSuccessClient();
      final engine = buildEngine(httpClient);

      await engine.processQueue();

      verify(() => mockRepo.markAsUploading('rec-1')).called(1);
      verify(() => mockRepo.markAsUploaded('rec-1', 'srv-1', any())).called(1);
      expect(engine.isProcessing, isFalse);
      httpClient.close();
    });
  });

  group('processQueue - retry/backoff', () {
    test('skips recordings with retryCount >= 5', () async {
      final testFile = File('${tempDir.path}/maxretry.m4a');
      testFile.writeAsBytesSync(Uint8List(1024));

      final rec = makeRecording(
        localFilePath: testFile.path,
        retryCount: 5,
        lastRetryAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      when(() => mockConnectivity.isOnline).thenAnswer((_) async => true);
      when(() => mockRepo.getPendingUploads()).thenAnswer((_) async => [rec]);

      final httpClient = buildSuccessClient();
      final engine = buildEngine(httpClient);

      await engine.processQueue();

      verifyNever(() => mockRepo.markAsUploading(any()));
      httpClient.close();
    });

    test('skips recordings within backoff window', () async {
      final testFile = File('${tempDir.path}/backoff.m4a');
      testFile.writeAsBytesSync(Uint8List(1024));

      final rec = makeRecording(
        localFilePath: testFile.path,
        retryCount: 1,
        lastRetryAt: DateTime.now(),
      );

      when(() => mockConnectivity.isOnline).thenAnswer((_) async => true);
      when(() => mockRepo.getPendingUploads()).thenAnswer((_) async => [rec]);

      final httpClient = buildSuccessClient();
      final engine = buildEngine(httpClient);

      await engine.processQueue();

      verifyNever(() => mockRepo.markAsUploading(any()));
      httpClient.close();
    });

    test('processes recordings past backoff window', () async {
      final testFile = File('${tempDir.path}/pastbackoff.m4a');
      testFile.writeAsBytesSync(Uint8List(1024));

      final rec = makeRecording(
        localFilePath: testFile.path,
        retryCount: 1,
        lastRetryAt: DateTime.now().subtract(const Duration(seconds: 30)),
      );

      when(() => mockConnectivity.isOnline).thenAnswer((_) async => true);
      when(() => mockRepo.getPendingUploads()).thenAnswer((_) async => [rec]);
      stubRepoForUpload(testFile.path);

      final httpClient = buildSuccessClient();
      final engine = buildEngine(httpClient);

      await engine.processQueue();

      verify(() => mockRepo.markAsUploading('rec-1')).called(1);
      httpClient.close();
    });
  });

  group('processQueue - concurrency', () {
    test(
      'uploads multiple recordings concurrently with maxConcurrency=3',
      () async {
        final files = <File>[];
        final recordings = <LocalRecording>[];

        for (var i = 0; i < 5; i++) {
          final f = File('${tempDir.path}/concurrent_$i.m4a');
          f.writeAsBytesSync(Uint8List(1024));
          files.add(f);

          recordings.add(makeRecording(id: 'rec-$i', localFilePath: f.path));
        }

        when(() => mockConnectivity.isOnline).thenAnswer((_) async => true);
        when(
          () => mockRepo.getPendingUploads(),
        ).thenAnswer((_) async => recordings);

        for (var i = 0; i < 5; i++) {
          stubRepoForUpload(files[i].path, id: 'rec-$i');
        }

        var serverIdCounter = 0;
        final httpClient = MockClient((request) async {
          final path = request.url.path;

          if (request.method == 'POST' && path == '/api/oc/recordings') {
            serverIdCounter++;
            return http.Response(
              jsonEncode({'id': 'srv-$serverIdCounter'}),
              201,
            );
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
            return http.Response('', 200);
          }

          if (request.method == 'GET' &&
              path.startsWith('/api/oc/recordings/srv-')) {
            return http.Response(
              jsonEncode({
                'upload_status': 'verified',
                'gcs_url': 'https://storage.googleapis.com/bucket/file.m4a',
              }),
              200,
            );
          }

          return http.Response('Not Found', 404);
        });

        final engine = buildEngine(httpClient);

        await engine.processQueue(maxConcurrency: 3);

        for (var i = 0; i < 5; i++) {
          verify(() => mockRepo.markAsUploading('rec-$i')).called(1);
        }

        expect(engine.isProcessing, isFalse);
        httpClient.close();
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );
  });

  group('error handling', () {
    test('401 response marks as non-retryable', () async {
      final testFile = File('${tempDir.path}/auth_fail.m4a');
      testFile.writeAsBytesSync(Uint8List(1024));

      final rec = makeRecording(localFilePath: testFile.path);

      when(() => mockConnectivity.isOnline).thenAnswer((_) async => true);
      when(() => mockRepo.getPendingUploads()).thenAnswer((_) async => [rec]);
      stubRepoForUpload(testFile.path);

      final httpClient = MockClient((request) async {
        if (request.method == 'POST' &&
            request.url.path == '/api/oc/recordings') {
          return http.Response('Unauthorized', 401);
        }
        return http.Response('Not Found', 404);
      });

      final engine = buildEngine(httpClient);

      await engine.processQueue();

      verify(
        () => mockRepo.updateRecording(
          'rec-1',
          any(that: isA<LocalRecordingsCompanion>()),
        ),
      ).called(greaterThanOrEqualTo(1));
      verifyNever(() => mockRepo.markAsUploaded(any(), any(), any()));
      httpClient.close();
    });

    test('500 response marks as retryable failure', () async {
      final testFile = File('${tempDir.path}/server_err.m4a');
      testFile.writeAsBytesSync(Uint8List(1024));

      final rec = makeRecording(localFilePath: testFile.path);

      when(() => mockConnectivity.isOnline).thenAnswer((_) async => true);
      when(() => mockRepo.getPendingUploads()).thenAnswer((_) async => [rec]);
      stubRepoForUpload(testFile.path);

      final httpClient = MockClient((request) async {
        if (request.method == 'POST' &&
            request.url.path == '/api/oc/recordings') {
          return http.Response('Internal Server Error', 500);
        }
        return http.Response('Not Found', 404);
      });

      final engine = buildEngine(httpClient);

      await engine.processQueue();

      verify(() => mockRepo.markAsFailed('rec-1')).called(1);
      verifyNever(() => mockRepo.markAsUploaded(any(), any(), any()));
      httpClient.close();
    });

    test('timeout marks as retryable failure', () async {
      final testFile = File('${tempDir.path}/timeout.m4a');
      testFile.writeAsBytesSync(Uint8List(1024));

      final rec = makeRecording(localFilePath: testFile.path);

      when(() => mockConnectivity.isOnline).thenAnswer((_) async => true);
      when(() => mockRepo.getPendingUploads()).thenAnswer((_) async => [rec]);
      stubRepoForUpload(testFile.path);

      final httpClient = MockClient((request) async {
        if (request.method == 'POST' &&
            request.url.path == '/api/oc/recordings') {
          throw TimeoutException('mock timeout');
        }
        return http.Response('Not Found', 404);
      });

      final engine = buildEngine(httpClient);

      await engine.processQueue();

      verify(() => mockRepo.markAsFailed('rec-1')).called(1);
      verifyNever(() => mockRepo.markAsUploaded(any(), any(), any()));
      httpClient.close();
    });
  });

  group('verification polling', () {
    test('polling returns verified leads to success', () async {
      final testFile = File('${tempDir.path}/poll_ok.m4a');
      testFile.writeAsBytesSync(Uint8List(1024));

      final rec = makeRecording(localFilePath: testFile.path);

      when(() => mockConnectivity.isOnline).thenAnswer((_) async => true);
      when(() => mockRepo.getPendingUploads()).thenAnswer((_) async => [rec]);
      stubRepoForUpload(testFile.path);

      var pollCount = 0;
      final httpClient = MockClient((request) async {
        final path = request.url.path;

        if (request.method == 'POST' && path == '/api/oc/recordings') {
          return http.Response(jsonEncode({'id': 'srv-1'}), 201);
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
          return http.Response('', 200);
        }

        if (request.method == 'GET' && path == '/api/oc/recordings/srv-1') {
          pollCount++;
          if (pollCount < 3) {
            return http.Response(
              jsonEncode({'upload_status': 'processing'}),
              200,
            );
          }
          return http.Response(
            jsonEncode({
              'upload_status': 'verified',
              'gcs_url': 'https://storage.googleapis.com/bucket/file.m4a',
            }),
            200,
          );
        }

        return http.Response('Not Found', 404);
      });

      final engine = buildEngine(httpClient);

      await engine.processQueue();

      verify(() => mockRepo.markAsUploaded('rec-1', 'srv-1', any())).called(1);
      expect(pollCount, 3);
      httpClient.close();
    });

    test('polling returns upload_failed marks as failed', () async {
      final testFile = File('${tempDir.path}/poll_fail.m4a');
      testFile.writeAsBytesSync(Uint8List(1024));

      final rec = makeRecording(localFilePath: testFile.path);

      when(() => mockConnectivity.isOnline).thenAnswer((_) async => true);
      when(() => mockRepo.getPendingUploads()).thenAnswer((_) async => [rec]);
      stubRepoForUpload(testFile.path);

      final httpClient = MockClient((request) async {
        final path = request.url.path;

        if (request.method == 'POST' && path == '/api/oc/recordings') {
          return http.Response(jsonEncode({'id': 'srv-1'}), 201);
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
          return http.Response('', 200);
        }

        if (request.method == 'GET' && path == '/api/oc/recordings/srv-1') {
          return http.Response(
            jsonEncode({
              'upload_status': 'upload_failed',
              'upload_error': 'Checksum mismatch',
            }),
            200,
          );
        }

        return http.Response('Not Found', 404);
      });

      final engine = buildEngine(httpClient);

      await engine.processQueue();

      verify(() => mockRepo.markAsFailed('rec-1')).called(1);
      verifyNever(() => mockRepo.markAsUploaded(any(), any(), any()));
      httpClient.close();
    });

    test('confirm-upload failure marks as failed not uploaded', () async {
      final testFile = File('${tempDir.path}/poll_timeout.m4a');
      testFile.writeAsBytesSync(Uint8List(1024));

      final rec = makeRecording(localFilePath: testFile.path);

      when(() => mockConnectivity.isOnline).thenAnswer((_) async => true);
      when(() => mockRepo.getPendingUploads()).thenAnswer((_) async => [rec]);
      stubRepoForUpload(testFile.path);

      final httpClient = MockClient((request) async {
        final path = request.url.path;

        if (request.method == 'POST' && path == '/api/oc/recordings') {
          return http.Response(jsonEncode({'id': 'srv-1'}), 201);
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
          return http.Response('Server Error', 500);
        }

        return http.Response('Not Found', 404);
      });

      final engine = buildEngine(httpClient);

      await engine.processQueue();

      verify(() => mockRepo.markAsFailed('rec-1')).called(1);
      verifyNever(() => mockRepo.markAsUploaded(any(), any(), any()));
      httpClient.close();
    });
  });

  group('uploadSingle', () {
    test('uploads only the specified recording', () async {
      final testFile = File('${tempDir.path}/single.m4a');
      testFile.writeAsBytesSync(Uint8List(1024));

      stubRepoForUpload(testFile.path);
      when(() => mockConnectivity.isOnline).thenAnswer((_) async => true);

      final httpClient = buildSuccessClient();
      final engine = buildEngine(httpClient);

      await engine.uploadSingle('rec-1');

      verify(
        () => mockRepo.getRecordingById('rec-1'),
      ).called(greaterThanOrEqualTo(1));
      verify(() => mockRepo.markAsUploading('rec-1')).called(1);
      verify(() => mockRepo.markAsUploaded('rec-1', 'srv-1', any())).called(1);
      verifyNever(() => mockRepo.getPendingUploads());
      httpClient.close();
    });

    test('returns early if recording not found', () async {
      when(
        () => mockRepo.getRecordingById('nonexistent'),
      ).thenAnswer((_) async => null);

      final httpClient = buildSuccessClient();
      final engine = buildEngine(httpClient);

      await engine.uploadSingle('nonexistent');

      verify(() => mockRepo.getRecordingById('nonexistent')).called(1);
      verifyNever(() => mockConnectivity.isOnline);
      verifyNever(() => mockRepo.markAsUploading(any()));
      httpClient.close();
    });

    test('returns early if offline', () async {
      final testFile = File('${tempDir.path}/offline_single.m4a');
      testFile.writeAsBytesSync(Uint8List(1024));

      final rec = makeRecording(localFilePath: testFile.path);
      when(
        () => mockRepo.getRecordingById('rec-1'),
      ).thenAnswer((_) async => rec);
      when(() => mockConnectivity.isOnline).thenAnswer((_) async => false);

      final httpClient = buildSuccessClient();
      final engine = buildEngine(httpClient);

      await engine.uploadSingle('rec-1');

      verify(() => mockRepo.getRecordingById('rec-1')).called(1);
      verify(() => mockConnectivity.isOnline).called(1);
      verifyNever(() => mockRepo.markAsUploading(any()));
      httpClient.close();
    });
  });
}
