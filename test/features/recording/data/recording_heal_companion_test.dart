/// Tests for buildHealMetadataCompanion.
///
/// Heals rows already corrupted by the ENG-64 bug. The function uses a local
/// row with `userId IS NULL` as the marker for "this was inserted by the pre-
/// fix hand-picked cache code" — that bug omitted userId, so any local row
/// missing userId paired with a server row that has one is treated as
/// corrupted and gets all metadata fields rehydrated. Rows whose `userId` is
/// already populated are never touched on user-content fields, so intentional
/// user clears (description set to empty, storyteller removed) survive a
/// refresh.
library;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/features/recording/data/recording_heal_companion.dart';
import 'package:oral_collector/features/recording/data/repositories/local_recording_repository.dart';
import 'package:oral_collector/features/recording/domain/entities/server_recording.dart';

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

  ServerRecording buildServer({
    String id = 'rec-1',
    String? description,
    String? storytellerId,
    String? userId = 'u-server',
    String? secondaryGenreId,
    String? secondarySubcategoryId,
    String? secondaryRegisterId,
    String? gcsUrl,
    String uploadStatus = 'verified',
  }) {
    return ServerRecording(
      id: id,
      projectId: 'project-1',
      genreId: 'genre-1',
      description: description,
      storytellerId: storytellerId,
      userId: userId,
      secondaryGenreId: secondaryGenreId,
      secondarySubcategoryId: secondarySubcategoryId,
      secondaryRegisterId: secondaryRegisterId,
      durationSeconds: 60.0,
      fileSizeBytes: 100000,
      format: 'm4a',
      gcsUrl: gcsUrl,
      uploadStatus: uploadStatus,
      cleaningStatus: 'cleaned',
      recordedAt: DateTime.utc(2026, 5, 1, 10),
    );
  }

  Future<void> seedCorruptedRow({
    String id = 'rec-1',
    String? gcsUrl,
    String uploadStatus = 'verified',
  }) async {
    await repo.insertRecording(
      LocalRecordingsCompanion(
        id: Value(id),
        projectId: const Value('project-1'),
        genreId: const Value('genre-1'),
        title: const Value('Recording'),
        durationSeconds: const Value(60.0),
        fileSizeBytes: const Value(100000),
        format: const Value('m4a'),
        localFilePath: const Value('/local/rec-1.m4a'),
        uploadStatus: Value(uploadStatus),
        serverId: Value(id),
        gcsUrl: Value(gcsUrl),
        cleaningStatus: const Value('cleaned'),
        recordedAt: Value(DateTime.utc(2026, 5, 1, 10)),
      ),
    );
  }

  Future<void> seedHealthyRow({
    String id = 'rec-1',
    String? description = 'edited offline',
    String? storytellerId = 's-local-edit',
    String userId = 'u-local',
    String? secondaryGenreId = 'sg-local-edit',
  }) async {
    await repo.insertRecording(
      LocalRecordingsCompanion(
        id: Value(id),
        projectId: const Value('project-1'),
        genreId: const Value('genre-1'),
        description: Value(description),
        storytellerId: Value(storytellerId),
        userId: Value(userId),
        secondaryGenreId: Value(secondaryGenreId),
        title: const Value('Recording'),
        durationSeconds: const Value(60.0),
        fileSizeBytes: const Value(100000),
        format: const Value('m4a'),
        localFilePath: const Value('/local/rec-1.m4a'),
        uploadStatus: const Value('verified'),
        serverId: Value(id),
        gcsUrl: const Value('https://gcs.example/rec-1.m4a'),
        cleaningStatus: const Value('cleaned'),
        recordedAt: Value(DateTime.utc(2026, 5, 1, 10)),
      ),
    );
  }

  test('heals every user-content field when userId is null locally and the '
      'server has one (the ENG-64 corruption marker)', () async {
    await seedCorruptedRow();
    final local = (await repo.getRecordingById('rec-1'))!;
    final server = buildServer(
      description: 'A story from the server',
      storytellerId: 's-server',
      userId: 'u-server',
      secondaryGenreId: 'sg-server',
      secondarySubcategoryId: 'ss-server',
      secondaryRegisterId: 'sr-server',
    );

    final companion = buildHealMetadataCompanion(local: local, server: server);
    await repo.updateRecording('rec-1', companion);

    final healed = (await repo.getRecordingById('rec-1'))!;
    expect(healed.description, 'A story from the server');
    expect(healed.storytellerId, 's-server');
    expect(healed.userId, 'u-server');
    expect(healed.secondaryGenreId, 'sg-server');
    expect(healed.secondarySubcategoryId, 'ss-server');
    expect(healed.secondaryRegisterId, 'sr-server');
  });

  test(
    'never overwrites local edits when userId is populated locally',
    () async {
      await seedHealthyRow();
      final local = (await repo.getRecordingById('rec-1'))!;
      final server = buildServer(
        description: 'stale server description',
        storytellerId: 's-server-stale',
        userId: 'u-server-stale',
        secondaryGenreId: 'sg-server-stale',
      );

      final companion = buildHealMetadataCompanion(
        local: local,
        server: server,
      );
      await repo.updateRecording('rec-1', companion);

      final after = (await repo.getRecordingById('rec-1'))!;
      expect(after.description, 'edited offline');
      expect(after.storytellerId, 's-local-edit');
      expect(after.userId, 'u-local');
      expect(after.secondaryGenreId, 'sg-local-edit');
    },
  );

  test('preserves a user-cleared description (empty string) even when the '
      'server still has the old text', () async {
    await seedHealthyRow(description: '');
    final local = (await repo.getRecordingById('rec-1'))!;
    final server = buildServer(description: 'pre-clear server description');

    final companion = buildHealMetadataCompanion(local: local, server: server);
    await repo.updateRecording('rec-1', companion);

    final after = (await repo.getRecordingById('rec-1'))!;
    expect(after.description, '');
  });

  test(
    'preserves a user-cleared storytellerId (null) when userId is populated, '
    'so a server refresh does not resurrect the removed storyteller',
    () async {
      await seedHealthyRow(storytellerId: null);
      final local = (await repo.getRecordingById('rec-1'))!;
      final server = buildServer(storytellerId: 's-server-removed-locally');

      final companion = buildHealMetadataCompanion(
        local: local,
        server: server,
      );
      await repo.updateRecording('rec-1', companion);

      final after = (await repo.getRecordingById('rec-1'))!;
      expect(after.storytellerId, isNull);
    },
  );

  test(
    'leaves user-content fields untouched when neither side has values',
    () async {
      await seedCorruptedRow();
      final local = (await repo.getRecordingById('rec-1'))!;
      final server = buildServer(userId: null);

      final companion = buildHealMetadataCompanion(
        local: local,
        server: server,
      );
      await repo.updateRecording('rec-1', companion);

      final after = (await repo.getRecordingById('rec-1'))!;
      expect(after.description, isNull);
      expect(after.storytellerId, isNull);
      expect(after.userId, isNull);
      expect(after.secondaryGenreId, isNull);
    },
  );

  test('sets gcsUrl and uploadStatus from server when server has gcsUrl, '
      'regardless of corruption marker', () async {
    await seedCorruptedRow();
    final local = (await repo.getRecordingById('rec-1'))!;
    final server = buildServer(
      gcsUrl: 'https://gcs.example/rec-1.m4a',
      uploadStatus: 'verified',
    );

    final companion = buildHealMetadataCompanion(local: local, server: server);
    await repo.updateRecording('rec-1', companion);

    final after = (await repo.getRecordingById('rec-1'))!;
    expect(after.gcsUrl, 'https://gcs.example/rec-1.m4a');
    expect(after.uploadStatus, 'verified');
  });

  test(
    'leaves gcsUrl and uploadStatus alone when server has no gcsUrl',
    () async {
      await seedCorruptedRow(
        gcsUrl: 'https://gcs.example/old.m4a',
        uploadStatus: 'uploaded',
      );
      final local = (await repo.getRecordingById('rec-1'))!;
      final server = buildServer(gcsUrl: null);

      final companion = buildHealMetadataCompanion(
        local: local,
        server: server,
      );
      await repo.updateRecording('rec-1', companion);

      final after = (await repo.getRecordingById('rec-1'))!;
      expect(after.gcsUrl, 'https://gcs.example/old.m4a');
      expect(after.uploadStatus, 'uploaded');
    },
  );

  test('partial heal: when userId is the corruption marker, only fields the '
      'server provides get filled', () async {
    await seedCorruptedRow();
    final local = (await repo.getRecordingById('rec-1'))!;
    final server = buildServer(
      description: 'has description',
      storytellerId: null,
      secondaryGenreId: 'has sg',
      secondarySubcategoryId: null,
    );

    final companion = buildHealMetadataCompanion(local: local, server: server);
    await repo.updateRecording('rec-1', companion);

    final after = (await repo.getRecordingById('rec-1'))!;
    expect(after.description, 'has description');
    expect(after.storytellerId, isNull);
    expect(after.secondaryGenreId, 'has sg');
    expect(after.secondarySubcategoryId, isNull);
  });
}
