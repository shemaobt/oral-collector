import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/features/recording/data/local_recording_to_entity.dart';

void main() {
  group('localRecordingToEntity', () {
    test('carries every recording-level field from the row', () {
      final row = LocalRecording(
        id: 'id-1',
        reviewFlagsJson: '[]',
        projectId: 'proj-1',
        genreId: 'genre-1',
        subcategoryId: 'subcat-1',
        title: 'title-1',
        description: 'desc-1',
        durationSeconds: 12.5,
        fileSizeBytes: 111,
        format: 'm4a',
        localFilePath: '/path/1.m4a',
        uploadStatus: 'uploading',
        serverId: 'srv-1',
        gcsUrl: 'gs://bucket/1',
        registerId: 'reg-1',
        secondaryGenreId: 'sgenre-1',
        secondarySubcategoryId: 'ssubcat-1',
        secondaryRegisterId: 'sreg-1',
        storytellerId: 'story-1',
        userId: 'user-1',
        cleaningStatus: 'needs_cleaning',
        recordedAt: DateTime(2026, 1, 2, 3, 4, 5),
        createdAt: DateTime(2026, 2, 3, 4, 5, 6),
        retryCount: 7,
        lastRetryAt: DateTime(2026, 3, 4),
        resumableSessionUri: 'uri-1',
        uploadedBytes: 222,
        md5Hash: 'hash-1',
        splitFromId: 'split-1',
        splitIndex: 3,
        splitSegmentCount: 9,
      );

      final entity = localRecordingToEntity(row);

      expect(entity.id, 'id-1');
      expect(entity.projectId, 'proj-1');
      expect(entity.genreId, 'genre-1');
      expect(entity.subcategoryId, 'subcat-1');
      expect(entity.title, 'title-1');
      expect(entity.description, 'desc-1');
      expect(entity.durationSeconds, 12.5);
      expect(entity.fileSizeBytes, 111);
      expect(entity.format, 'm4a');
      expect(entity.localFilePath, '/path/1.m4a');
      expect(entity.uploadStatus, 'uploading');
      expect(entity.serverId, 'srv-1');
      expect(entity.gcsUrl, 'gs://bucket/1');
      expect(entity.registerId, 'reg-1');
      expect(entity.secondaryGenreId, 'sgenre-1');
      expect(entity.secondarySubcategoryId, 'ssubcat-1');
      expect(entity.secondaryRegisterId, 'sreg-1');
      expect(entity.storytellerId, 'story-1');
      expect(entity.userId, 'user-1');
      expect(entity.cleaningStatus, 'needs_cleaning');
      expect(entity.recordedAt, DateTime(2026, 1, 2, 3, 4, 5));
      expect(entity.createdAt, DateTime(2026, 2, 3, 4, 5, 6));
      expect(entity.retryCount, 7);
      expect(entity.resumableSessionUri, 'uri-1');
      expect(entity.uploadedBytes, 222);
      expect(entity.splitFromId, 'split-1');
      expect(entity.splitIndex, 3);
      expect(entity.splitSegmentCount, 9);
    });
  });
}
