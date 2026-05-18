import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/core/network/authenticated_client.dart';
import 'package:oral_collector/features/recording/data/repositories/local_recording_repository.dart';
import 'package:oral_collector/features/sync/data/services/resumable_upload_service.dart';
import 'package:oral_collector/features/sync/data/services/upload_downloader.dart';

class MockRecordingRepo extends Mock implements LocalRecordingRepository {}

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

class FakeLocalRecordingsCompanion extends Fake
    implements LocalRecordingsCompanion {}

class _ChunkCall {
  final String taskId;
  final String url;
  final String filePath;
  final int offset;
  final int end;
  final Map<String, String> headers;
  _ChunkCall({
    required this.taskId,
    required this.url,
    required this.filePath,
    required this.offset,
    required this.end,
    required this.headers,
  });
}

class _StubDownloader implements UploadDownloader {
  _StubDownloader({List<UploadResult>? responses})
    : _responses = responses != null ? List<UploadResult>.from(responses) : [];

  final List<UploadResult> _responses;
  final List<_ChunkCall> calls = [];
  bool cancelCalled = false;
  String? lastCancelledTaskId;

  void enqueueResponse(UploadResult result) => _responses.add(result);

  @override
  Future<UploadResult> putChunk({
    required String taskId,
    required String url,
    required String filePath,
    required int offset,
    required int end,
    required Map<String, String> headers,
  }) async {
    calls.add(
      _ChunkCall(
        taskId: taskId,
        url: url,
        filePath: filePath,
        offset: offset,
        end: end,
        headers: Map.from(headers),
      ),
    );
    if (_responses.isEmpty) {
      return const UploadResult(statusCode: 200);
    }
    return _responses.removeAt(0);
  }

  @override
  Future<void> cancel(String taskId) async {
    cancelCalled = true;
    lastCancelledTaskId = taskId;
  }

  @override
  Future<void> cancelAll() async {
    cancelCalled = true;
  }

  @override
  Future<void> resumeAfterCancel() async {}
}

