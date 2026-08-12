/// Tests for RecordingBoostPersister (ENG-402).
///
/// A trim-editor save with no cut points is not a split: it re-encodes the same
/// story at a new volume. The split persister was doing it anyway — deleting the
/// original locally and remotely and inserting a child — and the remote delete
/// is best-effort, so an offline edit left the server holding two live
/// recordings and the project counted the story twice.
///
/// This path keeps the row: same id, same serverId, new audio, queued to go up
/// again against the recording the server already has.
library;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/features/recording/data/local_recording_to_entity.dart';
import 'package:oral_collector/features/recording/data/repositories/local_recording_repository.dart';
import 'package:oral_collector/features/recording/data/services/recording_boost_persister.dart';
import 'package:oral_collector/features/recording/domain/entities/local_recording_entity.dart';
import 'package:oral_collector/features/recording/domain/entities/pending_metadata_field.dart';

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

  Future<LocalRecordingEntity> seed({
    String id = 'rec-1',
    String? serverId,
    String uploadStatus = 'verified',
  }) async {
    await repo.insertRecording(
      LocalRecordingsCompanion(
        id: Value(id),
        projectId: const Value('project-1'),
        genreId: const Value('genre-1'),
        title: const Value('Story'),
        description: const Value('a description with enough substance'),
        durationSeconds: const Value(60.0),
        fileSizeBytes: const Value(100000),
        format: const Value('m4a'),
        localFilePath: Value('/local/$id.m4a'),
        uploadStatus: Value(uploadStatus),
        serverId: Value(serverId),
        gcsUrl: serverId != null
            ? Value('https://gcs.example/$serverId.m4a')
            : const Value(null),
        cleaningStatus: const Value('cleaned'),
        recordedAt: Value(DateTime.utc(2026, 5, 1, 10)),
      ),
    );
    return localRecordingToEntity((await repo.getRecordingById(id))!);
  }

  RecordingBoostPersister persisterFor({
    Future<void> Function()? triggerUpload,
    Future<void> Function(LocalRecordingEntity recording)? trashPrevious,
  }) => RecordingBoostPersister(
    localRepo: repo,
    triggerUpload: triggerUpload ?? () async {},
    trashPrevious: trashPrevious,
  );

  Future<void> applyBoost(
    RecordingBoostPersister persister,
    LocalRecordingEntity recording, {
    String newFilePath = '/local/boosted.m4a',
    double newDurationSeconds = 60.0,
    int newFileSizeBytes = 123456,
  }) => persister.persist(
    recording: recording,
    newFilePath: newFilePath,
    newDurationSeconds: newDurationSeconds,
    newFileSizeBytes: newFileSizeBytes,
  );

  test('the row points at the boosted audio', () async {
    final recording = await seed(serverId: 'srv-1');

    await applyBoost(
      persisterFor(),
      recording,
      newFilePath: '/local/boosted.m4a',
      newDurationSeconds: 59.8,
      newFileSizeBytes: 123456,
    );

    final row = (await repo.getRecordingById('rec-1'))!;
    expect(row.localFilePath, '/local/boosted.m4a');
    expect(row.durationSeconds, 59.8);
    expect(row.fileSizeBytes, 123456);
  });

  test('queues the boosted audio to go up against the same server '
      'recording', () async {
    final recording = await seed(serverId: 'srv-1');

    await applyBoost(persisterFor(), recording);

    final row = (await repo.getRecordingById('rec-1'))!;
    // Back in the upload queue, still pointing at the server's recording: the
    // re-upload overwrites that recording's audio instead of creating another.
    expect(row.uploadStatus, 'local');
    expect(row.serverId, 'srv-1');
    // The resume state belonged to the audio that was just replaced.
    expect(row.resumableSessionUri, isNull);
    expect(row.uploadedBytes, 0);
    expect(row.retryCount, 0);
  });

  test('owes the server the new duration and size', () async {
    final recording = await seed(serverId: 'srv-1');

    await applyBoost(persisterFor(), recording);

    final row = (await repo.getRecordingById('rec-1'))!;
    expect(row.metadataSyncStatus, MetadataSyncStatus.pending);
    expect(
      decodePendingMetadataFields(row.pendingMetadataJson),
      contains(PendingMetadataField.audio),
    );
  });

  test('owes nothing when the server does not have the recording', () async {
    final recording = await seed(uploadStatus: 'local');

    await applyBoost(persisterFor(), recording);

    final row = (await repo.getRecordingById('rec-1'))!;
    expect(row.metadataSyncStatus, MetadataSyncStatus.synced);
    expect(decodePendingMetadataFields(row.pendingMetadataJson), isEmpty);
    expect(row.uploadStatus, 'local');
  });

  test('archives the replaced audio after the row has committed', () async {
    final recording = await seed(serverId: 'srv-1');
    String? pathOnRowDuringTrash;
    LocalRecordingEntity? trashed;

    await applyBoost(
      persisterFor(
        trashPrevious: (r) async {
          trashed = r;
          pathOnRowDuringTrash = (await repo.getRecordingById(
            'rec-1',
          ))!.localFilePath;
        },
      ),
      recording,
    );

    // The callback gets the recording as it was, so it can find the file the
    // row no longer names — the row already points at the boosted audio.
    expect(trashed?.localFilePath, '/local/rec-1.m4a');
    expect(pathOnRowDuringTrash, '/local/boosted.m4a');
  });

  test('kicks the upload queue exactly once', () async {
    final recording = await seed(serverId: 'srv-1');
    var triggerCalls = 0;

    await applyBoost(
      persisterFor(
        triggerUpload: () async {
          triggerCalls++;
        },
      ),
      recording,
    );

    expect(triggerCalls, 1);
  });
}
