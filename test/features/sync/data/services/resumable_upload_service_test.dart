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
import 'package:oral_collector/features/sync/data/services/resumable_upload_service.dart';

class MockRecordingRepo extends Mock implements LocalRecordingRepository {}

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

class FakeLocalRecordingsCompanion extends Fake
    implements LocalRecordingsCompanion {}

void main() {
  late Directory tempDir;

  setUpAll(() {
    registerFallbackValue(FakeLocalRecordingsCompanion());
    registerFallbackValue('');
    dotenv.testLoad(fileInput: 'BACKEND_URL=http://localhost:8080');
  });

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('upload_test');
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  group('ResumableUploadResult', () {
    test('success result', () {
      const result = ResumableUploadResult(success: true);
      expect(result.success, isTrue);
      expect(result.error, isNull);
    });

    test('failure result', () {
      const result = ResumableUploadResult(success: false, error: 'timeout');
      expect(result.success, isFalse);
      expect(result.error, equals('timeout'));
    });
  });

  group('single PUT upload', () {
    late MockRecordingRepo mockRepo;
    late MockSecureStorage mockStorage;

    setUp(() {
      mockRepo = MockRecordingRepo();
      mockStorage = MockSecureStorage();
      when(
        () => mockStorage.read(key: any(named: 'key')),
      ).thenAnswer((_) async => 'test-token');
    });

    test('uploads small file successfully', () async {
      final testFile = File('${tempDir.path}/small.m4a');
      testFile.writeAsBytesSync(Uint8List(1024));

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('upload-url')) {
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
        return http.Response('', 404);
      });

      final authClient = AuthenticatedClient(
        client: mockClient,
        storage: mockStorage,
      );

      final service = ResumableUploadService(
        client: authClient,
        recordingRepo: mockRepo,
      );

      final result = await service.upload(
        recordingId: 'rec-1',
        serverId: 'srv-1',
        localFilePath: testFile.path,
        format: 'm4a',
        fileSizeBytes: 1024,
      );

      expect(result.success, isTrue);
      mockClient.close();
    });

    test('retries on 403 expired URL', () async {
      final testFile = File('${tempDir.path}/retry.m4a');
      testFile.writeAsBytesSync(Uint8List(512));

      var putCount = 0;
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('upload-url')) {
          return http.Response(
            jsonEncode({
              'upload_url': 'https://storage.googleapis.com/test',
              'content_type': 'audio/mp4',
            }),
            200,
          );
        }
        if (request.url.host == 'storage.googleapis.com') {
          putCount++;
          if (putCount == 1) return http.Response('expired', 403);
          return http.Response('', 200);
        }
        return http.Response('', 404);
      });

      final authClient = AuthenticatedClient(
        client: mockClient,
        storage: mockStorage,
      );

      final service = ResumableUploadService(
        client: authClient,
        recordingRepo: mockRepo,
      );

      final result = await service.upload(
        recordingId: 'rec-2',
        serverId: 'srv-2',
        localFilePath: testFile.path,
        format: 'm4a',
        fileSizeBytes: 512,
      );

      expect(result.success, isTrue);
      expect(putCount, 2);
      mockClient.close();
    });

    test('fails when upload-url endpoint fails', () async {
      final testFile = File('${tempDir.path}/fail.m4a');
      testFile.writeAsBytesSync(Uint8List(256));

      final mockClient = MockClient((request) async {
        return http.Response('Server Error', 500);
      });

      final authClient = AuthenticatedClient(
        client: mockClient,
        storage: mockStorage,
      );

      final service = ResumableUploadService(
        client: authClient,
        recordingRepo: mockRepo,
      );

      final result = await service.upload(
        recordingId: 'rec-3',
        serverId: 'srv-3',
        localFilePath: testFile.path,
        format: 'm4a',
        fileSizeBytes: 256,
      );

      expect(result.success, isFalse);
      mockClient.close();
    });

    test('tracks progress via callback', () async {
      final testFile = File('${tempDir.path}/progress.m4a');
      testFile.writeAsBytesSync(Uint8List(2048));

      final progressCalls = <(int, int)>[];

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('upload-url')) {
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
        return http.Response('', 404);
      });

      final authClient = AuthenticatedClient(
        client: mockClient,
        storage: mockStorage,
      );

      final service = ResumableUploadService(
        client: authClient,
        recordingRepo: mockRepo,
      );

      await service.upload(
        recordingId: 'rec-4',
        serverId: 'srv-4',
        localFilePath: testFile.path,
        format: 'm4a',
        fileSizeBytes: 2048,
        onProgress: (sent, total) => progressCalls.add((sent, total)),
      );

      expect(progressCalls, isNotEmpty);
      expect(progressCalls.last.$1, equals(progressCalls.last.$2));
      mockClient.close();
    });
  });

  group('resumable upload - new session', () {
    late MockRecordingRepo mockRepo;
    late MockSecureStorage mockStorage;
    const sessionUri = 'https://storage.googleapis.com/upload/session-123';
    const fileSize = 5 * 1024 * 1024;

    setUp(() {
      mockRepo = MockRecordingRepo();
      mockStorage = MockSecureStorage();
      when(
        () => mockStorage.read(key: any(named: 'key')),
      ).thenAnswer((_) async => 'test-token');
    });

    test('creates resumable session for file >= 5MB', () async {
      final testFile = File('${tempDir.path}/large.m4a');
      testFile.writeAsBytesSync(Uint8List(fileSize));

      when(() => mockRepo.getRecordingById('rec-1')).thenAnswer(
        (_) async => LocalRecording(
          id: 'rec-1',
          projectId: 'proj-1',
          genreId: 'genre-1',
          subcategoryId: null,
          title: 'Test',
          durationSeconds: 60.0,
          fileSizeBytes: fileSize,
          format: 'm4a',
          localFilePath: testFile.path,
          uploadStatus: 'uploading',
          serverId: 'srv-1',
          gcsUrl: null,
          registerId: null,
          cleaningStatus: 'none',
          recordedAt: DateTime(2024, 1, 1),
          createdAt: DateTime(2024, 1, 1),
          retryCount: 0,
          lastRetryAt: null,
          resumableSessionUri: null,
          uploadedBytes: 0,
          md5Hash: null,
        ),
      );

      when(
        () => mockRepo.updateRecording(any(), any()),
      ).thenAnswer((_) async => true);

      var sessionRequested = false;

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('resumable-upload-url')) {
          sessionRequested = true;
          return http.Response(jsonEncode({'session_uri': sessionUri}), 200);
        }
        if (request.url.host == 'storage.googleapis.com') {
          return http.Response('', 200);
        }
        return http.Response('', 404);
      });

      final authClient = AuthenticatedClient(
        client: mockClient,
        storage: mockStorage,
      );

      final service = ResumableUploadService(
        client: authClient,
        recordingRepo: mockRepo,
      );

      final result = await service.upload(
        recordingId: 'rec-1',
        serverId: 'srv-1',
        localFilePath: testFile.path,
        format: 'm4a',
        fileSizeBytes: fileSize,
      );

      expect(result.success, isTrue);
      expect(sessionRequested, isTrue);
      mockClient.close();
    });

    test('uploads file in correct chunk sizes', () async {
      final testFile = File('${tempDir.path}/chunk_size.m4a');
      testFile.writeAsBytesSync(Uint8List(fileSize));

      when(() => mockRepo.getRecordingById('rec-1')).thenAnswer(
        (_) async => LocalRecording(
          id: 'rec-1',
          projectId: 'proj-1',
          genreId: 'genre-1',
          subcategoryId: null,
          title: 'Test',
          durationSeconds: 60.0,
          fileSizeBytes: fileSize,
          format: 'm4a',
          localFilePath: testFile.path,
          uploadStatus: 'uploading',
          serverId: 'srv-1',
          gcsUrl: null,
          registerId: null,
          cleaningStatus: 'none',
          recordedAt: DateTime(2024, 1, 1),
          createdAt: DateTime(2024, 1, 1),
          retryCount: 0,
          lastRetryAt: null,
          resumableSessionUri: null,
          uploadedBytes: 0,
          md5Hash: null,
        ),
      );

      when(
        () => mockRepo.updateRecording(any(), any()),
      ).thenAnswer((_) async => true);

      final capturedRanges = <String>[];

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('resumable-upload-url')) {
          return http.Response(jsonEncode({'session_uri': sessionUri}), 200);
        }
        if (request.url.host == 'storage.googleapis.com') {
          final range = request.headers['content-range'];
          if (range != null && !range.contains('*')) {
            capturedRanges.add(range);
          }
          return http.Response('', 200);
        }
        return http.Response('', 404);
      });

      final authClient = AuthenticatedClient(
        client: mockClient,
        storage: mockStorage,
      );

      final service = ResumableUploadService(
        client: authClient,
        recordingRepo: mockRepo,
      );

      await service.upload(
        recordingId: 'rec-1',
        serverId: 'srv-1',
        localFilePath: testFile.path,
        format: 'm4a',
        fileSizeBytes: fileSize,
      );

      expect(capturedRanges, hasLength(1));
      expect(capturedRanges[0], equals('bytes 0-${fileSize - 1}/$fileSize'));
      mockClient.close();
    });

    test('reports progress after each chunk via callback', () async {
      final testFile = File('${tempDir.path}/progress.m4a');
      testFile.writeAsBytesSync(Uint8List(fileSize));

      when(() => mockRepo.getRecordingById('rec-1')).thenAnswer(
        (_) async => LocalRecording(
          id: 'rec-1',
          projectId: 'proj-1',
          genreId: 'genre-1',
          subcategoryId: null,
          title: 'Test',
          durationSeconds: 60.0,
          fileSizeBytes: fileSize,
          format: 'm4a',
          localFilePath: testFile.path,
          uploadStatus: 'uploading',
          serverId: 'srv-1',
          gcsUrl: null,
          registerId: null,
          cleaningStatus: 'none',
          recordedAt: DateTime(2024, 1, 1),
          createdAt: DateTime(2024, 1, 1),
          retryCount: 0,
          lastRetryAt: null,
          resumableSessionUri: null,
          uploadedBytes: 0,
          md5Hash: null,
        ),
      );

      when(
        () => mockRepo.updateRecording(any(), any()),
      ).thenAnswer((_) async => true);

      final progressCalls = <(int, int)>[];

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('resumable-upload-url')) {
          return http.Response(jsonEncode({'session_uri': sessionUri}), 200);
        }
        if (request.url.host == 'storage.googleapis.com') {
          return http.Response('', 200);
        }
        return http.Response('', 404);
      });

      final authClient = AuthenticatedClient(
        client: mockClient,
        storage: mockStorage,
      );

      final service = ResumableUploadService(
        client: authClient,
        recordingRepo: mockRepo,
      );

      await service.upload(
        recordingId: 'rec-1',
        serverId: 'srv-1',
        localFilePath: testFile.path,
        format: 'm4a',
        fileSizeBytes: fileSize,
        onProgress: (sent, total) => progressCalls.add((sent, total)),
      );

      expect(progressCalls, isNotEmpty);
      expect(progressCalls.last, equals((fileSize, fileSize)));
      mockClient.close();
    });

    test('updates uploadedBytes in repo after each chunk', () async {
      final testFile = File('${tempDir.path}/update_bytes.m4a');
      testFile.writeAsBytesSync(Uint8List(fileSize));

      when(() => mockRepo.getRecordingById('rec-1')).thenAnswer(
        (_) async => LocalRecording(
          id: 'rec-1',
          projectId: 'proj-1',
          genreId: 'genre-1',
          subcategoryId: null,
          title: 'Test',
          durationSeconds: 60.0,
          fileSizeBytes: fileSize,
          format: 'm4a',
          localFilePath: testFile.path,
          uploadStatus: 'uploading',
          serverId: 'srv-1',
          gcsUrl: null,
          registerId: null,
          cleaningStatus: 'none',
          recordedAt: DateTime(2024, 1, 1),
          createdAt: DateTime(2024, 1, 1),
          retryCount: 0,
          lastRetryAt: null,
          resumableSessionUri: null,
          uploadedBytes: 0,
          md5Hash: null,
        ),
      );

      when(
        () => mockRepo.updateRecording(any(), any()),
      ).thenAnswer((_) async => true);

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('resumable-upload-url')) {
          return http.Response(jsonEncode({'session_uri': sessionUri}), 200);
        }
        if (request.url.host == 'storage.googleapis.com') {
          return http.Response('', 200);
        }
        return http.Response('', 404);
      });

      final authClient = AuthenticatedClient(
        client: mockClient,
        storage: mockStorage,
      );

      final service = ResumableUploadService(
        client: authClient,
        recordingRepo: mockRepo,
      );

      await service.upload(
        recordingId: 'rec-1',
        serverId: 'srv-1',
        localFilePath: testFile.path,
        format: 'm4a',
        fileSizeBytes: fileSize,
      );

      verify(
        () => mockRepo.updateRecording('rec-1', any()),
      ).called(greaterThanOrEqualTo(2));
      mockClient.close();
    });

    test('clears session data on completion', () async {
      final testFile = File('${tempDir.path}/clear_session.m4a');
      testFile.writeAsBytesSync(Uint8List(fileSize));

      when(() => mockRepo.getRecordingById('rec-1')).thenAnswer(
        (_) async => LocalRecording(
          id: 'rec-1',
          projectId: 'proj-1',
          genreId: 'genre-1',
          subcategoryId: null,
          title: 'Test',
          durationSeconds: 60.0,
          fileSizeBytes: fileSize,
          format: 'm4a',
          localFilePath: testFile.path,
          uploadStatus: 'uploading',
          serverId: 'srv-1',
          gcsUrl: null,
          registerId: null,
          cleaningStatus: 'none',
          recordedAt: DateTime(2024, 1, 1),
          createdAt: DateTime(2024, 1, 1),
          retryCount: 0,
          lastRetryAt: null,
          resumableSessionUri: null,
          uploadedBytes: 0,
          md5Hash: null,
        ),
      );

      final updateCalls = <LocalRecordingsCompanion>[];
      when(() => mockRepo.updateRecording(any(), any())).thenAnswer((
        inv,
      ) async {
        updateCalls.add(inv.positionalArguments[1] as LocalRecordingsCompanion);
        return true;
      });

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('resumable-upload-url')) {
          return http.Response(jsonEncode({'session_uri': sessionUri}), 200);
        }
        if (request.url.host == 'storage.googleapis.com') {
          return http.Response('', 200);
        }
        return http.Response('', 404);
      });

      final authClient = AuthenticatedClient(
        client: mockClient,
        storage: mockStorage,
      );

      final service = ResumableUploadService(
        client: authClient,
        recordingRepo: mockRepo,
      );

      await service.upload(
        recordingId: 'rec-1',
        serverId: 'srv-1',
        localFilePath: testFile.path,
        format: 'm4a',
        fileSizeBytes: fileSize,
      );

      final lastUpdate = updateCalls.last;
      expect(lastUpdate.resumableSessionUri.present, isTrue);
      expect(lastUpdate.resumableSessionUri.value, isNull);
      expect(lastUpdate.uploadedBytes.present, isTrue);
      expect(lastUpdate.uploadedBytes.value, equals(0));
      mockClient.close();
    });
  });

  group('resumable upload - resume existing session', () {
    late MockRecordingRepo mockRepo;
    late MockSecureStorage mockStorage;
    const existingSessionUri =
        'https://storage.googleapis.com/upload/existing-session';
    const fileSize = 5 * 1024 * 1024;
    const alreadyUploaded = 2 * 1024 * 1024;

    setUp(() {
      mockRepo = MockRecordingRepo();
      mockStorage = MockSecureStorage();
      when(
        () => mockStorage.read(key: any(named: 'key')),
      ).thenAnswer((_) async => 'test-token');
    });

    test('reuses existing session URI from recording', () async {
      final testFile = File('${tempDir.path}/resume.m4a');
      testFile.writeAsBytesSync(Uint8List(fileSize));

      when(() => mockRepo.getRecordingById('rec-1')).thenAnswer(
        (_) async => LocalRecording(
          id: 'rec-1',
          projectId: 'proj-1',
          genreId: 'genre-1',
          subcategoryId: null,
          title: 'Test',
          durationSeconds: 60.0,
          fileSizeBytes: fileSize,
          format: 'm4a',
          localFilePath: testFile.path,
          uploadStatus: 'uploading',
          serverId: 'srv-1',
          gcsUrl: null,
          registerId: null,
          cleaningStatus: 'none',
          recordedAt: DateTime(2024, 1, 1),
          createdAt: DateTime(2024, 1, 1),
          retryCount: 0,
          lastRetryAt: null,
          resumableSessionUri: existingSessionUri,
          uploadedBytes: alreadyUploaded,
          md5Hash: null,
        ),
      );

      when(
        () => mockRepo.updateRecording(any(), any()),
      ).thenAnswer((_) async => true);

      var sessionCreated = false;

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('resumable-upload-url')) {
          sessionCreated = true;
          return http.Response(
            jsonEncode({
              'session_uri':
                  'https://storage.googleapis.com/upload/new-session',
            }),
            200,
          );
        }
        if (request.url.host == 'storage.googleapis.com') {
          final range = request.headers['content-range'];
          if (range != null && range.contains('*')) {
            return http.Response(
              '',
              308,
              headers: {'range': 'bytes=0-${alreadyUploaded - 1}'},
            );
          }
          return http.Response('', 200);
        }
        return http.Response('', 404);
      });

      final authClient = AuthenticatedClient(
        client: mockClient,
        storage: mockStorage,
      );

      final service = ResumableUploadService(
        client: authClient,
        recordingRepo: mockRepo,
      );

      final result = await service.upload(
        recordingId: 'rec-1',
        serverId: 'srv-1',
        localFilePath: testFile.path,
        format: 'm4a',
        fileSizeBytes: fileSize,
      );

      expect(result.success, isTrue);
      expect(sessionCreated, isFalse);
      mockClient.close();
    });

    test('queries server for current offset', () async {
      final testFile = File('${tempDir.path}/query_offset.m4a');
      testFile.writeAsBytesSync(Uint8List(fileSize));

      when(() => mockRepo.getRecordingById('rec-1')).thenAnswer(
        (_) async => LocalRecording(
          id: 'rec-1',
          projectId: 'proj-1',
          genreId: 'genre-1',
          subcategoryId: null,
          title: 'Test',
          durationSeconds: 60.0,
          fileSizeBytes: fileSize,
          format: 'm4a',
          localFilePath: testFile.path,
          uploadStatus: 'uploading',
          serverId: 'srv-1',
          gcsUrl: null,
          registerId: null,
          cleaningStatus: 'none',
          recordedAt: DateTime(2024, 1, 1),
          createdAt: DateTime(2024, 1, 1),
          retryCount: 0,
          lastRetryAt: null,
          resumableSessionUri: existingSessionUri,
          uploadedBytes: alreadyUploaded,
          md5Hash: null,
        ),
      );

      when(
        () => mockRepo.updateRecording(any(), any()),
      ).thenAnswer((_) async => true);

      var offsetQueried = false;

      final mockClient = MockClient((request) async {
        if (request.url.host == 'storage.googleapis.com') {
          final range = request.headers['content-range'];
          if (range != null && range.contains('*')) {
            offsetQueried = true;
            return http.Response(
              '',
              308,
              headers: {'range': 'bytes=0-${alreadyUploaded - 1}'},
            );
          }
          return http.Response('', 200);
        }
        return http.Response('', 404);
      });

      final authClient = AuthenticatedClient(
        client: mockClient,
        storage: mockStorage,
      );

      final service = ResumableUploadService(
        client: authClient,
        recordingRepo: mockRepo,
      );

      await service.upload(
        recordingId: 'rec-1',
        serverId: 'srv-1',
        localFilePath: testFile.path,
        format: 'm4a',
        fileSizeBytes: fileSize,
      );

      expect(offsetQueried, isTrue);
      mockClient.close();
    });

    test('resumes from the offset returned by server', () async {
      final testFile = File('${tempDir.path}/resume_offset.m4a');
      testFile.writeAsBytesSync(Uint8List(fileSize));

      when(() => mockRepo.getRecordingById('rec-1')).thenAnswer(
        (_) async => LocalRecording(
          id: 'rec-1',
          projectId: 'proj-1',
          genreId: 'genre-1',
          subcategoryId: null,
          title: 'Test',
          durationSeconds: 60.0,
          fileSizeBytes: fileSize,
          format: 'm4a',
          localFilePath: testFile.path,
          uploadStatus: 'uploading',
          serverId: 'srv-1',
          gcsUrl: null,
          registerId: null,
          cleaningStatus: 'none',
          recordedAt: DateTime(2024, 1, 1),
          createdAt: DateTime(2024, 1, 1),
          retryCount: 0,
          lastRetryAt: null,
          resumableSessionUri: existingSessionUri,
          uploadedBytes: alreadyUploaded,
          md5Hash: null,
        ),
      );

      when(
        () => mockRepo.updateRecording(any(), any()),
      ).thenAnswer((_) async => true);

      final capturedRanges = <String>[];

      final mockClient = MockClient((request) async {
        if (request.url.host == 'storage.googleapis.com') {
          final range = request.headers['content-range'];
          if (range != null && range.contains('*')) {
            return http.Response(
              '',
              308,
              headers: {'range': 'bytes=0-${alreadyUploaded - 1}'},
            );
          }
          if (range != null) {
            capturedRanges.add(range);
          }
          return http.Response('', 200);
        }
        return http.Response('', 404);
      });

      final authClient = AuthenticatedClient(
        client: mockClient,
        storage: mockStorage,
      );

      final service = ResumableUploadService(
        client: authClient,
        recordingRepo: mockRepo,
      );

      await service.upload(
        recordingId: 'rec-1',
        serverId: 'srv-1',
        localFilePath: testFile.path,
        format: 'm4a',
        fileSizeBytes: fileSize,
      );

      expect(capturedRanges, hasLength(1));
      expect(
        capturedRanges[0],
        equals('bytes $alreadyUploaded-${fileSize - 1}/$fileSize'),
      );
      mockClient.close();
    });
  });

  group('resumable upload - session expiry', () {
    late MockRecordingRepo mockRepo;
    late MockSecureStorage mockStorage;
    const fileSize = 5 * 1024 * 1024;

    setUp(() {
      mockRepo = MockRecordingRepo();
      mockStorage = MockSecureStorage();
      when(
        () => mockStorage.read(key: any(named: 'key')),
      ).thenAnswer((_) async => 'test-token');
    });

    test(
      'on 410 response creates new session and retries from beginning',
      () async {
        final testFile = File('${tempDir.path}/expiry.m4a');
        testFile.writeAsBytesSync(Uint8List(fileSize));

        when(() => mockRepo.getRecordingById('rec-1')).thenAnswer(
          (_) async => LocalRecording(
            id: 'rec-1',
            projectId: 'proj-1',
            genreId: 'genre-1',
            subcategoryId: null,
            title: 'Test',
            durationSeconds: 60.0,
            fileSizeBytes: fileSize,
            format: 'm4a',
            localFilePath: testFile.path,
            uploadStatus: 'uploading',
            serverId: 'srv-1',
            gcsUrl: null,
            registerId: null,
            cleaningStatus: 'none',
            recordedAt: DateTime(2024, 1, 1),
            createdAt: DateTime(2024, 1, 1),
            retryCount: 0,
            lastRetryAt: null,
            resumableSessionUri: null,
            uploadedBytes: 0,
            md5Hash: null,
          ),
        );

        final updateCalls = <LocalRecordingsCompanion>[];
        when(() => mockRepo.updateRecording(any(), any())).thenAnswer((
          inv,
        ) async {
          updateCalls.add(
            inv.positionalArguments[1] as LocalRecordingsCompanion,
          );
          return true;
        });

        var sessionCreateCount = 0;
        var chunkPutCount = 0;

        final mockClient = MockClient((request) async {
          if (request.url.path.contains('resumable-upload-url')) {
            sessionCreateCount++;
            return http.Response(
              jsonEncode({
                'session_uri':
                    'https://storage.googleapis.com/upload/session-$sessionCreateCount',
              }),
              200,
            );
          }
          if (request.url.host == 'storage.googleapis.com') {
            final range = request.headers['content-range'];
            if (range != null && !range.contains('*')) {
              chunkPutCount++;
              if (chunkPutCount == 1) return http.Response('', 410);
              return http.Response('', 200);
            }
          }
          return http.Response('', 404);
        });

        final authClient = AuthenticatedClient(
          client: mockClient,
          storage: mockStorage,
        );

        final service = ResumableUploadService(
          client: authClient,
          recordingRepo: mockRepo,
        );

        final result = await service.upload(
          recordingId: 'rec-1',
          serverId: 'srv-1',
          localFilePath: testFile.path,
          format: 'm4a',
          fileSizeBytes: fileSize,
        );

        expect(result.success, isTrue);
        expect(sessionCreateCount, 2);

        final resetUpdate = updateCalls.firstWhere(
          (c) =>
              c.uploadedBytes.present &&
              c.uploadedBytes.value == 0 &&
              c.resumableSessionUri.present &&
              c.resumableSessionUri.value != null,
        );
        expect(resetUpdate, isNotNull);
        mockClient.close();
      },
    );
  });

  group('resumable upload - multi-chunk', () {
    late MockRecordingRepo mockRepo;
    late MockSecureStorage mockStorage;
    const sessionUri = 'https://storage.googleapis.com/upload/multi-chunk';
    const fileSize = 12 * 1024 * 1024;
    const chunkSize = 8 * 1024 * 1024;

    setUp(() {
      mockRepo = MockRecordingRepo();
      mockStorage = MockSecureStorage();
      when(
        () => mockStorage.read(key: any(named: 'key')),
      ).thenAnswer((_) async => 'test-token');
    });

    test('splits file larger than 8MB into multiple chunks', () async {
      final testFile = File('${tempDir.path}/multi_chunk.m4a');
      testFile.writeAsBytesSync(Uint8List(fileSize));

      when(() => mockRepo.getRecordingById('rec-1')).thenAnswer(
        (_) async => LocalRecording(
          id: 'rec-1',
          projectId: 'proj-1',
          genreId: 'genre-1',
          subcategoryId: null,
          title: 'Test',
          durationSeconds: 60.0,
          fileSizeBytes: fileSize,
          format: 'm4a',
          localFilePath: testFile.path,
          uploadStatus: 'uploading',
          serverId: 'srv-1',
          gcsUrl: null,
          registerId: null,
          cleaningStatus: 'none',
          recordedAt: DateTime(2024, 1, 1),
          createdAt: DateTime(2024, 1, 1),
          retryCount: 0,
          lastRetryAt: null,
          resumableSessionUri: null,
          uploadedBytes: 0,
          md5Hash: null,
        ),
      );

      when(
        () => mockRepo.updateRecording(any(), any()),
      ).thenAnswer((_) async => true);

      final capturedRanges = <String>[];

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('resumable-upload-url')) {
          return http.Response(jsonEncode({'session_uri': sessionUri}), 200);
        }
        if (request.url.host == 'storage.googleapis.com') {
          final range = request.headers['content-range'];
          if (range != null && !range.contains('*')) {
            capturedRanges.add(range);
            if (capturedRanges.length < 2) return http.Response('', 308);
            return http.Response('', 200);
          }
        }
        return http.Response('', 404);
      });

      final authClient = AuthenticatedClient(
        client: mockClient,
        storage: mockStorage,
      );

      final service = ResumableUploadService(
        client: authClient,
        recordingRepo: mockRepo,
      );

      final result = await service.upload(
        recordingId: 'rec-1',
        serverId: 'srv-1',
        localFilePath: testFile.path,
        format: 'm4a',
        fileSizeBytes: fileSize,
      );

      expect(result.success, isTrue);
      expect(capturedRanges, hasLength(2));
      expect(capturedRanges[0], equals('bytes 0-${chunkSize - 1}/$fileSize'));
      expect(
        capturedRanges[1],
        equals('bytes $chunkSize-${fileSize - 1}/$fileSize'),
      );
      mockClient.close();
    });

    test('reports progress for all chunks', () async {
      final testFile = File('${tempDir.path}/multi_progress.m4a');
      testFile.writeAsBytesSync(Uint8List(fileSize));

      when(() => mockRepo.getRecordingById('rec-1')).thenAnswer(
        (_) async => LocalRecording(
          id: 'rec-1',
          projectId: 'proj-1',
          genreId: 'genre-1',
          subcategoryId: null,
          title: 'Test',
          durationSeconds: 60.0,
          fileSizeBytes: fileSize,
          format: 'm4a',
          localFilePath: testFile.path,
          uploadStatus: 'uploading',
          serverId: 'srv-1',
          gcsUrl: null,
          registerId: null,
          cleaningStatus: 'none',
          recordedAt: DateTime(2024, 1, 1),
          createdAt: DateTime(2024, 1, 1),
          retryCount: 0,
          lastRetryAt: null,
          resumableSessionUri: null,
          uploadedBytes: 0,
          md5Hash: null,
        ),
      );

      when(
        () => mockRepo.updateRecording(any(), any()),
      ).thenAnswer((_) async => true);

      final progressCalls = <(int, int)>[];
      var chunkCount = 0;

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('resumable-upload-url')) {
          return http.Response(jsonEncode({'session_uri': sessionUri}), 200);
        }
        if (request.url.host == 'storage.googleapis.com') {
          final range = request.headers['content-range'];
          if (range != null && !range.contains('*')) {
            chunkCount++;
            if (chunkCount < 2) return http.Response('', 308);
            return http.Response('', 200);
          }
        }
        return http.Response('', 404);
      });

      final authClient = AuthenticatedClient(
        client: mockClient,
        storage: mockStorage,
      );

      final service = ResumableUploadService(
        client: authClient,
        recordingRepo: mockRepo,
      );

      await service.upload(
        recordingId: 'rec-1',
        serverId: 'srv-1',
        localFilePath: testFile.path,
        format: 'm4a',
        fileSizeBytes: fileSize,
        onProgress: (sent, total) => progressCalls.add((sent, total)),
      );

      expect(progressCalls, hasLength(2));
      expect(progressCalls[0], equals((chunkSize, fileSize)));
      expect(progressCalls[1], equals((fileSize, fileSize)));
      mockClient.close();
    });
  });

  group('resumable upload - error handling', () {
    late MockRecordingRepo mockRepo;
    late MockSecureStorage mockStorage;
    const fileSize = 5 * 1024 * 1024;

    setUp(() {
      mockRepo = MockRecordingRepo();
      mockStorage = MockSecureStorage();
      when(
        () => mockStorage.read(key: any(named: 'key')),
      ).thenAnswer((_) async => 'test-token');
    });

    test('returns failure when session creation fails', () async {
      final testFile = File('${tempDir.path}/fail_session.m4a');
      testFile.writeAsBytesSync(Uint8List(fileSize));

      when(() => mockRepo.getRecordingById('rec-1')).thenAnswer(
        (_) async => LocalRecording(
          id: 'rec-1',
          projectId: 'proj-1',
          genreId: 'genre-1',
          subcategoryId: null,
          title: 'Test',
          durationSeconds: 60.0,
          fileSizeBytes: fileSize,
          format: 'm4a',
          localFilePath: testFile.path,
          uploadStatus: 'uploading',
          serverId: 'srv-1',
          gcsUrl: null,
          registerId: null,
          cleaningStatus: 'none',
          recordedAt: DateTime(2024, 1, 1),
          createdAt: DateTime(2024, 1, 1),
          retryCount: 0,
          lastRetryAt: null,
          resumableSessionUri: null,
          uploadedBytes: 0,
          md5Hash: null,
        ),
      );

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('resumable-upload-url')) {
          return http.Response('Server Error', 500);
        }
        return http.Response('', 404);
      });

      final authClient = AuthenticatedClient(
        client: mockClient,
        storage: mockStorage,
      );

      final service = ResumableUploadService(
        client: authClient,
        recordingRepo: mockRepo,
      );

      final result = await service.upload(
        recordingId: 'rec-1',
        serverId: 'srv-1',
        localFilePath: testFile.path,
        format: 'm4a',
        fileSizeBytes: fileSize,
      );

      expect(result.success, isFalse);
      expect(
        result.error,
        contains('Failed to create resumable upload session'),
      );
      mockClient.close();
    });

    test('returns failure when chunk upload fails', () async {
      final testFile = File('${tempDir.path}/fail_chunk.m4a');
      testFile.writeAsBytesSync(Uint8List(fileSize));

      when(() => mockRepo.getRecordingById('rec-1')).thenAnswer(
        (_) async => LocalRecording(
          id: 'rec-1',
          projectId: 'proj-1',
          genreId: 'genre-1',
          subcategoryId: null,
          title: 'Test',
          durationSeconds: 60.0,
          fileSizeBytes: fileSize,
          format: 'm4a',
          localFilePath: testFile.path,
          uploadStatus: 'uploading',
          serverId: 'srv-1',
          gcsUrl: null,
          registerId: null,
          cleaningStatus: 'none',
          recordedAt: DateTime(2024, 1, 1),
          createdAt: DateTime(2024, 1, 1),
          retryCount: 0,
          lastRetryAt: null,
          resumableSessionUri: null,
          uploadedBytes: 0,
          md5Hash: null,
        ),
      );

      when(
        () => mockRepo.updateRecording(any(), any()),
      ).thenAnswer((_) async => true);

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('resumable-upload-url')) {
          return http.Response(
            jsonEncode({
              'session_uri':
                  'https://storage.googleapis.com/upload/session-fail',
            }),
            200,
          );
        }
        if (request.url.host == 'storage.googleapis.com') {
          return http.Response('Internal Server Error', 500);
        }
        return http.Response('', 404);
      });

      final authClient = AuthenticatedClient(
        client: mockClient,
        storage: mockStorage,
      );

      final service = ResumableUploadService(
        client: authClient,
        recordingRepo: mockRepo,
      );

      final result = await service.upload(
        recordingId: 'rec-1',
        serverId: 'srv-1',
        localFilePath: testFile.path,
        format: 'm4a',
        fileSizeBytes: fileSize,
      );

      expect(result.success, isFalse);
      expect(result.error, contains('Chunk upload failed'));
      mockClient.close();
    });

    test('returns failure when recording not found in repo', () async {
      final testFile = File('${tempDir.path}/not_found.m4a');
      testFile.writeAsBytesSync(Uint8List(fileSize));

      when(
        () => mockRepo.getRecordingById('rec-missing'),
      ).thenAnswer((_) async => null);

      final mockClient = MockClient((request) async {
        return http.Response('', 404);
      });

      final authClient = AuthenticatedClient(
        client: mockClient,
        storage: mockStorage,
      );

      final service = ResumableUploadService(
        client: authClient,
        recordingRepo: mockRepo,
      );

      final result = await service.upload(
        recordingId: 'rec-missing',
        serverId: 'srv-1',
        localFilePath: testFile.path,
        format: 'm4a',
        fileSizeBytes: fileSize,
      );

      expect(result.success, isFalse);
      expect(result.error, contains('Recording not found'));
      mockClient.close();
    });
  });
}
