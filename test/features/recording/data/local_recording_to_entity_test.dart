import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/features/recording/data/local_recording_to_entity.dart';
import 'package:oral_collector/features/recording/domain/entities/pending_metadata_field.dart';

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
        metadataSyncStatus: MetadataSyncStatus.pending,
        pendingMetadataJson: '["title","cleaning_status"]',
        metadataRetryCount: 2,
        metadataLastRetryAt: DateTime(2026, 3, 5),
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
      // ENG-405 reads the outbox off the entity, not the row, so the marker on
      // the list has to survive this projection (ENG-403).
      expect(entity.metadataSyncStatus, MetadataSyncStatus.pending);
      expect(entity.pendingMetadataFields, {
        PendingMetadataField.title,
        PendingMetadataField.cleaningStatus,
      });
      expect(entity.hasPendingMetadata, isTrue);
    });

    test('a row owing nothing reads as having nothing pending', () {
      final row = LocalRecording(
        id: 'id-1',
        reviewFlagsJson: '[]',
        projectId: 'proj-1',
        genreId: 'genre-1',
        durationSeconds: 1,
        fileSizeBytes: 1,
        format: 'm4a',
        localFilePath: '/path/1.m4a',
        uploadStatus: 'local',
        cleaningStatus: 'none',
        recordedAt: DateTime(2026, 1, 2),
        createdAt: DateTime(2026, 1, 2),
        retryCount: 0,
        uploadedBytes: 0,
        metadataSyncStatus: MetadataSyncStatus.synced,
        pendingMetadataJson: '[]',
        metadataRetryCount: 0,
      );

      final entity = localRecordingToEntity(row);

      expect(entity.pendingMetadataFields, isEmpty);
      expect(entity.hasPendingMetadata, isFalse);
    });

    test('copyWith carries the outbox through untouched', () {
      // copyWith rebuilds the entity field by field; a field it forgets is
      // silently reset to its default, which here would erase a pending edit
      // from the screen while the row still owes it.
      final entity = localRecordingToEntity(
        LocalRecording(
          id: 'id-1',
          reviewFlagsJson: '[]',
          projectId: 'proj-1',
          genreId: 'genre-1',
          durationSeconds: 1,
          fileSizeBytes: 1,
          format: 'm4a',
          localFilePath: '/path/1.m4a',
          uploadStatus: 'local',
          cleaningStatus: 'none',
          recordedAt: DateTime(2026, 1, 2),
          createdAt: DateTime(2026, 1, 2),
          retryCount: 0,
          uploadedBytes: 0,
          metadataSyncStatus: MetadataSyncStatus.pending,
          pendingMetadataJson: '["title"]',
          metadataRetryCount: 0,
        ),
      );

      final copy = entity.copyWith(title: 'renamed');

      expect(copy.metadataSyncStatus, MetadataSyncStatus.pending);
      expect(copy.pendingMetadataFields, {PendingMetadataField.title});
      expect(copy, isNot(entity));
      expect(
        copy,
        equals(entity.copyWith(title: 'renamed')),
        reason: 'value equality must account for the outbox',
      );
    });
  });
}
