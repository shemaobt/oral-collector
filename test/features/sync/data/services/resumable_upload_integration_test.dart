// Integration-style test for ResumableUploadService against a real Drift
// schema (AppDatabase + LocalRecordingRepository on an in-memory NativeDatabase).
//
// Why: the rest of resumable_upload_service_test.dart mocks
// LocalRecordingRepository, which means a migration that renamed
// `uploadedBytes` or changed the LocalRecordingsCompanion shape would not
// break those tests. These cases run the upload loop end-to-end through the
// real schema so persistence bugs surface in CI.

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
import 'package:oral_collector/features/sync/data/services/resumable_upload_service.dart';
import 'package:oral_collector/features/sync/data/services/upload_downloader.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

class _PlannedDownloader implements UploadDownloader {
  _PlannedDownloader(this._responses);

  final List<UploadResult> _responses;
  final List<int> chunkOffsets = [];

  @override
  Future<UploadResult> putChunk({
    required String taskId,
    required String url,
    required String filePath,
    required int offset,
    required int end,
    required Map<String, String> headers,
  }) async {
    chunkOffsets.add(offset);
    if (_responses.isEmpty) {
      return const UploadResult(statusCode: 200);
    }
    return _responses.removeAt(0);
  }

  @override
  Future<void> cancel(String taskId) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> resumeAfterCancel() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late AppDatabase db;
  late LocalRecordingRepository repo;
  late MockSecureStorage secureStorage;

  setUpAll(() {
    dotenv.testLoad(fileInput: 'BACKEND_URL=http://localhost:8080');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    tempDir = Directory.systemTemp.createTempSync('upload_integration_');
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = LocalRecordingRepository(db);
    secureStorage = MockSecureStorage();
    when(
      () => secureStorage.read(key: any(named: 'key')),
    ).thenAnswer((_) async => 'test-token');
  });

  tearDown(() async {
    await db.close();
    tempDir.deleteSync(recursive: true);
  });

  Future<void> seedRecording({
    required String id,
    required int fileSizeBytes,
    required String localFilePath,
    String? resumableSessionUri,
    int uploadedBytes = 0,
  }) async {
    await db
        .into(db.localRecordings)
        .insert(
          LocalRecordingsCompanion.insert(
            id: id,
            projectId: 'proj-1',
            genreId: 'genre-1',
            localFilePath: localFilePath,
            recordedAt: DateTime(2024, 1, 1),
            durationSeconds: const Value(60.0),
            fileSizeBytes: Value(fileSizeBytes),
            uploadStatus: const Value('uploading'),
            serverId: const Value('srv-1'),
            resumableSessionUri: resumableSessionUri == null
                ? const Value.absent()
                : Value(resumableSessionUri),
            uploadedBytes: Value(uploadedBytes),
          ),
        );
  }

  ResumableUploadService buildService(
    UploadDownloader downloader,
    MockClient mockClient,
  ) {
    final auth = AuthenticatedClient(
      client: mockClient,
      storage: secureStorage,
    );
    return ResumableUploadService(
      client: auth,
      recordingRepo: repo,
      downloader: downloader,
    );
  }

  test('a successful 2-chunk upload persists final state (sessionUri=null, '
      'uploadedBytes=0) in the real LocalRecordings row', () async {
    const fileSize = 12 * 1024 * 1024;
    final file = File('${tempDir.path}/integration.m4a');
    file.writeAsBytesSync(Uint8List(fileSize));

    await seedRecording(
      id: 'rec-1',
      fileSizeBytes: fileSize,
      localFilePath: file.path,
    );

    final mockClient = MockClient((request) async {
      if (request.url.path.contains('resumable-upload-url')) {
        return http.Response(
          jsonEncode({
            'session_uri': 'https://storage.googleapis.com/upload/s1',
          }),
          200,
        );
      }
      return http.Response('', 404);
    });

    final downloader = _PlannedDownloader([
      const UploadResult(statusCode: 308),
      const UploadResult(statusCode: 200),
    ]);

    final service = buildService(downloader, mockClient);
    final result = await service.upload(
      recordingId: 'rec-1',
      serverId: 'srv-1',
      localFilePath: file.path,
      format: 'm4a',
      fileSizeBytes: fileSize,
    );

    expect(result.success, isTrue);
    expect(downloader.chunkOffsets, [0, 8 * 1024 * 1024]);

    // Real-schema assertion: the row's bookkeeping is cleared on terminal
    // success — a future schema change that drops or renames these columns
    // would fail here, not silently pass.
    final row = await repo.getRecordingById('rec-1');
    expect(row, isNotNull);
    expect(row!.resumableSessionUri, isNull);
    expect(row.uploadedBytes, 0);
  });

  test(
    'a paused-by-recording chunk leaves uploadedBytes from the prior committed '
    'chunk in the real row (§1 invariant survives the schema layer)',
    () async {
      const fileSize = 24 * 1024 * 1024;
      final file = File('${tempDir.path}/paused.m4a');
      file.writeAsBytesSync(Uint8List(fileSize));

      await seedRecording(
        id: 'rec-2',
        fileSizeBytes: fileSize,
        localFilePath: file.path,
      );

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('resumable-upload-url')) {
          return http.Response(
            jsonEncode({
              'session_uri': 'https://storage.googleapis.com/upload/s2',
            }),
            200,
          );
        }
        return http.Response('', 404);
      });

      final downloader = _PlannedDownloader([
        const UploadResult(statusCode: 308), // chunk 1 commits
        const UploadResult(statusCode: 0, cancelled: true), // chunk 2 cancelled
      ]);

      final service = buildService(downloader, mockClient);
      final result = await service.upload(
        recordingId: 'rec-2',
        serverId: 'srv-1',
        localFilePath: file.path,
        format: 'm4a',
        fileSizeBytes: fileSize,
      );

      expect(result.pausedByRecording, isTrue);

      final row = await repo.getRecordingById('rec-2');
      expect(row, isNotNull);
      expect(
        row!.uploadedBytes,
        8 * 1024 * 1024,
        reason: 'first chunk\'s 8 MB end offset must be persisted in Drift',
      );
      expect(
        row.resumableSessionUri,
        isNotNull,
        reason: 'session URI is kept so the next sync run can resume',
      );
    },
  );
}