LocalRecording _seedRecording({
  required String id,
  required int fileSizeBytes,
  required String filePath,
  String? resumableSessionUri,
  int uploadedBytes = 0,
}) {
  return LocalRecording(
    id: id,
    projectId: 'proj-1',
    genreId: 'genre-1',
    subcategoryId: null,
    title: 'Test',
    durationSeconds: 60.0,
    fileSizeBytes: fileSizeBytes,
    format: 'm4a',
    localFilePath: filePath,
    uploadStatus: 'uploading',
    serverId: 'srv-1',
    gcsUrl: null,
    registerId: null,
    cleaningStatus: 'none',
    recordedAt: DateTime(2024, 1, 1),
    createdAt: DateTime(2024, 1, 1),
    retryCount: 0,
    lastRetryAt: null,
    resumableSessionUri: resumableSessionUri,
    uploadedBytes: uploadedBytes,
    md5Hash: null,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late MockRecordingRepo mockRepo;
  late MockSecureStorage mockStorage;
  late _StubDownloader fakeDownloader;
  const sessionUri = 'https://storage.googleapis.com/upload/session-123';
  const chunkSize = 8 * 1024 * 1024;

  setUpAll(() {
    registerFallbackValue(FakeLocalRecordingsCompanion());
    registerFallbackValue('');
    dotenv.testLoad(fileInput: 'BACKEND_URL=http://localhost:8080');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    tempDir = Directory.systemTemp.createTempSync('upload_test');
    mockRepo = MockRecordingRepo();
    mockStorage = MockSecureStorage();
    fakeDownloader = _StubDownloader();
    when(
      () => mockStorage.read(key: any(named: 'key')),
    ).thenAnswer((_) async => 'test-token');
    when(
      () => mockRepo.updateRecording(any(), any()),
    ).thenAnswer((_) async => true);
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  ResumableUploadService buildService({MockClient? httpClient}) {
    final client =
        httpClient ?? MockClient((_) async => http.Response('', 404));
    final authClient = AuthenticatedClient(
      client: client,
      storage: mockStorage,
    );
    return ResumableUploadService(
      client: authClient,
      recordingRepo: mockRepo,
      downloader: fakeDownloader,
    );
  }

  group('ResumableUploadResult', () {
    test('success result', () {
      const result = ResumableUploadResult(success: true);
      expect(result.success, isTrue);
      expect(result.error, isNull);
      expect(result.pausedByRecording, isFalse);
    });

    test('paused_by_recording is exposed as a typed flag', () {
      const result = ResumableUploadResult(
        success: false,
        error: pausedByRecordingError,
      );
      expect(result.pausedByRecording, isTrue);
    });
  });

  group('RecordingActiveFlag gate (§1 mutex)', () {
    test(
      'returns paused_by_recording without enqueueing any chunk when flag is active',
      () async {
        SharedPreferences.setMockInitialValues({
          'com.shema.oralCollector.is_recording_active': true,
        });
        final testFile = File('${tempDir.path}/x.m4a');
        testFile.writeAsBytesSync(Uint8List(1024));

        final service = buildService();
        final result = await service.upload(
          recordingId: 'rec-1',
          serverId: 'srv-1',
          localFilePath: testFile.path,
          format: 'm4a',
          fileSizeBytes: 1024,
        );

        expect(result.pausedByRecording, isTrue);
        expect(fakeDownloader.calls, isEmpty);
      },
    );
  });

  group('single PUT upload (< 5 MB)', () {
    test('uploads small file via downloader with offset 0', () async {
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
        return http.Response('', 404);
      });

      fakeDownloader.enqueueResponse(const UploadResult(statusCode: 200));

      final service = buildService(httpClient: mockClient);
      final result = await service.upload(
        recordingId: 'rec-1',
        serverId: 'srv-1',
        localFilePath: testFile.path,
        format: 'm4a',
        fileSizeBytes: 1024,
      );

      expect(result.success, isTrue);
      expect(fakeDownloader.calls, hasLength(1));
      final call = fakeDownloader.calls.first;
      expect(call.offset, 0);
      expect(call.end, 1024);
      expect(call.url, 'https://storage.googleapis.com/test');
      expect(call.headers['Content-Type'], 'audio/mp4');
    });

    test('retries once on 403 expired URL', () async {
      final testFile = File('${tempDir.path}/expired.m4a');
      testFile.writeAsBytesSync(Uint8List(512));

      var urlRequests = 0;
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('upload-url')) {
          urlRequests++;
          return http.Response(
            jsonEncode({
              'upload_url': 'https://storage.googleapis.com/test',
              'content_type': 'audio/mp4',
            }),
            200,
          );
        }
        return http.Response('', 404);
      });

      fakeDownloader.enqueueResponse(const UploadResult(statusCode: 403));
      fakeDownloader.enqueueResponse(const UploadResult(statusCode: 200));

      final service = buildService(httpClient: mockClient);
      final result = await service.upload(
        recordingId: 'rec-1',
        serverId: 'srv-1',
        localFilePath: testFile.path,
        format: 'm4a',
        fileSizeBytes: 512,
      );

      expect(result.success, isTrue);
      expect(urlRequests, 2);
      expect(fakeDownloader.calls, hasLength(2));
    });

    test('reports progress via callback after success', () async {
      final testFile = File('${tempDir.path}/progress.m4a');
      testFile.writeAsBytesSync(Uint8List(2048));

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'upload_url': 'https://storage.googleapis.com/test',
            'content_type': 'audio/mp4',
          }),
          200,
        );
      });

      fakeDownloader.enqueueResponse(const UploadResult(statusCode: 200));

      var sentBytes = 0;
      var totalBytes = 0;
      final service = buildService(httpClient: mockClient);
      await service.upload(
        recordingId: 'rec-1',
        serverId: 'srv-1',
        localFilePath: testFile.path,
        format: 'm4a',
        fileSizeBytes: 2048,
        onProgress: (sent, total) {
          sentBytes = sent;
          totalBytes = total;
        },
      );

      expect(sentBytes, 2048);
      expect(totalBytes, 2048);
    });

    test('fails when upload-url endpoint fails', () async {
      final testFile = File('${tempDir.path}/x.m4a');
      testFile.writeAsBytesSync(Uint8List(256));

      final mockClient = MockClient((request) async => http.Response('', 500));

      final service = buildService(httpClient: mockClient);
      final result = await service.upload(
        recordingId: 'rec-1',
        serverId: 'srv-1',
        localFilePath: testFile.path,
        format: 'm4a',
        fileSizeBytes: 256,
      );

      expect(result.success, isFalse);
      expect(fakeDownloader.calls, isEmpty);
    });
  });

  group('resumable upload (>= 5 MB)', () {
    const fileSize = 5 * 1024 * 1024;

    test('creates a new resumable session when none exists', () async {
      final testFile = File('${tempDir.path}/r.m4a');
      testFile.writeAsBytesSync(Uint8List(fileSize));

      when(() => mockRepo.getRecordingById('rec-1')).thenAnswer(
        (_) async => _seedRecording(
          id: 'rec-1',
          fileSizeBytes: fileSize,
          filePath: testFile.path,
        ),
      );

      var sessionRequested = false;
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('resumable-upload-url')) {
          sessionRequested = true;
          return http.Response(jsonEncode({'session_uri': sessionUri}), 200);
        }
        return http.Response('', 404);
      });

      fakeDownloader.enqueueResponse(const UploadResult(statusCode: 200));

      final service = buildService(httpClient: mockClient);
      final result = await service.upload(
        recordingId: 'rec-1',
        serverId: 'srv-1',
        localFilePath: testFile.path,
        format: 'm4a',
        fileSizeBytes: fileSize,
      );

      expect(result.success, isTrue);
      expect(sessionRequested, isTrue);
      expect(fakeDownloader.calls.single.url, sessionUri);
    });

    test(
      'chunk Content-Range header reflects offset, end, fileLength',
      () async {
        final testFile = File('${tempDir.path}/cr.m4a');
        testFile.writeAsBytesSync(Uint8List(fileSize));

        when(() => mockRepo.getRecordingById('rec-1')).thenAnswer(
          (_) async => _seedRecording(
            id: 'rec-1',
            fileSizeBytes: fileSize,
            filePath: testFile.path,
            resumableSessionUri: sessionUri,
          ),
        );

        // Query-offset call returns 308 + Range: bytes=0-(fileSize-1) but
        // for a fresh-but-known sessionUri we return Range: bytes=0-0 which
        // the service uses as offset=1. Easier: have query return 0 bytes
        // received (no range header), so service starts at offset=0.
        final mockClient = MockClient((request) async {
          if (request.method == 'PUT' &&
              request.headers['Content-Range'] == 'bytes */$fileSize') {
            // query-offset response: 308 with no range header means offset=0
            return http.Response('', 308);
          }
          return http.Response('', 404);
        });

        fakeDownloader.enqueueResponse(const UploadResult(statusCode: 200));

        final service = buildService(httpClient: mockClient);
        await service.upload(
          recordingId: 'rec-1',
          serverId: 'srv-1',
          localFilePath: testFile.path,
          format: 'm4a',
          fileSizeBytes: fileSize,
        );

        // 5 MB fits in a single 8 MB chunk → 1 putChunk call.
        expect(fakeDownloader.calls, hasLength(1));
        final call = fakeDownloader.calls.first;
        expect(call.offset, 0);
        expect(call.end, fileSize);
        expect(
          call.headers['Content-Range'],
          'bytes 0-${fileSize - 1}/$fileSize',
        );
      },
    );

    test('persists uploadedBytes in repo after each chunk commit', () async {
      const bigFile = 12 * 1024 * 1024; // forces 2 chunks
      final testFile = File('${tempDir.path}/big.m4a');
      testFile.writeAsBytesSync(Uint8List(bigFile));

      when(() => mockRepo.getRecordingById('rec-1')).thenAnswer(
        (_) async => _seedRecording(
          id: 'rec-1',
          fileSizeBytes: bigFile,
          filePath: testFile.path,
        ),
      );

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('resumable-upload-url')) {
          return http.Response(jsonEncode({'session_uri': sessionUri}), 200);
        }
        return http.Response('', 404);
      });

      fakeDownloader.enqueueResponse(const UploadResult(statusCode: 308));
      fakeDownloader.enqueueResponse(const UploadResult(statusCode: 200));

      final service = buildService(httpClient: mockClient);
      final result = await service.upload(
        recordingId: 'rec-1',
        serverId: 'srv-1',
        localFilePath: testFile.path,
        format: 'm4a',
        fileSizeBytes: bigFile,
      );

      expect(result.success, isTrue);
      // 2 chunks: 0..8MB then 8MB..12MB.
      expect(fakeDownloader.calls, hasLength(2));
      expect(fakeDownloader.calls[0].offset, 0);
      expect(fakeDownloader.calls[0].end, chunkSize);
      expect(fakeDownloader.calls[1].offset, chunkSize);
      expect(fakeDownloader.calls[1].end, bigFile);

      // First chunk persists uploadedBytes=8MB, then session cleared on done.
      // We expect updateRecording calls including offsets after each chunk.
      verify(
        () => mockRepo.updateRecording(any(), any()),
      ).called(greaterThanOrEqualTo(2));
    });

    test(
      '410 response triggers fresh session and resets offset to 0',
      () async {
        const bigFile = 12 * 1024 * 1024;
        final testFile = File('${tempDir.path}/expired_session.m4a');
        testFile.writeAsBytesSync(Uint8List(bigFile));

        when(() => mockRepo.getRecordingById('rec-1')).thenAnswer(
          (_) async => _seedRecording(
            id: 'rec-1',
            fileSizeBytes: bigFile,
            filePath: testFile.path,
          ),
        );

        var sessionCallCount = 0;
        final mockClient = MockClient((request) async {
          if (request.url.path.contains('resumable-upload-url')) {
            sessionCallCount++;
            return http.Response(
              jsonEncode({'session_uri': '$sessionUri-$sessionCallCount'}),
              200,
            );
          }
          return http.Response('', 404);
        });

        fakeDownloader.enqueueResponse(const UploadResult(statusCode: 410));
        fakeDownloader.enqueueResponse(const UploadResult(statusCode: 308));
        fakeDownloader.enqueueResponse(const UploadResult(statusCode: 200));

        final service = buildService(httpClient: mockClient);
        final result = await service.upload(
          recordingId: 'rec-1',
          serverId: 'srv-1',
          localFilePath: testFile.path,
          format: 'm4a',
          fileSizeBytes: bigFile,
        );

        expect(result.success, isTrue);
        // Service requests 2 separate sessions: original + recreated.
        expect(sessionCallCount, 2);
      },
    );

    test('returns failure when a chunk PUT fails non-recoverably', () async {
      final testFile = File('${tempDir.path}/fail.m4a');
      testFile.writeAsBytesSync(Uint8List(fileSize));

      when(() => mockRepo.getRecordingById('rec-1')).thenAnswer(
        (_) async => _seedRecording(
          id: 'rec-1',
          fileSizeBytes: fileSize,
          filePath: testFile.path,
        ),
      );

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('resumable-upload-url')) {
          return http.Response(jsonEncode({'session_uri': sessionUri}), 200);
        }
        return http.Response('', 404);
      });

      fakeDownloader.enqueueResponse(
        const UploadResult(statusCode: 500, responseBody: 'server error'),
      );

      final service = buildService(httpClient: mockClient);
      final result = await service.upload(
        recordingId: 'rec-1',
        serverId: 'srv-1',
        localFilePath: testFile.path,
        format: 'm4a',
        fileSizeBytes: fileSize,
      );

      expect(result.success, isFalse);
      expect(result.pausedByRecording, isFalse);
    });

    test(
      'queryOffset == fileLength short-circuits to success AND clears session bookkeeping',
      () async {
        final testFile = File('${tempDir.path}/done.m4a');
        testFile.writeAsBytesSync(Uint8List(fileSize));

        when(() => mockRepo.getRecordingById('rec-1')).thenAnswer(
          (_) async => _seedRecording(
            id: 'rec-1',
            fileSizeBytes: fileSize,
            filePath: testFile.path,
            resumableSessionUri: sessionUri,
            uploadedBytes: fileSize,
          ),
        );

        final mockClient = MockClient((request) async {
          // GCS reports the upload is already done.
          return http.Response('', 200);
        });

        final service = buildService(httpClient: mockClient);
        final result = await service.upload(
          recordingId: 'rec-1',
          serverId: 'srv-1',
          localFilePath: testFile.path,
          format: 'm4a',
          fileSizeBytes: fileSize,
        );

        expect(result.success, isTrue);
        expect(fakeDownloader.calls, isEmpty);

        // Verify the stale session URI was cleared so the next sync run
        // doesn't waste a round-trip querying an exhausted URI.
        final captured = verify(
          () => mockRepo.updateRecording('rec-1', captureAny()),
        ).captured;
        final hasClearingUpdate = captured.any((companion) {
          final c = companion as LocalRecordingsCompanion;
          return c.resumableSessionUri.present &&
              c.resumableSessionUri.value == null;
        });
        expect(
          hasClearingUpdate,
          isTrue,
          reason: 'quickSuccess must null out resumableSessionUri',
        );
      },
    );

    test(
      'server-reported offset overrides client uploadedBytes when smaller',
      () async {
        // Scenario: client persisted 24 MB but GCS only committed 8 MB (e.g.,
        // we crashed after onProgress but before the DB write under the old
        // ordering, or the last chunk PUT was rolled back server-side).
        // Service must trust the server view and re-upload from 8 MB, not 24.
        const bigFile = 32 * 1024 * 1024;
        final testFile = File('${tempDir.path}/disagree.m4a');
        testFile.writeAsBytesSync(Uint8List(bigFile));

        when(() => mockRepo.getRecordingById('rec-1')).thenAnswer(
          (_) async => _seedRecording(
            id: 'rec-1',
            fileSizeBytes: bigFile,
            filePath: testFile.path,
            resumableSessionUri: sessionUri,
            uploadedBytes: 24 * 1024 * 1024, // client thinks 24
          ),
        );

        final mockClient = MockClient((request) async {
          if (request.headers['Content-Range'] == 'bytes */$bigFile') {
            // Server reports 8 MB committed (last byte = 8388607).
            return http.Response(
              '',
              308,
              headers: {'range': 'bytes=0-8388607'},
            );
          }
          return http.Response('', 404);
        });

        // From offset 8 MB → 16 MB → 24 MB → 32 MB = 3 chunks (8 MB each).
        fakeDownloader.enqueueResponse(const UploadResult(statusCode: 308));
        fakeDownloader.enqueueResponse(const UploadResult(statusCode: 308));
        fakeDownloader.enqueueResponse(const UploadResult(statusCode: 200));

        final service = buildService(httpClient: mockClient);
        final result = await service.upload(
          recordingId: 'rec-1',
          serverId: 'srv-1',
          localFilePath: testFile.path,
          format: 'm4a',
          fileSizeBytes: bigFile,
        );

        expect(result.success, isTrue);
        expect(fakeDownloader.calls, hasLength(3));
        // First chunk should resume from 8 MB (server-reported), NOT 24 MB.
        expect(fakeDownloader.calls.first.offset, 8 * 1024 * 1024);
      },
    );

    test(
      'server-reported offset is trusted even when greater than client uploadedBytes',
      () async {
        // Scenario: client persisted 0 (e.g., process killed right after
        // session-URI write but before any chunk write succeeded persistently)
        // but the previous run did manage to PUT chunk 0. Server should be
        // trusted; we skip the first chunk.
        const bigFile = 16 * 1024 * 1024;
        final testFile = File('${tempDir.path}/server_ahead.m4a');
        testFile.writeAsBytesSync(Uint8List(bigFile));

        when(() => mockRepo.getRecordingById('rec-1')).thenAnswer(
          (_) async => _seedRecording(
            id: 'rec-1',
            fileSizeBytes: bigFile,
            filePath: testFile.path,
            resumableSessionUri: sessionUri,
            uploadedBytes: 0, // client thinks zero
          ),
        );

        final mockClient = MockClient((request) async {
          if (request.headers['Content-Range'] == 'bytes */$bigFile') {
            // Server reports 8 MB already committed.
            return http.Response(
              '',
              308,
              headers: {'range': 'bytes=0-8388607'},
            );
          }
          return http.Response('', 404);
        });

        fakeDownloader.enqueueResponse(const UploadResult(statusCode: 200));

        final service = buildService(httpClient: mockClient);
        final result = await service.upload(
          recordingId: 'rec-1',
          serverId: 'srv-1',
          localFilePath: testFile.path,
          format: 'm4a',
          fileSizeBytes: bigFile,
        );

        expect(result.success, isTrue);
        // Only one chunk: from 8 MB to 16 MB.
        expect(fakeDownloader.calls, hasLength(1));
        expect(fakeDownloader.calls.first.offset, 8 * 1024 * 1024);
        expect(fakeDownloader.calls.first.end, bigFile);
      },
    );

    test(
      'cancelled chunk persists uploadedBytes from previous successful chunk',
      () async {
        // §1 invariant: when recording starts mid-upload, the cancellation
        // surfaces as paused_by_recording. The bytes from the chunk that
        // already succeeded must remain in the DB so the next resume picks
        // up where we left off (not zeroed back to 0).
        const bigFile = 24 * 1024 * 1024;
        final testFile = File('${tempDir.path}/cancel_mid.m4a');
        testFile.writeAsBytesSync(Uint8List(bigFile));

        when(() => mockRepo.getRecordingById('rec-1')).thenAnswer(
          (_) async => _seedRecording(
            id: 'rec-1',
            fileSizeBytes: bigFile,
            filePath: testFile.path,
          ),
        );

        final mockClient = MockClient((request) async {
          if (request.url.path.contains('resumable-upload-url')) {
            return http.Response(jsonEncode({'session_uri': sessionUri}), 200);
          }
          return http.Response('', 404);
        });

        // Chunk 1 succeeds (308), then chunk 2 is cancelled (recording starts).
        fakeDownloader.enqueueResponse(const UploadResult(statusCode: 308));
        fakeDownloader.enqueueResponse(
          const UploadResult(statusCode: 0, cancelled: true),
        );

        final service = buildService(httpClient: mockClient);
        final result = await service.upload(
          recordingId: 'rec-1',
          serverId: 'srv-1',
          localFilePath: testFile.path,
          format: 'm4a',
          fileSizeBytes: bigFile,
        );

        expect(result.pausedByRecording, isTrue);

        // Verify the DB was updated with uploadedBytes = 8 MB (the first
        // successful chunk's end offset). Capture all update calls and
        // confirm at least one wrote uploadedBytes = 8 MB.
        final captured = verify(
          () => mockRepo.updateRecording('rec-1', captureAny()),
        ).captured;
        final persistedOffsets = captured
            .map((c) => (c as LocalRecordingsCompanion).uploadedBytes)
            .where((v) => v.present)
            .map((v) => v.value)
            .toList();
        expect(
          persistedOffsets,
          contains(chunkSize),
          reason: 'first chunk\'s 8MB end offset must be in the DB',
        );
      },
    );

    test(
      'final chunk 200/201 terminates the loop AND clears session bookkeeping',
      () async {
        // Distinguish the terminal 200 from intermediate 308 — and confirm
        // the session URI and uploadedBytes are reset on completion.
        const bigFile = 16 * 1024 * 1024;
        final testFile = File('${tempDir.path}/terminal.m4a');
        testFile.writeAsBytesSync(Uint8List(bigFile));

        when(() => mockRepo.getRecordingById('rec-1')).thenAnswer(
          (_) async => _seedRecording(
            id: 'rec-1',
            fileSizeBytes: bigFile,
            filePath: testFile.path,
          ),
        );

        final mockClient = MockClient((request) async {
          if (request.url.path.contains('resumable-upload-url')) {
            return http.Response(jsonEncode({'session_uri': sessionUri}), 200);
          }
          return http.Response('', 404);
        });

        fakeDownloader.enqueueResponse(const UploadResult(statusCode: 308));
        fakeDownloader.enqueueResponse(const UploadResult(statusCode: 200));

        final service = buildService(httpClient: mockClient);
        final result = await service.upload(
          recordingId: 'rec-1',
          serverId: 'srv-1',
          localFilePath: testFile.path,
          format: 'm4a',
          fileSizeBytes: bigFile,
        );

        expect(result.success, isTrue);
        expect(fakeDownloader.calls, hasLength(2));
        // Verify the final chunk's Content-Range covers the last byte range.
        expect(
          fakeDownloader.calls[1].headers['Content-Range'],
          'bytes 8388608-${bigFile - 1}/$bigFile',
        );

        final captured = verify(
          () => mockRepo.updateRecording('rec-1', captureAny()),
        ).captured;
        final finalUpdate = captured.last as LocalRecordingsCompanion;
        expect(finalUpdate.resumableSessionUri.present, isTrue);
        expect(finalUpdate.resumableSessionUri.value, isNull);
      },
    );

    test('returns failure when recording not found in repo', () async {
      final testFile = File('${tempDir.path}/missing.m4a');
      testFile.writeAsBytesSync(Uint8List(fileSize));

      when(
        () => mockRepo.getRecordingById('rec-missing'),
      ).thenAnswer((_) async => null);

      final service = buildService();
      final result = await service.upload(
        recordingId: 'rec-missing',
        serverId: 'srv-1',
        localFilePath: testFile.path,
        format: 'm4a',
        fileSizeBytes: fileSize,
      );

      expect(result.success, isFalse);
    });

    test('cancelled chunk surfaces as paused_by_recording', () async {
      final testFile = File('${tempDir.path}/cancel.m4a');
      testFile.writeAsBytesSync(Uint8List(fileSize));

      when(() => mockRepo.getRecordingById('rec-1')).thenAnswer(
        (_) async => _seedRecording(
          id: 'rec-1',
          fileSizeBytes: fileSize,
          filePath: testFile.path,
        ),
      );

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('resumable-upload-url')) {
          return http.Response(jsonEncode({'session_uri': sessionUri}), 200);
        }
        return http.Response('', 404);
      });

      fakeDownloader.enqueueResponse(
        const UploadResult(statusCode: 0, cancelled: true),
      );

      final service = buildService(httpClient: mockClient);
      final result = await service.upload(
        recordingId: 'rec-1',
        serverId: 'srv-1',
        localFilePath: testFile.path,
        format: 'm4a',
        fileSizeBytes: fileSize,
      );

      expect(result.pausedByRecording, isTrue);
    });
  });
}
