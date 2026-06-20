/// Tests for the upload-queue ordering of LocalRecordingRepository.
///
/// The queue is drained FIFO in the order these methods return, so the order
/// must be stable. Ordering by wall-clock `recordedAt` is not: a batch import
/// stamps many rows with the same `recordedAt`, and `recordedAt` can move
/// backward relative to enqueue order. See ENG-122.
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

  Future<void> insertPending({
    required String id,
    required DateTime recordedAt,
    required DateTime createdAt,
    String uploadStatus = 'local',
  }) {
    return repo.insertRecording(
      LocalRecordingsCompanion(
        id: Value(id),
        projectId: const Value('proj-1'),
        genreId: const Value('genre-1'),
        localFilePath: Value('/tmp/$id.m4a'),
        uploadStatus: Value(uploadStatus),
        recordedAt: Value(recordedAt),
        createdAt: Value(createdAt),
      ),
    );
  }

  test('getPendingUploads breaks createdAt ties deterministically by id', () async {
    // Same recordedAt AND same createdAt (the batch-import case) => only the id
    // tiebreaker can decide, so the queue order stays stable and deterministic.
    final t = DateTime.utc(2026, 5, 1, 10);
    await insertPending(id: 'r3', recordedAt: t, createdAt: t);
    await insertPending(id: 'r1', recordedAt: t, createdAt: t);
    await insertPending(id: 'r2', recordedAt: t, createdAt: t);

    final pending = await repo.getPendingUploads();

    expect(pending.map((r) => r.id).toList(), ['r1', 'r2', 'r3']);
  });

  test(
    'getPendingUploads orders by enqueue time (createdAt), not recordedAt or id',
    () async {
      // 'b_first' is enqueued earliest (smallest createdAt) so it must upload
      // first — even though it has the newer recordedAt AND the larger id. The
      // ids deliberately sort opposite to the expected order, so an implementation
      // that ordered by recordedAt or by id alone would produce the wrong result.
      await insertPending(
        id: 'a_second',
        recordedAt: DateTime.utc(2020, 1, 1),
        createdAt: DateTime.utc(2026, 5, 1, 10, 0, 2),
      );
      await insertPending(
        id: 'b_first',
        recordedAt: DateTime.utc(2026, 1, 1),
        createdAt: DateTime.utc(2026, 5, 1, 10, 0, 1),
      );

      final pending = await repo.getPendingUploads();

      expect(pending.map((r) => r.id).toList(), ['b_first', 'a_second']);
    },
  );

  test(
    'getPendingWebUploads breaks createdAt ties deterministically by id',
    () async {
      final t = DateTime.utc(2026, 5, 1, 10);
      await insertPending(
        id: 'w3',
        recordedAt: t,
        createdAt: t,
        uploadStatus: 'web_uploading',
      );
      await insertPending(
        id: 'w1',
        recordedAt: t,
        createdAt: t,
        uploadStatus: 'web_uploading',
      );
      await insertPending(
        id: 'w2',
        recordedAt: t,
        createdAt: t,
        uploadStatus: 'web_uploading',
      );

      final pending = await repo.getPendingWebUploads();

      expect(pending.map((r) => r.id).toList(), ['w1', 'w2', 'w3']);
    },
  );
}
