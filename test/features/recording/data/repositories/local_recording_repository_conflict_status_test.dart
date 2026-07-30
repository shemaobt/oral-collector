/// The two queries that make the user-exit terminal statuses safe:
/// `failed_conflict` (ENG-71) and `failed_description` (ENG-354).
///
/// A recording parked in either was refused for a reason no retry can change —
/// a title the backend already has, or a description the create rule rejects.
/// Only the user can clear it, so it must stay out of the upload queue —
/// otherwise it re-uploads forever and is refused every time — and it must
/// survive the destructive "Clear failed" cleanup, which is the only user
/// action that deletes rows wholesale.
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

  test(
    'getPendingUploads never queues a recording awaiting the user',
    () async {
      await insert('conflicted', 'failed_conflict');
      await insert('undescribed', 'failed_description');
      await insert('retryable', 'failed');

      final pending = await repo.getPendingUploads();

      expect(pending.map((r) => r.id), ['retryable']);
    },
  );

  test('deleteStaleRecordings keeps a recording awaiting the user', () async {
    await insert('conflicted', 'failed_conflict');
    await insert('undescribed', 'failed_description');
    await insert('stale', 'failed');

    final deleted = await repo.deleteStaleRecordings('proj-1');

    expect(deleted, 1);
    expect(
      (await repo.getAllRecordings('proj-1')).map((r) => r.id),
      unorderedEquals(['conflicted', 'undescribed']),
    );
  });
}
