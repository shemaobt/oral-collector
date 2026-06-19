/// Tests for LocalRecordingRepository.saveRecording (ENG-192, re-typed ENG-201).
///
/// saveRecording centralizes the companion construction that ConfirmationStep
/// used to build inline for both the native and web-direct save paths. It now
/// takes a single LocalRecordingEntity. These pin the persistence contract:
/// provided fields land, empty optional metadata is omitted (not stored as
/// empty strings), the web-uploaded form carries serverId + uploaded status,
/// and DB-managed columns keep their Drift defaults regardless of the entity.
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/features/recording/data/repositories/local_recording_repository.dart';
import 'package:oral_collector/features/recording/domain/entities/local_recording_entity.dart';

/// Builds an entity with sensible defaults so each test states only the fields
/// it asserts on.
LocalRecordingEntity _entity({
  required String id,
  String projectId = 'proj-1',
  String genreId = 'genre-1',
  String? storytellerId = 'st-1',
  String? title = 'A Story',
  String? description,
  double durationSeconds = 1.0,
  int fileSizeBytes = 10,
  String format = 'm4a',
  String localFilePath = '/tmp/rec.m4a',
  String uploadStatus = 'local',
  String? serverId,
  String? subcategoryId,
  String? registerId,
  String? userId,
  String cleaningStatus = 'none',
  DateTime? recordedAt,
  DateTime? createdAt,
  int retryCount = 0,
  int uploadedBytes = 0,
}) {
  return LocalRecordingEntity(
    id: id,
    projectId: projectId,
    genreId: genreId,
    subcategoryId: subcategoryId,
    title: title,
    description: description,
    durationSeconds: durationSeconds,
    fileSizeBytes: fileSizeBytes,
    format: format,
    localFilePath: localFilePath,
    uploadStatus: uploadStatus,
    serverId: serverId,
    registerId: registerId,
    storytellerId: storytellerId,
    userId: userId,
    cleaningStatus: cleaningStatus,
    recordedAt: recordedAt ?? DateTime.utc(2026, 4, 15, 10),
    createdAt: createdAt ?? DateTime.utc(2026, 4, 15, 10),
    retryCount: retryCount,
    uploadedBytes: uploadedBytes,
  );
}

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
      _entity(
        id: 'rec-1',
        title: 'A Sunday Story',
        durationSeconds: 12.5,
        fileSizeBytes: 2048,
        format: 'm4a',
        localFilePath: '/tmp/rec-1.m4a',
        recordedAt: DateTime.utc(2026, 4, 15, 10),
      ),
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
      _entity(
        id: 'rec-2',
        title: 'Untitled',
        subcategoryId: '',
        registerId: null,
        description: '',
        userId: null,
      ),
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
      _entity(
        id: 'rec-4',
        title: 'With Metadata',
        durationSeconds: 5.0,
        fileSizeBytes: 512,
        localFilePath: '/tmp/rec-4.m4a',
        subcategoryId: 'sub-1',
        registerId: 'reg-1',
        description: 'a note',
        userId: 'user-1',
      ),
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
        _entity(
          id: 'rec-3',
          title: 'Web Story',
          durationSeconds: 30.0,
          fileSizeBytes: 4096,
          format: 'webm',
          localFilePath: '',
          subcategoryId: 'unclassified',
          uploadStatus: 'uploaded',
          serverId: 'srv-9',
        ),
      );

      final row = await repo.getRecordingById('rec-3');
      expect(row, isNotNull);
      expect(row!.uploadStatus, 'uploaded');
      expect(row.serverId, 'srv-9');
      expect(row.localFilePath, '');
      expect(row.subcategoryId, 'unclassified');
    },
  );

  test('saving lets Drift assign createdAt and DB-managed defaults, '
      'ignoring entity values', () async {
    await repo.saveRecording(
      _entity(
        id: 'rec-5',
        createdAt: DateTime.utc(2000, 1, 1),
        retryCount: 99,
        uploadedBytes: 4242,
        cleaningStatus: 'bogus',
      ),
    );

    final row = await repo.getRecordingById('rec-5');
    expect(row, isNotNull);
    // createdAt comes from the DB clock (column default), not the entity.
    expect(row!.createdAt.isAtSameMomentAs(DateTime.utc(2000, 1, 1)), isFalse);
    expect(row.createdAt.isAfter(DateTime.utc(2020)), isTrue);
    // The DB-managed defaults win over whatever the entity carried.
    expect(row.retryCount, 0);
    expect(row.uploadedBytes, 0);
    expect(row.cleaningStatus, 'none');
  });
}
