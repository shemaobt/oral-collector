import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show MethodChannel;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oral_collector/core/config/upload_retry_policy.dart';
import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/core/network/authenticated_client.dart';
import 'package:oral_collector/features/recording/data/repositories/local_recording_repository.dart';
import 'package:oral_collector/features/storyteller/data/repositories/local_storyteller_repository.dart';
import 'package:oral_collector/features/sync/data/repositories/sync_engine.dart';
import 'package:oral_collector/features/sync/data/services/upload_downloader.dart';
import 'package:oral_collector/features/sync/domain/repositories/connectivity_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../support/sync_engine_api.dart';

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
  }) async {
    return const UploadResult(statusCode: 200);
  }

  @override
  Future<void> cancel(String taskId) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> resumeAfterCancel() async {}
}

class MockRecordingRepo extends Mock implements LocalRecordingRepository {}

class MockStorytellerRepo extends Mock implements LocalStorytellerRepository {}

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
  // Long enough to satisfy the create-time description rule (ENG-354), which is
  // what every recording the app saves carries.
  String? description = 'A description with enough substance to be accepted',
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
    reviewFlagsJson: '[]',
    // The metadata outbox defaults (ENG-403): this row owes the server no edit.
    metadataSyncStatus: 'synced',
    pendingMetadataJson: '[]',
    metadataRetryCount: 0,
    projectId: projectId,
    genreId: genreId,
    subcategoryId: subcategoryId,
    title: title,
    description: description,
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
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late MockRecordingRepo mockRepo;
  late MockStorytellerRepo mockStorytellerRepo;
  late MockConnectivity mockConnectivity;
  late MockSecureStorage mockStorage;

  /// Every companion the engine handed to `updateRecording`, per recording id,
  /// in write order. Recorded at the stub rather than read back through
  /// `verify(captureAny())`, which fails outright when the engine wrote
  /// nothing — and "wrote nothing" is exactly what several of these tests are
  /// asserting.
  late Map<String, List<LocalRecordingsCompanion>> recordedUpdates;

  setUpAll(() {
    registerFallbackValue(FakeLocalRecordingsCompanion());
    registerFallbackValue('');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    recordedUpdates = {};
    tempDir = Directory.systemTemp.createTempSync('sync_engine_test');
    mockRepo = MockRecordingRepo();
    mockStorytellerRepo = MockStorytellerRepo();
    mockConnectivity = MockConnectivity();
    mockStorage = MockSecureStorage();

    when(
      () => mockStorage.read(key: any(named: 'key')),
    ).thenAnswer((_) async => 'test-token');
    when(
      () => mockStorytellerRepo.getPendingSyncs(),
    ).thenAnswer((_) async => <LocalStoryteller>[]);
    // Nothing owes the server a metadata edit in these tests; the drain is
    // covered end to end in sync_engine_metadata_outbox_test.dart (ENG-403).
    when(
      () => mockRepo.getPendingMetadataSyncs(),
    ).thenAnswer((_) async => <LocalRecording>[]);
    when(
      () => mockStorytellerRepo.getRowById(any()),
    ).thenAnswer((_) async => null);
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  SyncEngineImpl buildEngine(
    MockClient httpClient, {
    UploadDownloader? downloader,
  }) {
    final authClient = AuthenticatedClient(
      client: httpClient,
      storage: mockStorage,
    );
    return SyncEngineImpl(
      recordingRepo: mockRepo,
      storytellerRepo: mockStorytellerRepo,
      connectivity: mockConnectivity,
      client: authClient,
      recordingApi: apiRepoFor(authClient),
      uploadDownloader: downloader ?? const _AlwaysOkDownloader(),
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
        return http.Response(
          jsonEncode({
            'gcs_url': 'https://storage.googleapis.com/bucket/file.m4a',
          }),
          200,
        );
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

  void stubRepoForUpload(
    String filePath, {
    String id = 'rec-1',
    String? description = 'A description with enough substance to be accepted',
  }) {
    final rec = makeRecording(
      id: id,
      localFilePath: filePath,
      description: description,
    );

    when(() => mockRepo.getRecordingById(id)).thenAnswer((_) async => rec);
    when(() => mockRepo.markAsUploading(id)).thenAnswer((_) async => true);
    when(
      () => mockRepo.markAsUploaded(id, any(), any()),
    ).thenAnswer((_) async => true);
    when(() => mockRepo.markAsFailed(id)).thenAnswer((_) async => true);
    when(() => mockRepo.updateRecording(id, any())).thenAnswer((
      invocation,
    ) async {
      recordedUpdates
          .putIfAbsent(id, () => [])
          .add(invocation.positionalArguments[1] as LocalRecordingsCompanion);
      return true;
    });
    when(() => mockRepo.resetRetryCount(id)).thenAnswer((_) async => true);
  }

  // A permanent (non-retryable) failure routes through _markPermanentlyFailed,
  // which writes uploadStatus='failed_exhausted' with retryCount=maxRetries.
  // Not the generic 'failed': that one means a retry is still coming, and a row
  // wearing it with a spent budget is queued by the counters and refused by the
  // drain (ENG-377).
  void expectPermanentFailRec1() {
    final captured = verify(
      () => mockRepo.updateRecording('rec-1', captureAny()),
    ).captured;
    final hadPermanentFail = captured.any((c) {
      final companion = c as LocalRecordingsCompanion;
      return companion.uploadStatus.present &&
          companion.uploadStatus.value == 'failed_exhausted' &&
          companion.retryCount.present &&
          companion.retryCount.value == kMaxUploadRetries;
    });
    expect(
      hadPermanentFail,
      isTrue,
      reason: 'a non-retryable failure must be marked permanent',
    );
  }

  /// Every `uploadStatus` the engine wrote for `rec-1`, in write order. Empty
  /// when it wrote none.
  List<String> capturedStatusesForRec1() =>
      (recordedUpdates['rec-1'] ?? const [])
          .where((c) => c.uploadStatus.present)
          .map((c) => c.uploadStatus.value)
          .toList();

  MockClient createStatusOnCreate(int status) {
    return MockClient((request) async {
      if (request.method == 'POST' &&
          request.url.path == '/api/oc/recordings') {
        return http.Response('error', status);
      }
      return http.Response('Not Found', 404);
    });
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

    test('§1 paused_by_recording reverts uploadStatus to local without marking '
        'as failed and without incrementing retryCount', () async {
      // Pre-flag the flag so ResumableUploadService returns paused_by_recording
      // before even touching the downloader.
      SharedPreferences.setMockInitialValues({
        'com.shema.oralCollector.is_recording_active': true,
      });
      final testFile = File('${tempDir.path}/paused.m4a');
      testFile.writeAsBytesSync(Uint8List(1024));

      final rec = makeRecording(localFilePath: testFile.path);

      when(() => mockConnectivity.isOnline).thenAnswer((_) async => true);
      when(() => mockRepo.getPendingUploads()).thenAnswer((_) async => [rec]);
      stubRepoForUpload(testFile.path);

      final httpClient = buildSuccessClient();
      final engine = buildEngine(httpClient);

      await engine.processQueue();

      verify(() => mockRepo.markAsUploading('rec-1')).called(1);
      // No markAsUploaded and no markAsFailed — the row reverts to local.
      verifyNever(() => mockRepo.markAsUploaded(any(), any(), any()));
      verifyNever(() => mockRepo.markAsFailed(any()));
      httpClient.close();
    });
  });

  group('processQueue - connectivity sampling (ENG-125 F14)', () {
    test(
      'samples connectivity once per pass regardless of eligible count',
      () async {
        final testFile = File('${tempDir.path}/f14a.m4a');
        testFile.writeAsBytesSync(Uint8List(1024));

        when(() => mockConnectivity.isOnline).thenAnswer((_) async => true);

        final recs = [
          makeRecording(id: 'rec-1', localFilePath: testFile.path),
          makeRecording(id: 'rec-2', localFilePath: testFile.path),
          makeRecording(id: 'rec-3', localFilePath: testFile.path),
        ];
        when(() => mockRepo.getPendingUploads()).thenAnswer((_) async => recs);
        for (final id in ['rec-1', 'rec-2', 'rec-3']) {
          stubRepoForUpload(testFile.path, id: id);
        }

        final httpClient = buildSuccessClient();
        final engine = buildEngine(httpClient);

        await engine.processQueue();

        // All three eligible recordings are still uploaded ...
        verify(() => mockRepo.markAsUploaded('rec-1', any(), any())).called(1);
        verify(() => mockRepo.markAsUploaded('rec-2', any(), any())).called(1);
        verify(() => mockRepo.markAsUploaded('rec-3', any(), any())).called(1);
        // ... while connectivity is probed a single time for the whole pass,
        // not once per item.
        verify(() => mockConnectivity.isOnline).called(1);
        // wifiOnly defaults to false, so WiFi must never be probed at all.
        verifyNever(() => mockConnectivity.isOnWifi);
        httpClient.close();
      },
    );

    test('stops the pass after an upload fails and connectivity has since '
        'dropped', () async {
      final testFile = File('${tempDir.path}/f14b.m4a');
      testFile.writeAsBytesSync(Uint8List(1024));

      // Online for the pass-level gate, offline on the post-failure re-probe.
      var onlineCalls = 0;
      when(() => mockConnectivity.isOnline).thenAnswer((_) async {
        onlineCalls++;
        return onlineCalls <= 1;
      });

      final recs = [
        makeRecording(id: 'rec-1', localFilePath: testFile.path),
        makeRecording(id: 'rec-2', localFilePath: testFile.path),
        makeRecording(id: 'rec-3', localFilePath: testFile.path),
      ];
      when(() => mockRepo.getPendingUploads()).thenAnswer((_) async => recs);
      for (final id in ['rec-1', 'rec-2', 'rec-3']) {
        stubRepoForUpload(testFile.path, id: id);
      }

      // Every upload fails at create (500 -> retryable failure).
      final httpClient = createStatusOnCreate(500);
      final engine = buildEngine(httpClient);

      await engine.processQueue();

      // The first recording is still attempted (no per-item pre-probe blocks
      // it) ...
      verify(() => mockRepo.markAsUploading('rec-1')).called(1);
      // ... but once it fails and the re-probe shows offline, the rest of the
      // pass is skipped.
      verifyNever(() => mockRepo.markAsUploading('rec-2'));
      verifyNever(() => mockRepo.markAsUploading('rec-3'));
      httpClient.close();
    });

    test(
      'stops uploading when wifiOnly and WiFi drops to cellular mid-pass',
      () async {
        final testFile = File('${tempDir.path}/f14c.m4a');
        testFile.writeAsBytesSync(Uint8List(1024));

        // Stays reachable the whole time, so uploads would otherwise succeed over
        // cellular. WiFi is present for the gate + the first item, then drops.
        when(() => mockConnectivity.isOnline).thenAnswer((_) async => true);
        var wifiCalls = 0;
        when(() => mockConnectivity.isOnWifi).thenAnswer((_) async {
          wifiCalls++;
          return wifiCalls <= 2;
        });

        final recs = [
          makeRecording(id: 'rec-1', localFilePath: testFile.path),
          makeRecording(id: 'rec-2', localFilePath: testFile.path),
          makeRecording(id: 'rec-3', localFilePath: testFile.path),
        ];
        when(() => mockRepo.getPendingUploads()).thenAnswer((_) async => recs);
        for (final id in ['rec-1', 'rec-2', 'rec-3']) {
          stubRepoForUpload(testFile.path, id: id);
        }

        // Every upload SUCCEEDS — the regression this guards against is the rest
        // of the queue leaking onto cellular because successes hide the drop.
        final httpClient = buildSuccessClient();
        final engine = buildEngine(httpClient);

        await engine.processQueue(wifiOnly: true);

        verify(() => mockRepo.markAsUploading('rec-1')).called(1);
        verifyNever(() => mockRepo.markAsUploading('rec-2'));
        verifyNever(() => mockRepo.markAsUploading('rec-3'));
        httpClient.close();
      },
    );

    test('stops admitting over cellular when wifiOnly and WiFi drops '
        '(maxConcurrency > 1)', () async {
      final files = <File>[];
      final recs = <LocalRecording>[];
      for (var i = 0; i < 5; i++) {
        final f = File('${tempDir.path}/f14d_$i.m4a')
          ..writeAsBytesSync(Uint8List(1024));
        files.add(f);
        recs.add(makeRecording(id: 'rec-$i', localFilePath: f.path));
      }

      when(() => mockConnectivity.isOnline).thenAnswer((_) async => true);
      // WiFi for the gate + the first concurrent batch of 3 admits, then drops.
      var wifiCalls = 0;
      when(() => mockConnectivity.isOnWifi).thenAnswer((_) async {
        wifiCalls++;
        return wifiCalls <= 4;
      });

      when(() => mockRepo.getPendingUploads()).thenAnswer((_) async => recs);
      for (var i = 0; i < 5; i++) {
        stubRepoForUpload(files[i].path, id: 'rec-$i');
      }

      var serverIdCounter = 0;
      final httpClient = MockClient((request) async {
        final path = request.url.path;
        if (request.method == 'POST' && path == '/api/oc/recordings') {
          serverIdCounter++;
          return http.Response(jsonEncode({'id': 'srv-$serverIdCounter'}), 201);
        }
        if (request.url.host == 'storage.googleapis.com') {
          return http.Response('', 200);
        }
        if (request.method == 'POST' && path.contains('/confirm-upload')) {
          return http.Response('', 200);
        }
        return http.Response('Not Found', 404);
      });
      final engine = buildEngine(httpClient);

      await engine.processQueue(wifiOnly: true, maxConcurrency: 3);

      // Once WiFi drops, no further uploads are admitted over cellular.
      verifyNever(() => mockRepo.markAsUploading('rec-3'));
      verifyNever(() => mockRepo.markAsUploading('rec-4'));
      httpClient.close();
    }, timeout: const Timeout(Duration(seconds: 10)));
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

    test('does not re-dispatch a row already in the uploading state', () async {
      final testFile = File('${tempDir.path}/inflight.m4a');
      testFile.writeAsBytesSync(Uint8List(1024));

      final rec = makeRecording(
        localFilePath: testFile.path,
        uploadStatus: 'uploading',
      );

      when(() => mockConnectivity.isOnline).thenAnswer((_) async => true);
      when(() => mockRepo.getPendingUploads()).thenAnswer((_) async => [rec]);

      final httpClient = buildSuccessClient();
      final engine = buildEngine(httpClient);

      await engine.processQueue();

      // The queue ran and saw the row, but left it untouched — proving the row
      // was skipped specifically, not that the whole pass no-op'd.
      verify(() => mockRepo.getPendingUploads()).called(1);
      verifyNever(() => mockRepo.markAsUploading(any()));
      verifyNever(() => mockRepo.updateRecording(any(), any()));
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

    test('429 marca como falha retryable', () async {
      final testFile = File('${tempDir.path}/rate_limited.m4a');
      testFile.writeAsBytesSync(Uint8List(1024));

      final rec = makeRecording(localFilePath: testFile.path);

      when(() => mockConnectivity.isOnline).thenAnswer((_) async => true);
      when(() => mockRepo.getPendingUploads()).thenAnswer((_) async => [rec]);
      stubRepoForUpload(testFile.path);

      final httpClient = createStatusOnCreate(429);
      final engine = buildEngine(httpClient);

      await engine.processQueue();

      verify(() => mockRepo.markAsFailed('rec-1')).called(1);
      verifyNever(() => mockRepo.markAsUploaded(any(), any(), any()));
      httpClient.close();
    });

    test('403 marca como falha não-retryable', () async {
      final testFile = File('${tempDir.path}/forbidden.m4a');
      testFile.writeAsBytesSync(Uint8List(1024));

      final rec = makeRecording(localFilePath: testFile.path);

      when(() => mockConnectivity.isOnline).thenAnswer((_) async => true);
      when(() => mockRepo.getPendingUploads()).thenAnswer((_) async => [rec]);
      stubRepoForUpload(testFile.path);

      final httpClient = createStatusOnCreate(403);
      final engine = buildEngine(httpClient);

      await engine.processQueue();

      verifyNever(() => mockRepo.markAsFailed('rec-1'));
      verifyNever(() => mockRepo.markAsUploaded(any(), any(), any()));
      expectPermanentFailRec1();
      httpClient.close();
    });

    test('409 marca como conflito de título, não falha genérica', () async {
      final testFile = File('${tempDir.path}/conflict.m4a');
      testFile.writeAsBytesSync(Uint8List(1024));

      final rec = makeRecording(localFilePath: testFile.path);

      when(() => mockConnectivity.isOnline).thenAnswer((_) async => true);
      when(() => mockRepo.getPendingUploads()).thenAnswer((_) async => [rec]);
      stubRepoForUpload(testFile.path);

      final httpClient = createStatusOnCreate(409);
      final engine = buildEngine(httpClient);

      await engine.processQueue();

      verifyNever(() => mockRepo.markAsFailed('rec-1'));
      verifyNever(() => mockRepo.markAsUploaded(any(), any(), any()));

      final written =
          verify(() => mockRepo.updateRecording('rec-1', captureAny())).captured
              .cast<LocalRecordingsCompanion>()
              .where((c) => c.uploadStatus.present)
              .toList();
      expect(
        written.map((c) => c.uploadStatus.value),
        contains('failed_conflict'),
      );
      expect(
        written.map((c) => c.uploadStatus.value),
        isNot(contains('failed')),
      );
      // Same permanent-failure write as the other terminal statuses: the retry
      // budget is spent too, so nothing but a rename can move the row.
      final conflict = written.firstWhere(
        (c) => c.uploadStatus.value == 'failed_conflict',
      );
      expect(conflict.retryCount.value, kMaxUploadRetries);
      httpClient.close();
    });

    test('409 no confirm-upload não vira conflito de título', () async {
      // Only the create call deduplicates on (project_id, title). The row is
      // already created by the time confirm-upload runs, so a rename would skip
      // the create branch and hit the same 409 again — parking it in
      // failed_conflict offers the user an exit that leads nowhere.
      final testFile = File('${tempDir.path}/confirm_conflict.m4a');
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
          return http.Response('already confirmed', 409);
        }
        return http.Response('Not Found', 404);
      });
      final engine = buildEngine(httpClient);

      await engine.processQueue();

      verifyNever(() => mockRepo.markAsUploaded(any(), any(), any()));

      final written =
          verify(() => mockRepo.updateRecording('rec-1', captureAny())).captured
              .cast<LocalRecordingsCompanion>()
              .where((c) => c.uploadStatus.present)
              .toList();
      // The plain permanent-failure status, which does not advertise a rename
      // that would change nothing.
      expect(
        written.map((c) => c.uploadStatus.value),
        contains('failed_exhausted'),
      );
      expect(
        written.map((c) => c.uploadStatus.value),
        isNot(contains('failed_conflict')),
      );
      httpClient.close();
    });

    test(
      'descrição insuficiente não chega a ser enviada ao servidor',
      () async {
        // A recording that predates the create-time description rule (ENG-354).
        // The client owns the same rule, so it can refuse before spending a
        // round-trip — and park the row where the UI can explain the block.
        final testFile = File('${tempDir.path}/short_description.m4a');
        testFile.writeAsBytesSync(Uint8List(1024));

        final rec = makeRecording(
          localFilePath: testFile.path,
          description: 'too short',
        );

        when(() => mockConnectivity.isOnline).thenAnswer((_) async => true);
        when(() => mockRepo.getPendingUploads()).thenAnswer((_) async => [rec]);
        stubRepoForUpload(testFile.path, description: 'too short');

        var createCalls = 0;
        final httpClient = MockClient((request) async {
          if (request.method == 'POST' &&
              request.url.path == '/api/oc/recordings') {
            createCalls++;
          }
          return http.Response(jsonEncode({'id': 'srv-1'}), 201);
        });
        final engine = buildEngine(httpClient);

        await engine.processQueue();

        expect(
          createCalls,
          0,
          reason: 'o create é recusado localmente, sem round-trip',
        );
        verifyNever(() => mockRepo.markAsUploaded(any(), any(), any()));

        final written = capturedStatusesForRec1();
        expect(written, contains('failed_description'));
        expect(
          written,
          isNot(contains('failed')),
          reason: 'não pode virar a falha genérica, que não explica nada',
        );
        httpClient.close();
      },
    );

    test('descrição suficiente segue o fluxo normal de upload', () async {
      // The guard against over-blocking: the pre-flight must only stop the
      // recordings the server would refuse anyway.
      final testFile = File('${tempDir.path}/long_description.m4a');
      testFile.writeAsBytesSync(Uint8List(1024));

      final rec = makeRecording(localFilePath: testFile.path);

      when(() => mockConnectivity.isOnline).thenAnswer((_) async => true);
      when(() => mockRepo.getPendingUploads()).thenAnswer((_) async => [rec]);
      stubRepoForUpload(testFile.path);

      var createCalls = 0;
      final httpClient = MockClient((request) async {
        final path = request.url.path;
        if (request.method == 'POST' && path == '/api/oc/recordings') {
          createCalls++;
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
          return http.Response(
            jsonEncode({'gcs_url': 'https://gcs/a.m4a'}),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });
      final engine = buildEngine(httpClient);

      await engine.processQueue();

      expect(createCalls, 1);
      verify(() => mockRepo.markAsUploaded('rec-1', 'srv-1', any())).called(1);
      expect(capturedStatusesForRec1(), isNot(contains('failed_description')));
      httpClient.close();
    });

    test('422 que não é sobre a descrição continua falha genérica', () async {
      // Other things 422 on this endpoint (a foreign key the caller got wrong).
      // The status must not claim the description is the problem.
      final testFile = File('${tempDir.path}/unprocessable.m4a');
      testFile.writeAsBytesSync(Uint8List(1024));

      final rec = makeRecording(localFilePath: testFile.path);

      when(() => mockConnectivity.isOnline).thenAnswer((_) async => true);
      when(() => mockRepo.getPendingUploads()).thenAnswer((_) async => [rec]);
      stubRepoForUpload(testFile.path);

      final httpClient = createStatusOnCreate(422);
      final engine = buildEngine(httpClient);

      await engine.processQueue();

      verifyNever(() => mockRepo.markAsUploaded(any(), any(), any()));
      final written = capturedStatusesForRec1();
      expect(written, contains('failed_exhausted'));
      expect(written, isNot(contains('failed_description')));
      httpClient.close();
    });

    test('400 marca como falha não-retryable', () async {
      final testFile = File('${tempDir.path}/bad_request.m4a');
      testFile.writeAsBytesSync(Uint8List(1024));

      final rec = makeRecording(localFilePath: testFile.path);

      when(() => mockConnectivity.isOnline).thenAnswer((_) async => true);
      when(() => mockRepo.getPendingUploads()).thenAnswer((_) async => [rec]);
      stubRepoForUpload(testFile.path);

      final httpClient = createStatusOnCreate(400);
      final engine = buildEngine(httpClient);

      await engine.processQueue();

      verifyNever(() => mockRepo.markAsFailed('rec-1'));
      verifyNever(() => mockRepo.markAsUploaded(any(), any(), any()));
      expectPermanentFailRec1();
      httpClient.close();
    });

    test('create com id não-string marca como falha permanente', () async {
      final testFile = File('${tempDir.path}/bad_id.m4a');
      testFile.writeAsBytesSync(Uint8List(1024));

      final rec = makeRecording(localFilePath: testFile.path);

      when(() => mockConnectivity.isOnline).thenAnswer((_) async => true);
      when(() => mockRepo.getPendingUploads()).thenAnswer((_) async => [rec]);
      stubRepoForUpload(testFile.path);

      final httpClient = MockClient((request) async {
        if (request.method == 'POST' &&
            request.url.path == '/api/oc/recordings') {
          return http.Response(jsonEncode({'id': 123}), 201);
        }
        return http.Response('Not Found', 404);
      });
      final engine = buildEngine(httpClient);

      await engine.processQueue();

      verifyNever(() => mockRepo.markAsUploaded(any(), any(), any()));
      expectPermanentFailRec1();
      httpClient.close();
    });
  });

  group('terminal statuses (ENG-377)', () {
    test('uma falha permanente termina em failed_exhausted', () async {
      // 'failed' with the retry budget spent is the shape that lit the sync
      // chip over a queue the engine refuses to touch: the pending query says
      // yes, the drain filter says no, and nothing on screen can explain it.
      final testFile = File('${tempDir.path}/exhausted.m4a');
      testFile.writeAsBytesSync(Uint8List(1024));

      final rec = makeRecording(localFilePath: testFile.path);

      when(() => mockConnectivity.isOnline).thenAnswer((_) async => true);
      when(() => mockRepo.getPendingUploads()).thenAnswer((_) async => [rec]);
      stubRepoForUpload(testFile.path);

      final httpClient = createStatusOnCreate(400);
      final engine = buildEngine(httpClient);

      await engine.processQueue();

      final written = capturedStatusesForRec1();
      expect(written, contains('failed_exhausted'));
      expect(
        written,
        isNot(contains('failed')),
        reason: 'the generic failure returns it to a queue that gave up on it',
      );
      httpClient.close();
    });

    test('the retryable path writes no status of its own', () async {
      // The ceiling is markAsFailed's call, not the engine's: it is the one
      // that re-reads the count, so it gets the decision right even when the
      // failure was raised before the engine could read the row. What the
      // engine owes is to route every retryable failure there and write nothing
      // itself.
      final testFile = File('${tempDir.path}/budget_left.m4a');
      testFile.writeAsBytesSync(Uint8List(1024));

      final rec = makeRecording(
        localFilePath: testFile.path,
        retryCount: kMaxUploadRetries - 2,
      );

      when(() => mockConnectivity.isOnline).thenAnswer((_) async => true);
      when(() => mockRepo.getPendingUploads()).thenAnswer((_) async => [rec]);
      stubRepoForUpload(testFile.path);
      when(
        () => mockRepo.getRecordingById('rec-1'),
      ).thenAnswer((_) async => rec);

      final httpClient = createStatusOnCreate(500);
      final engine = buildEngine(httpClient);

      await engine.processQueue();

      verify(() => mockRepo.markAsFailed('rec-1')).called(1);
      expect(capturedStatusesForRec1(), isEmpty);
      httpClient.close();
    });

    test(
      'um arquivo local que não existe termina em failed_missing_file',
      () async {
        // The opposite dead end: the row was marked failed without spending a
        // retry, so it never reached the ceiling — reselected on every pass and
        // skipped on every pass. The three lookups _resolveFilePath does are all
        // the app has, and it hard-deletes, so the file is not coming back.
        final docsDir = Directory('${tempDir.path}/docs')..createSync();
        const channel = MethodChannel('plugins.flutter.io/path_provider');
        final messenger =
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
        messenger.setMockMethodCallHandler(channel, (_) async => docsDir.path);
        addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

        final missingPath = '${tempDir.path}/never_written.m4a';
        final rec = makeRecording(localFilePath: missingPath);

        when(() => mockConnectivity.isOnline).thenAnswer((_) async => true);
        when(() => mockRepo.getPendingUploads()).thenAnswer((_) async => [rec]);
        stubRepoForUpload(missingPath);

        final httpClient = buildSuccessClient();
        final engine = buildEngine(httpClient);

        await engine.processQueue();

        final written = capturedStatusesForRec1();
        expect(written, contains('failed_missing_file'));
        expect(written, isNot(contains('failed')));
        verifyNever(() => mockRepo.markAsFailed(any()));
        verifyNever(() => mockRepo.markAsUploading(any()));
        httpClient.close();
      },
    );
  });

  group('verification polling', () {
    test('confirm success marks upload as uploaded', () async {
      final testFile = File('${tempDir.path}/poll_ok.m4a');
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
          return http.Response(
            jsonEncode({
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
      httpClient.close();
    });

    test(
      'malformed confirm-upload response marks as permanently failed (non-retryable)',
      () async {
        // Engine no longer polls a status endpoint; confirm-upload is the
        // single source of truth. A 200 with an unparseable body indicates a
        // server-side protocol violation — retrying won't help, so the row
        // is marked failed_exhausted with retryCount=maxRetries (H7).
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
            // Malformed body — JSON parsing will fail.
            return http.Response('', 200);
          }

          return http.Response('Not Found', 404);
        });

        final engine = buildEngine(httpClient);

        await engine.processQueue();

        verifyNever(() => mockRepo.markAsUploaded(any(), any(), any()));
        // Verify the permanently-failed update happened.
        final captured = verify(
          () => mockRepo.updateRecording('rec-1', captureAny()),
        ).captured;
        final hadPermanentFail = captured.any((c) {
          final companion = c as LocalRecordingsCompanion;
          return companion.uploadStatus.present &&
              companion.uploadStatus.value == 'failed_exhausted' &&
              companion.retryCount.present &&
              companion.retryCount.value == kMaxUploadRetries;
        });
        expect(
          hadPermanentFail,
          isTrue,
          reason:
              'malformed confirm-upload must be marked non-retryable failed',
        );
        httpClient.close();
      },
    );

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
