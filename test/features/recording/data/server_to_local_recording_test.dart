/// Tests for serverRecordingToLocal — the single mapper that every caller
/// must use when converting a backend recording into a LocalRecording. See
/// ENG-64 and `docs/recording-split-semantics.md`.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/recording/data/server_to_local_recording.dart';
import 'package:oral_collector/features/recording/domain/entities/server_recording.dart';

void main() {
  ServerRecording fullServerRecording() => ServerRecording(
        id: 'r-1',
        projectId: 'p-1',
        genreId: 'g-primary',
        subcategoryId: 's-primary',
        registerId: 'reg-primary',
        secondaryGenreId: 'g-secondary',
        secondarySubcategoryId: 's-secondary',
        secondaryRegisterId: 'reg-secondary',
        storytellerId: 'st-1',
        userId: 'u-1',
        title: 'A story',
        description: 'A story told on a Sunday',
        durationSeconds: 60.0,
        fileSizeBytes: 123456,
        format: 'm4a',
        gcsUrl: 'https://gcs.example/r-1.m4a',
        uploadStatus: 'verified',
        cleaningStatus: 'cleaned',
        recordedAt: DateTime.utc(2026, 5, 1, 10),
        splitFromId: 'parent-X',
        splitIndex: 2,
        splitSegmentCount: 3,
      );

  test('carries every recording-level metadata field', () {
    final server = fullServerRecording();

    final local = serverRecordingToLocal(server);

    expect(local.id, 'r-1');
    expect(local.projectId, 'p-1');
    expect(local.genreId, 'g-primary');
    expect(local.subcategoryId, 's-primary');
    expect(local.registerId, 'reg-primary');
    expect(local.secondaryGenreId, 'g-secondary');
    expect(local.secondarySubcategoryId, 's-secondary');
    expect(local.secondaryRegisterId, 'reg-secondary');
    expect(local.storytellerId, 'st-1');
    expect(local.userId, 'u-1');
    expect(local.title, 'A story');
    expect(local.description, 'A story told on a Sunday');
    expect(local.format, 'm4a');
    expect(local.gcsUrl, 'https://gcs.example/r-1.m4a');
    expect(local.uploadStatus, 'verified');
    expect(local.cleaningStatus, 'cleaned');
    expect(local.recordedAt, DateTime.utc(2026, 5, 1, 10));
    expect(local.splitFromId, 'parent-X');
    expect(local.splitIndex, 2);
    expect(local.splitSegmentCount, 3);
  });

  test('serverId is set from server.id and localFilePath is empty (file is '
      'not on this device)', () {
    final local = serverRecordingToLocal(fullServerRecording());
    expect(local.serverId, 'r-1');
    expect(local.localFilePath, '');
  });

  test('preserves null metadata when the server response omits fields', () {
    final bare = ServerRecording(
      id: 'r-2',
      projectId: 'p-2',
      genreId: 'g',
      durationSeconds: 1.0,
      fileSizeBytes: 1,
      format: 'm4a',
      uploadStatus: 'local',
      cleaningStatus: 'none',
      recordedAt: DateTime.utc(2026, 5, 1),
    );

    final local = serverRecordingToLocal(bare);

    expect(local.description, isNull);
    expect(local.storytellerId, isNull);
    expect(local.userId, isNull);
    expect(local.secondaryGenreId, isNull);
    expect(local.secondarySubcategoryId, isNull);
    expect(local.secondaryRegisterId, isNull);
    expect(local.splitFromId, isNull);
    expect(local.splitIndex, isNull);
    expect(local.splitSegmentCount, isNull);
  });
}
