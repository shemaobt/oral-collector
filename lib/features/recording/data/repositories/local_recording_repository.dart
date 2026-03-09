import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';

class LocalRecordingRepository {
  final AppDatabase _db;

  LocalRecordingRepository(this._db);

  /// Insert a new recording into the local database.
  Future<void> insertRecording(LocalRecordingsCompanion data) async {
    await _db.into(_db.localRecordings).insert(data);
  }

  /// Get all recordings for a given project, ordered by recordedAt descending.
  Future<List<LocalRecording>> getAllRecordings(String projectId) async {
    return (_db.select(_db.localRecordings)
          ..where((t) => t.projectId.equals(projectId))
          ..orderBy([
            (t) => OrderingTerm.desc(t.recordedAt),
          ]))
        .get();
  }

  /// Get a single recording by its ID, or null if not found.
  Future<LocalRecording?> getRecordingById(String id) async {
    return (_db.select(_db.localRecordings)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Update a recording by ID with the given companion data.
  Future<bool> updateRecording(
      String id, LocalRecordingsCompanion data) async {
    final rows = await (_db.update(_db.localRecordings)
          ..where((t) => t.id.equals(id)))
        .write(data);
    return rows > 0;
  }

  /// Delete a recording by ID.
  Future<bool> deleteRecording(String id) async {
    final rows = await (_db.delete(_db.localRecordings)
          ..where((t) => t.id.equals(id)))
        .go();
    return rows > 0;
  }

  /// Get all recordings with upload status 'local' or 'failed' (pending upload).
  Future<List<LocalRecording>> getPendingUploads() async {
    return (_db.select(_db.localRecordings)
          ..where((t) =>
              t.uploadStatus.equals('local') |
              t.uploadStatus.equals('failed'))
          ..orderBy([
            (t) => OrderingTerm.asc(t.recordedAt),
          ]))
        .get();
  }

  /// Mark a recording as currently uploading.
  Future<bool> markAsUploading(String id) async {
    final rows = await (_db.update(_db.localRecordings)
          ..where((t) => t.id.equals(id)))
        .write(const LocalRecordingsCompanion(
      uploadStatus: Value('uploading'),
    ));
    return rows > 0;
  }

  /// Mark a recording as successfully uploaded with server ID and GCS URL.
  Future<bool> markAsUploaded(
      String id, String serverId, String gcsUrl) async {
    final rows = await (_db.update(_db.localRecordings)
          ..where((t) => t.id.equals(id)))
        .write(LocalRecordingsCompanion(
      uploadStatus: const Value('uploaded'),
      serverId: Value(serverId),
      gcsUrl: Value(gcsUrl),
    ));
    return rows > 0;
  }

  /// Mark a recording upload as failed, optionally incrementing the retry count.
  Future<bool> markAsFailed(String id, {bool incrementRetry = true}) async {
    if (incrementRetry) {
      final recording = await getRecordingById(id);
      if (recording == null) return false;

      final rows = await (_db.update(_db.localRecordings)
            ..where((t) => t.id.equals(id)))
          .write(LocalRecordingsCompanion(
        uploadStatus: const Value('failed'),
        retryCount: Value(recording.retryCount + 1),
        lastRetryAt: Value(DateTime.now()),
      ));
      return rows > 0;
    } else {
      final rows = await (_db.update(_db.localRecordings)
            ..where((t) => t.id.equals(id)))
          .write(const LocalRecordingsCompanion(
        uploadStatus: Value('failed'),
      ));
      return rows > 0;
    }
  }
}
