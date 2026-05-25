import '../../../core/database/app_database.dart';
import '../domain/entities/server_recording.dart';

/// Builds a [LocalRecording] from a [ServerRecording] preserving every
/// recording-level metadata field. The single mapper exists so that callers
/// like the detail screen and the trim editor cannot silently diverge on
/// which fields they carry — divergence is what caused ENG-64.
///
/// `localFilePath` is empty because the file is not on this device; callers
/// must download or stream the audio separately.
LocalRecording serverRecordingToLocal(ServerRecording server) {
  return LocalRecording(
    id: server.id,
    projectId: server.projectId,
    genreId: server.genreId,
    subcategoryId: server.subcategoryId,
    registerId: server.registerId,
    secondaryGenreId: server.secondaryGenreId,
    secondarySubcategoryId: server.secondarySubcategoryId,
    secondaryRegisterId: server.secondaryRegisterId,
    storytellerId: server.storytellerId,
    userId: server.userId,
    title: server.title,
    description: server.description,
    durationSeconds: server.durationSeconds,
    fileSizeBytes: server.fileSizeBytes,
    format: server.format,
    localFilePath: '',
    uploadStatus: server.uploadStatus,
    serverId: server.id,
    gcsUrl: server.gcsUrl,
    cleaningStatus: server.cleaningStatus,
    recordedAt: server.recordedAt,
    createdAt: server.recordedAt,
    retryCount: 0,
    uploadedBytes: 0,
    splitFromId: server.splitFromId,
    splitIndex: server.splitIndex,
    splitSegmentCount: server.splitSegmentCount,
  );
}
