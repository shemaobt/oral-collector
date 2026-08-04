/// The retry budget, and the two places the repository spends it (ENG-377).
///
/// `markAsFailed` records one attempt and retires the row when that was the
/// last one. It decides the ceiling itself, on the count it re-reads, because
/// the caller may have failed before it ever got to read the row — and a caller
/// counting from zero would leave `failed` on a row with nothing left, which is
/// queued by `getPendingUploads` and refused by the drain, forever.
///
/// `normalizeExhaustedUploads` is the same invariant applied backwards, to the
/// rows older builds already wrote into that shape.
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

  Future<void> insert(String id, String uploadStatus, {int retryCount = 0}) {
    return repo.insertRecording(
      LocalRecordingsCompanion(
        id: Value(id),
        projectId: const Value('proj-1'),
        genreId: const Value('genre-1'),
        localFilePath: Value('/tmp/$id.m4a'),
        uploadStatus: Value(uploadStatus),
        retryCount: Value(retryCount),
        recordedAt: Value(DateTime.utc(2026, 5, 1)),
      ),
    );
  }

  group('markAsFailed', () {
    test('an attempt with budget left stays retryable', () async {
      await insert('rec-1', 'uploading', retryCount: kMaxUploadRetries - 2);

      await repo.markAsFailed('rec-1');

      final row = (await repo.getRecordingById('rec-1'))!;
      expect(row.uploadStatus, 'failed');
      expect(row.retryCount, kMaxUploadRetries - 1);
      expect((await repo.getPendingUploads()).map((r) => r.id), ['rec-1']);
    });

    test('the attempt that spends the last retry is terminal', () async {
      await insert('rec-1', 'uploading', retryCount: kMaxUploadRetries - 1);

      await repo.markAsFailed('rec-1');

      final row = (await repo.getRecordingById('rec-1'))!;
      expect(row.uploadStatus, 'failed_exhausted');
      expect(row.retryCount, kMaxUploadRetries);
      expect(await repo.getPendingUploads(), isEmpty);
    });

    test('a row already past the ceiling never falls back to failed', () async {
      await insert('rec-1', 'failed_exhausted', retryCount: kMaxUploadRetries);

      await repo.markAsFailed('rec-1');

      expect(
        (await repo.getRecordingById('rec-1'))!.uploadStatus,
        'failed_exhausted',
      );
    });

    test('a recording that is gone is not resurrected', () async {
      expect(await repo.markAsFailed('absent'), isFalse);
    });
  });

  group('normalizeExhaustedUploads', () {
    test('retires rows an older build left stuck', () async {
      // The bug was reported from devices that already hold these rows. Fixing
      // the writers stops new ones; without this sweep the person who reported
      // it still sees the inflated count and the dead button after updating.
      await insert('stuck', 'failed', retryCount: kMaxUploadRetries);
      await insert('retryable', 'failed', retryCount: 2);
      await insert('fresh', 'local');

      await repo.normalizeExhaustedUploads();

      expect(
        (await repo.getPendingUploads()).map((r) => r.id),
        unorderedEquals(['retryable', 'fresh']),
      );
      expect(
        (await repo.getRecordingById('stuck'))!.uploadStatus,
        'failed_exhausted',
      );
    });

    test('running it twice changes nothing the second time', () async {
      await insert('stuck', 'failed', retryCount: kMaxUploadRetries);

      final first = await repo.normalizeExhaustedUploads();
      final second = await repo.normalizeExhaustedUploads();

      // It runs on every launch, so it has to be safe to run on every launch.
      expect(first, 1);
      expect(second, 0);
    });

    test('a recording still inside its retry budget is left alone', () async {
      await insert('retryable', 'failed', retryCount: kMaxUploadRetries - 1);

      await repo.normalizeExhaustedUploads();

      expect(
        (await repo.getRecordingById('retryable'))!.uploadStatus,
        'failed',
      );
    });
  });
}
