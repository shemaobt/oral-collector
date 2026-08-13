/// What the recordings list's failed-upload action is allowed to touch.
///
/// It began as a hard delete ("Clear failed", ENG-46), scoped to `failed`
/// alone because `uploading` is not a failure — it is the one status that says
/// the upload is happening right now, and deleting it destroyed a recording
/// the user never saw fail. ENG-404 reversed the premise instead of narrowing
/// it further: a failed upload is by definition one whose audio exists only on
/// the device, so the action requeues the row and nothing here deletes one.
///
/// The scope moved with the premise. `failed` was already in the queue, so
/// requeueing it only skips the backoff wait and hands back the budget;
/// `failed_exhausted` is the case that needs this most, because
/// `getPendingUploads` does not select it and without an explicit requeue it is
/// never attempted again. The three failures a retry cannot fix on its own
/// (`failed_conflict`, `failed_description`, `failed_missing_file`) stay out.
library;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oral_collector/core/config/upload_retry_policy.dart';
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

  Future<void> insert(
    String id,
    String uploadStatus, {
    String projectId = 'proj-1',
    int retryCount = 0,
    DateTime? lastRetryAt,
  }) {
    return repo.insertRecording(
      LocalRecordingsCompanion(
        id: Value(id),
        projectId: Value(projectId),
        genreId: const Value('genre-1'),
        localFilePath: Value('/tmp/$id.m4a'),
        uploadStatus: Value(uploadStatus),
        retryCount: Value(retryCount),
        lastRetryAt: Value(lastRetryAt),
        recordedAt: Value(DateTime.utc(2026, 5, 1)),
      ),
    );
  }

  test('a spent-budget recording is put back in the queue', () async {
    await insert(
      'exhausted',
      'failed_exhausted',
      retryCount: kMaxUploadRetries,
      lastRetryAt: DateTime.utc(2026, 5, 2),
    );

    expect(
      await repo.getPendingUploads(),
      isEmpty,
      reason:
          'failed_exhausted is out of the queue until something requeues it',
    );

    expect(await repo.requeueFailedUploads('proj-1'), 1);

    expect((await repo.getPendingUploads()).map((r) => r.id), ['exhausted']);
  });

  test('a failed recording is handed a fresh budget and no backoff', () async {
    await insert(
      'stale',
      'failed',
      retryCount: 3,
      lastRetryAt: DateTime.utc(2026, 5, 2),
    );

    expect(await repo.requeueFailedUploads('proj-1'), 1);

    final row = (await repo.getRecordingById('stale'))!;
    expect(row.uploadStatus, 'local');
    expect(row.retryCount, 0);
    expect(row.lastRetryAt, isNull);
  });

  test('nothing is deleted', () async {
    await insert('a', 'failed');
    await insert('b', 'failed_exhausted');
    await insert('c', 'failed_conflict');
    await insert('d', 'uploading');

    await repo.requeueFailedUploads('proj-1');

    expect((await repo.getAllRecordings('proj-1')).map((r) => r.id).toSet(), {
      'a',
      'b',
      'c',
      'd',
    });
  });

  test('the failures a retry cannot fix are left alone', () async {
    const untouched = [
      'failed_conflict',
      'failed_description',
      'failed_missing_file',
    ];
    for (final status in untouched) {
      await insert(status, status, retryCount: 2);
    }

    expect(await repo.requeueFailedUploads('proj-1'), 0);

    for (final status in untouched) {
      final row = (await repo.getRecordingById(status))!;
      expect(row.uploadStatus, status);
      expect(row.retryCount, 2, reason: '$status kept its budget');
    }
  });

  test('an upload in flight and a finished one are left alone', () async {
    await insert('in-flight', 'uploading');
    await insert('done', 'uploaded');

    expect(await repo.requeueFailedUploads('proj-1'), 0);

    expect(
      (await repo.getRecordingById('in-flight'))!.uploadStatus,
      'uploading',
    );
    expect((await repo.getRecordingById('done'))!.uploadStatus, 'uploaded');
  });

  test('it is scoped to the project', () async {
    await insert('mine', 'failed');
    await insert('theirs', 'failed', projectId: 'proj-2');

    expect(await repo.requeueFailedUploads('proj-1'), 1);

    expect((await repo.getRecordingById('theirs'))!.uploadStatus, 'failed');
  });
}
