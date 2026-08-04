/// What the recording still owes must survive its own upload (ENG-379).
///
/// The server recomputes the review flags on create and returns them; if the
/// client drops them, the row that just got a `serverId` reads as "owes
/// nothing" — and the incomplete-record warning disappears at the exact moment
/// the upload finishes. Written against real Drift rather than a mocked
/// repository on purpose: the failure is a write that never happens, which a
/// fake that echoes its argument back cannot show.
library;

import 'dart:convert';
import 'dart:io';

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
import 'package:oral_collector/features/recording/domain/entities/review_pendency.dart';
import 'package:oral_collector/features/storyteller/data/repositories/local_storyteller_repository.dart';
import 'package:oral_collector/features/sync/data/repositories/sync_engine.dart';
import 'package:oral_collector/features/sync/data/services/upload_downloader.dart';
import 'package:oral_collector/features/sync/domain/repositories/connectivity_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class _OnlineConnectivity implements ConnectivityService {
  @override
  Future<bool> get isOnline async => true;

  @override
  Future<bool> get isOnWifi async => true;

  @override
  Stream<bool> get onConnectivityChanged => const Stream.empty();
}

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late AppDatabase db;
  late LocalRecordingRepository repo;
  late File audioFile;
  late _MockSecureStorage storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = _MockSecureStorage();
    when(
      () => storage.read(key: any(named: 'key')),
    ).thenAnswer((_) async => 'test-token');
    tempDir = Directory.systemTemp.createTempSync('sync_engine_flags_test');
    audioFile = File('${tempDir.path}/rec-1.m4a')..writeAsBytesSync([1, 2, 3]);
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = LocalRecordingRepository(db);
  });

  tearDown(() async {
    await db.close();
    tempDir.deleteSync(recursive: true);
  });

  Future<void> seedUnclassified() => repo.insertRecording(
    LocalRecordingsCompanion(
      id: const Value('rec-1'),
      projectId: const Value('proj-1'),
      genreId: const Value('unclassified'),
      subcategoryId: const Value('unclassified'),
      registerId: const Value(null),
      title: const Value('Story'),
      // Long enough to clear the create-time description rule (ENG-354).
      description: const Value(
        'A description with enough substance to be accepted',
      ),
      durationSeconds: const Value(60),
      fileSizeBytes: Value(audioFile.lengthSync()),
      format: const Value('m4a'),
      localFilePath: Value(audioFile.path),
      uploadStatus: const Value('local'),
      cleaningStatus: const Value('none'),
      recordedAt: Value(DateTime.utc(2026, 5, 1)),
    ),
  );

  SyncEngineImpl buildEngine(List<Map<String, String>> createFlags) {
    final client = MockClient((request) async {
      final path = request.url.path;

      if (request.method == 'POST' && path == '/api/oc/recordings') {
        return http.Response(
          jsonEncode({'id': 'srv-1', 'review_flags': createFlags}),
          201,
        );
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
      return http.Response('Not Found', 404);
    });

    return SyncEngineImpl(
      recordingRepo: repo,
      storytellerRepo: LocalStorytellerRepository(db),
      connectivity: _OnlineConnectivity(),
      client: AuthenticatedClient(client: client, storage: storage),
      uploadDownloader: const _AlwaysOkDownloader(),
    );
  }

  test('an unclassified recording still owes a classification after its own '
      'upload', () async {
    await seedUnclassified();

    await buildEngine([
      {'code': 'missing_classification', 'origin': 'system'},
    ]).processQueue();

    final saved = await repo.getRecordingEntityById('rec-1');
    expect(saved, isNotNull);
    expect(saved!.serverId, 'srv-1');
    expect(saved.uploadStatus, 'uploaded');
    expect(recordingPendencies(saved), [PendencyKind.classification]);
  });

  test(
    'a server that reports nothing owed leaves the row owing nothing',
    () async {
      await seedUnclassified();

      await buildEngine(const []).processQueue();

      final saved = await repo.getRecordingEntityById('rec-1');
      expect(saved, isNotNull);
      expect(saved!.reviewFlags, isEmpty);
      expect(recordingPendencies(saved), isEmpty);
    },
  );
}
