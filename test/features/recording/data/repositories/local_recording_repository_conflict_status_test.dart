/// The two queries that make `failed_conflict` a safe terminal status (ENG-71).
///
/// A recording parked in `failed_conflict` was rejected by the backend's
/// (project_id, title) dedup. Only a rename can clear it, so it must stay out
/// of the upload queue — otherwise it re-uploads forever and 409s every time —
/// and it must survive the destructive "Clear failed" cleanup, which is the
/// only user action that deletes rows wholesale.
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

  Future<void> insert(String id, String uploadStatus) {
    return repo.insertRecording(
      LocalRecordingsCompanion(
        id: Value(id),
        projectId: const Value('proj-1'),
        genreId: const Value('genre-1'),
        localFilePath: Value('/tmp/$id.m4a'),
        uploadStatus: Value(uploadStatus),
        recordedAt: Value(DateTime.utc(2026, 5, 1)),
      ),
    );
  }

  test('getPendingUploads never queues a title-conflicted recording', () async {
    await insert('conflicted', 'failed_conflict');
    await insert('retryable', 'failed');

    final pending = await repo.getPendingUploads();

    expect(pending.map((r) => r.id), ['retryable']);
  });

  test('deleteStaleRecordings keeps a title-conflicted recording', () async {
    await insert('conflicted', 'failed_conflict');
    await insert('stale', 'failed');

    final deleted = await repo.deleteStaleRecordings('proj-1');

    expect(deleted, 1);
    expect((await repo.getAllRecordings('proj-1')).map((r) => r.id), [
      'conflicted',
    ]);
  });
}
