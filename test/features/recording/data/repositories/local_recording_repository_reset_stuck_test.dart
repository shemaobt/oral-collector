/// Tests for crash recovery of recordings left in the `uploading` state.
///
/// A mid-upload crash leaves a row stuck in `uploading`. Startup recovery must
/// hand it back to the upload queue (re-enqueue) without deleting it and
/// without losing the resume offset, so the upload continues rather than
/// restarting or being lost.
library;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/features/recording/data/repositories/local_recording_repository.dart';

void main() {
  late AppDatabase db;
  late LocalRecordingRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = LocalRecordingRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> insert({
    required String id,
    required String uploadStatus,
    int retryCount = 0,
    DateTime? lastRetryAt,
    String? serverId,
    String? resumableSessionUri,
    int uploadedBytes = 0,
  }) {
    return repo.insertRecording(
      LocalRecordingsCompanion(
        id: Value(id),
        projectId: const Value('proj-1'),
        genreId: const Value('genre-1'),
        localFilePath: Value('/tmp/$id.m4a'),
        uploadStatus: Value(uploadStatus),
        retryCount: Value(retryCount),
        lastRetryAt: Value(lastRetryAt),
        serverId: Value(serverId),
        resumableSessionUri: Value(resumableSessionUri),
        uploadedBytes: Value(uploadedBytes),
        recordedAt: Value(DateTime.utc(2026, 5, 1, 10)),
        createdAt: Value(DateTime.utc(2026, 5, 1, 10)),
      ),
    );
  }

  test('resetStuckUploading re-enqueues an orphaned uploading row without '
      'deleting it or losing resume state', () async {
    final lastRetry = DateTime.utc(2026, 5, 1, 9, 30);
    await insert(
      id: 'stuck',
      uploadStatus: 'uploading',
      retryCount: 2,
      lastRetryAt: lastRetry,
      serverId: 'srv-stuck',
      resumableSessionUri: 'https://upload.example/session/abc',
      uploadedBytes: 4096,
    );

    final count = await repo.resetStuckUploading();
    expect(count, 1);

    final row = await repo.getRecordingById('stuck');
    expect(row, isNotNull, reason: 'row must not be deleted');
    expect(
      row!.uploadStatus,
      isNot('uploading'),
      reason: 'status must be reset out of uploading',
    );

    // Re-enqueued: the sync drain picks it up again.
    final pending = await repo.getPendingUploads();
    expect(pending.map((r) => r.id), contains('stuck'));

    // Non-destructive: retry budget and resume offset preserved.
    // (Drift round-trips DateTime through local time, so compare the instant.)
    expect(row.retryCount, 2);
    expect(row.lastRetryAt!.isAtSameMomentAs(lastRetry), isTrue);
    expect(row.serverId, 'srv-stuck');
    expect(row.resumableSessionUri, 'https://upload.example/session/abc');
    expect(row.uploadedBytes, 4096);
  });

  test(
    'resetStuckUploading leaves terminal and failed rows untouched',
    () async {
      await insert(id: 'done', uploadStatus: 'uploaded', serverId: 'srv-done');
      await insert(id: 'failed', uploadStatus: 'failed', retryCount: 3);

      final count = await repo.resetStuckUploading();

      expect(count, 0);
      expect((await repo.getRecordingById('done'))!.uploadStatus, 'uploaded');
      expect((await repo.getRecordingById('failed'))!.uploadStatus, 'failed');
    },
  );
}
