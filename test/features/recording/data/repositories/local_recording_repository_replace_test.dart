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

  Future<void> seedUploaded(String id) async {
    await repo.insertRecording(
      LocalRecordingsCompanion(
        id: Value(id),
        projectId: const Value('proj-1'),
        genreId: const Value('genre-1'),
        title: const Value('Before'),
        durationSeconds: const Value(30.0),
        fileSizeBytes: const Value(1000),
        format: const Value('m4a'),
        localFilePath: const Value('/old/path.m4a'),
        uploadStatus: const Value('uploaded'),
        serverId: const Value('server-abc'),
        gcsUrl: const Value('https://gcs.example/oldblob.m4a'),
        md5Hash: const Value('oldhash'),
        resumableSessionUri: const Value('https://resume.example/session'),
        uploadedBytes: const Value(999),
        retryCount: const Value(2),
        lastRetryAt: Value(DateTime(2024, 1, 1)),
        cleaningStatus: const Value('none'),
        recordedAt: Value(DateTime(2024, 1, 1)),
      ),
    );
  }

  test(
    'replaceAudio resets upload state and writes new file metadata',
    () async {
      await seedUploaded('rec-1');

      final ok = await repo.replaceAudio(
        recordingId: 'rec-1',
        newFilePath: '/new/path.m4a',
        newDurationSeconds: 42.5,
        newFileSizeBytes: 2048,
      );

      expect(ok, isTrue);

      final updated = await repo.getRecordingById('rec-1');
      expect(updated, isNotNull);
      expect(updated!.localFilePath, '/new/path.m4a');
      expect(updated.durationSeconds, 42.5);
      expect(updated.fileSizeBytes, 2048);
      expect(updated.uploadStatus, 'local');
      expect(updated.md5Hash, isNull);
      expect(updated.resumableSessionUri, isNull);
      expect(updated.uploadedBytes, 0);
      expect(updated.retryCount, 0);
      expect(updated.lastRetryAt, isNull);

      expect(updated.serverId, 'server-abc');
      expect(updated.gcsUrl, 'https://gcs.example/oldblob.m4a');
      expect(updated.format, 'm4a');
      expect(updated.title, 'Before');
      expect(updated.projectId, 'proj-1');
      expect(updated.genreId, 'genre-1');
    },
  );

  test(
    'replaceAudio returns false when the recording does not exist',
    () async {
      final ok = await repo.replaceAudio(
        recordingId: 'missing',
        newFilePath: '/new/path.m4a',
        newDurationSeconds: 10.0,
        newFileSizeBytes: 100,
      );
      expect(ok, isFalse);
    },
  );
}
