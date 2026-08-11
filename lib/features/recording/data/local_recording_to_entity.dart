import '../../../core/database/app_database.dart';
import '../domain/entities/local_recording_entity.dart';
import '../domain/entities/pending_metadata_field.dart';
import '../domain/entities/review_flag.dart';

/// Single source of truth for the Drift row → domain entity projection. The
/// repository watch streams and the list notifier both go through this so they
/// cannot diverge on which fields they carry. The persistence internals
/// `lastRetryAt`/`md5Hash` are intentionally dropped. See ENG-195.
LocalRecordingEntity localRecordingToEntity(LocalRecording row) {
  return LocalRecordingEntity(
    id: row.id,
    projectId: row.projectId,
    genreId: row.genreId,
    subcategoryId: row.subcategoryId,
    title: row.title,
    description: row.description,
    durationSeconds: row.durationSeconds,
    fileSizeBytes: row.fileSizeBytes,
    format: row.format,
    localFilePath: row.localFilePath,
    uploadStatus: row.uploadStatus,
    serverId: row.serverId,
    gcsUrl: row.gcsUrl,
    registerId: row.registerId,
    secondaryGenreId: row.secondaryGenreId,
    secondarySubcategoryId: row.secondarySubcategoryId,
    secondaryRegisterId: row.secondaryRegisterId,
    storytellerId: row.storytellerId,
    userId: row.userId,
    cleaningStatus: row.cleaningStatus,
    recordedAt: row.recordedAt,
    createdAt: row.createdAt,
    retryCount: row.retryCount,
    resumableSessionUri: row.resumableSessionUri,
    uploadedBytes: row.uploadedBytes,
    splitFromId: row.splitFromId,
    splitIndex: row.splitIndex,
    splitSegmentCount: row.splitSegmentCount,
    reviewFlags: decodeReviewFlags(row.reviewFlagsJson),
    metadataSyncStatus: row.metadataSyncStatus,
    pendingMetadataFields: decodePendingMetadataFields(row.pendingMetadataJson),
  );
}
