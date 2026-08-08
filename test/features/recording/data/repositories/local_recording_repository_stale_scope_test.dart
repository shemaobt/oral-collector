/// What "Clear failed" is allowed to delete.
///
/// The sweep is wholesale and irreversible, and `uploading` is not a failure —
/// it is the one status that says the upload is happening right now. Deleting
/// it destroys a recording the user never saw fail.
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
    'deleteStaleRecordings spares a recording that is still uploading',
    () async {
      await insert('in-flight', 'uploading');
      await insert('stale', 'failed');

      final deleted = await repo.deleteStaleRecordings('proj-1');

      expect(deleted, 1);
      expect((await repo.getAllRecordings('proj-1')).map((r) => r.id), [
        'in-flight',
      ]);
    },
  );

  test('deleteStaleRecordings leaves other projects alone', () async {
    await insert('mine', 'failed');
    await repo.insertRecording(
      LocalRecordingsCompanion(
        id: const Value('theirs'),
        projectId: const Value('proj-2'),
        genreId: const Value('genre-1'),
        localFilePath: const Value('/tmp/theirs.m4a'),
        uploadStatus: const Value('failed'),
        recordedAt: Value(DateTime.utc(2026, 5, 1)),
      ),
    );

    expect(await repo.deleteStaleRecordings('proj-1'), 1);
    expect((await repo.getAllRecordings('proj-2')).map((r) => r.id), [
      'theirs',
    ]);
  });
}
