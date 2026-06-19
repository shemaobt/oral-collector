import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/entities/local_recording_entity.dart';

/// Projects a freshly captured [LocalRecordingEntity] onto the companion that
/// `saveRecording` inserts. This is the write-path projection for a **fresh
/// insert** — not a clean inverse of [localRecordingToEntity] nor a general
/// serializer: it reproduces the confirmation flow's old inline construction
/// (ENG-192, ENG-201), dropping empty optional metadata to absent and mapping
/// only the columns a new capture sets.
///
/// `createdAt`, `retryCount`, `uploadedBytes` and `cleaningStatus` are left
/// absent so the Drift defaults (`currentDateAndTime`, 0, 0, `'none'`) apply,
/// so the entity's read-path values never overwrite the DB clock/counters on a
/// fresh save. Columns a fresh capture never sets (`gcsUrl`, `secondary*`,
/// `splitFrom*`, `resumableSessionUri`) are intentionally not mapped.
LocalRecordingsCompanion localRecordingEntityToCompanion(
  LocalRecordingEntity e,
) {
  return LocalRecordingsCompanion(
    id: Value(e.id),
    projectId: Value(e.projectId),
    genreId: Value(e.genreId),
    storytellerId: Value(e.storytellerId),
    title: Value(e.title),
    durationSeconds: Value(e.durationSeconds),
    fileSizeBytes: Value(e.fileSizeBytes),
    format: Value(e.format),
    localFilePath: Value(e.localFilePath),
    recordedAt: Value(e.recordedAt),
    uploadStatus: Value(e.uploadStatus),
    subcategoryId: e.subcategoryId != null && e.subcategoryId!.isNotEmpty
        ? Value(e.subcategoryId)
        : const Value.absent(),
    registerId: e.registerId != null && e.registerId!.isNotEmpty
        ? Value(e.registerId)
        : const Value.absent(),
    description: e.description != null && e.description!.isNotEmpty
        ? Value(e.description)
        : const Value.absent(),
    userId: e.userId != null ? Value(e.userId) : const Value.absent(),
    serverId: e.serverId != null ? Value(e.serverId) : const Value.absent(),
  );
}
