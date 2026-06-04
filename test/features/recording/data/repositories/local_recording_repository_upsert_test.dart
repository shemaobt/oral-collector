/// Tests for LocalRecordingRepository.upsertRecording.
///
/// Guards against ENG-80: a retried web import must not crash with
/// "UNIQUE constraint failed: local_recordings.id" when a shadow row from a
/// previous failed attempt is still present, and it must keep the resume
/// progress (resumableSessionUri / uploadedBytes) so the upload can continue.
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

  LocalRecordingsCompanion shadow({
    required String id,
    String title = 'Original',
  }) {
    return LocalRecordingsCompanion(
      id: Value(id),
      projectId: const Value('proj-1'),
      genreId: const Value('unclassified'),
      localFilePath: Value('web_$id'),
      title: Value(title),
      uploadStatus: const Value('web_uploading'),
      recordedAt: Value(DateTime.utc(2026, 4, 15, 10)),
    );
  }

  test(
    'upserting an existing id does not throw and preserves resume progress',
    () async {
      await repo.insertRecording(shadow(id: 'web_srv-A'));
      await repo.updateRecording(
        'web_srv-A',
        const LocalRecordingsCompanion(
          resumableSessionUri: Value('gcs://session/abc'),
          uploadedBytes: Value(16777216),
        ),
      );

      await repo.upsertRecording(shadow(id: 'web_srv-A', title: 'Retry'));

      final row = await repo.getRecordingById('web_srv-A');
      expect(row, isNotNull);
      expect(row!.resumableSessionUri, 'gcs://session/abc');
      expect(row.uploadedBytes, 16777216);
      expect(row.title, 'Retry');
    },
  );
}
