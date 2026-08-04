/// The two queries that make the terminal upload statuses safe:
/// `failed_conflict` (ENG-71), `failed_description` (ENG-354),
/// `failed_exhausted` and `failed_missing_file` (ENG-377).
///
/// A recording parked in any of them was refused for a reason the drain cannot
/// change on its own, so it must stay out of the upload queue — otherwise it
/// re-uploads forever and is refused every time — and it must survive the
/// destructive "Clear failed" cleanup, which is the only user action that
/// deletes rows wholesale.
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

  test('getPendingUploads never queues a terminal recording', () async {
    await insert('conflicted', 'failed_conflict');
    await insert('undescribed', 'failed_description');
    await insert('exhausted', 'failed_exhausted', retryCount: 5);
    await insert('lost', 'failed_missing_file');
    await insert('retryable', 'failed');

    final pending = await repo.getPendingUploads();

    // The badge counts this query. Leaving a terminal row in it is what lit the
    // sync chip over a queue the engine had already given up on.
    expect(pending.map((r) => r.id), ['retryable']);
  });

  test('deleteStaleRecordings keeps a terminal recording', () async {
    await insert('conflicted', 'failed_conflict');
    await insert('undescribed', 'failed_description');
    await insert('exhausted', 'failed_exhausted', retryCount: 5);
    await insert('lost', 'failed_missing_file');
    await insert('stale', 'failed');

    final deleted = await repo.deleteStaleRecordings('proj-1');

    // Not about the audio — `failed_missing_file` has none left by definition.
    // Each of these rows carries the title, description and classification the
    // user typed and the server never received, and the sweep is wholesale.
    expect(deleted, 1);
    expect(
      (await repo.getAllRecordings('proj-1')).map((r) => r.id),
      unorderedEquals(['conflicted', 'undescribed', 'exhausted', 'lost']),
    );
  });

  test('resetRetryCount is the way back into the queue', () async {
    await insert('exhausted', 'failed_exhausted', retryCount: 5);

    await repo.resetRetryCount('exhausted');

    final pending = await repo.getPendingUploads();
    expect(pending.map((r) => r.id), ['exhausted']);
    expect((await repo.getRecordingById('exhausted'))!.retryCount, 0);
  });
}
