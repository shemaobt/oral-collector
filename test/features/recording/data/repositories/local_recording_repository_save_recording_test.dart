/// Tests for LocalRecordingRepository.saveRecording (ENG-192).
///
/// saveRecording centralizes the companion construction that ConfirmationStep
/// used to build inline for both the native and web-direct save paths. These
/// pin the persistence contract: provided fields land, empty optional metadata
/// is omitted (not stored as empty strings), and the web-uploaded form carries
/// serverId + uploaded status.
library;

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

  test('saving a recording persists the provided fields', () async {
    await repo.saveRecording(
      id: 'rec-1',
      projectId: 'proj-1',
      genreId: 'genre-1',
      storytellerId: 'st-1',
      title: 'A Sunday Story',
      durationSeconds: 12.5,
      fileSizeBytes: 2048,
      format: 'm4a',
      localFilePath: '/tmp/rec-1.m4a',
      recordedAt: DateTime.utc(2026, 4, 15, 10),
    );

    final row = await repo.getRecordingById('rec-1');
    expect(row, isNotNull);
    expect(row!.projectId, 'proj-1');
    expect(row.genreId, 'genre-1');
    expect(row.storytellerId, 'st-1');
    expect(row.title, 'A Sunday Story');
    expect(row.durationSeconds, 12.5);
    expect(row.fileSizeBytes, 2048);
    expect(row.format, 'm4a');
    expect(row.localFilePath, '/tmp/rec-1.m4a');
    expect(
      row.recordedAt.isAtSameMomentAs(DateTime.utc(2026, 4, 15, 10)),
      isTrue,
    );
    // Native path leaves the recording pending upload (no serverId yet).
    expect(row.uploadStatus, 'local');
    expect(row.serverId, isNull);
  });

  test('saving omits empty optional metadata', () async {
    await repo.saveRecording(
      id: 'rec-2',
      projectId: 'proj-1',
      genreId: 'genre-1',
      storytellerId: 'st-1',
      title: 'Untitled',
      durationSeconds: 1.0,
      fileSizeBytes: 10,
      format: 'm4a',
      localFilePath: '/tmp/rec-2.m4a',
      recordedAt: DateTime.utc(2026, 4, 15, 10),
      subcategoryId: '',
      registerId: null,
      description: '',
      userId: null,
    );

    final row = await repo.getRecordingById('rec-2');
    expect(row, isNotNull);
    expect(row!.subcategoryId, isNull);
    expect(row.registerId, isNull);
    expect(row.description, isNull);
    expect(row.userId, isNull);
  });

  test('saving persists non-empty optional metadata', () async {
    await repo.saveRecording(
      id: 'rec-4',
      projectId: 'proj-1',
      genreId: 'genre-1',
      storytellerId: 'st-1',
      title: 'With Metadata',
      durationSeconds: 5.0,
      fileSizeBytes: 512,
      format: 'm4a',
      localFilePath: '/tmp/rec-4.m4a',
      recordedAt: DateTime.utc(2026, 4, 15, 10),
      subcategoryId: 'sub-1',
      registerId: 'reg-1',
      description: 'a note',
      userId: 'user-1',
    );

    final row = await repo.getRecordingById('rec-4');
    expect(row, isNotNull);
    expect(row!.subcategoryId, 'sub-1');
    expect(row.registerId, 'reg-1');
    expect(row.description, 'a note');
    expect(row.userId, 'user-1');
  });

  test(
    'saving a web-uploaded recording stores server id and uploaded status',
    () async {
      await repo.saveRecording(
        id: 'rec-3',
        projectId: 'proj-1',
        genreId: 'genre-1',
        storytellerId: 'st-1',
        title: 'Web Story',
        durationSeconds: 30.0,
        fileSizeBytes: 4096,
        format: 'webm',
        localFilePath: '',
        recordedAt: DateTime.utc(2026, 4, 15, 10),
        subcategoryId: 'unclassified',
        uploadStatus: 'uploaded',
        serverId: 'srv-9',
      );

      final row = await repo.getRecordingById('rec-3');
      expect(row, isNotNull);
      expect(row!.uploadStatus, 'uploaded');
      expect(row.serverId, 'srv-9');
      expect(row.localFilePath, '');
      expect(row.subcategoryId, 'unclassified');
    },
  );
}
