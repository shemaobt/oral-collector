import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/classification.dart';

class LocalRecordingRepository {
  final AppDatabase _db;

  LocalRecordingRepository(this._db);

  Future<void> insertRecording(LocalRecordingsCompanion data) async {
    await _db.into(_db.localRecordings).insert(data);
  }

  Future<List<LocalRecording>> getAllRecordings(String projectId) async {
    return (_db.select(_db.localRecordings)
          ..where((t) => t.projectId.equals(projectId))
          ..orderBy([(t) => OrderingTerm.desc(t.recordedAt)]))
        .get();
  }

  Future<LocalRecording?> getRecordingById(String id) async {
    return (_db.select(
      _db.localRecordings,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<LocalRecording?> getRecordingByServerId(String serverId) async {
    return (_db.select(
      _db.localRecordings,
    )..where((t) => t.serverId.equals(serverId))).getSingleOrNull();
  }

  Future<bool> updateRecording(String id, LocalRecordingsCompanion data) async {
    final rows = await (_db.update(
      _db.localRecordings,
    )..where((t) => t.id.equals(id))).write(data);
    return rows > 0;
  }

  Future<bool> deleteRecording(String id) async {
    final rows = await (_db.delete(
      _db.localRecordings,
    )..where((t) => t.id.equals(id))).go();
    return rows > 0;
  }

  Future<List<LocalRecording>> getPendingUploads() async {
    return (_db.select(_db.localRecordings)
          ..where(
            (t) =>
                (t.uploadStatus.equals('local') |
                    t.uploadStatus.equals('failed') |
                    t.uploadStatus.equals('uploading')) &
                t.genreId.equals(kUnclassifiedGenreId).not() &
                t.registerId.isNotNull(),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.recordedAt)]))
        .get();
  }

  Future<int> getUnclassifiedCount(String projectId) async {
    final count = _db.localRecordings.id.count();
    final query = _db.selectOnly(_db.localRecordings)
      ..addColumns([count])
      ..where(
        _db.localRecordings.projectId.equals(projectId) &
            (_db.localRecordings.genreId.equals(kUnclassifiedGenreId) |
                _db.localRecordings.registerId.isNull()),
      );
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  Future<bool> markAsUploading(String id) async {
    final rows =
        await (_db.update(
          _db.localRecordings,
        )..where((t) => t.id.equals(id))).write(
          const LocalRecordingsCompanion(uploadStatus: Value('uploading')),
        );
    return rows > 0;
  }

  Future<bool> markAsUploaded(
    String id,
    String serverId,
    String? gcsUrl,
  ) async {
    final rows =
        await (_db.update(
          _db.localRecordings,
        )..where((t) => t.id.equals(id))).write(
          LocalRecordingsCompanion(
            uploadStatus: const Value('uploaded'),
            serverId: Value(serverId),
            gcsUrl: Value(gcsUrl),
          ),
        );
    return rows > 0;
  }

  Future<List<LocalRecording>> getAllLocalRecordings() async {
    return (_db.select(
      _db.localRecordings,
    )..orderBy([(t) => OrderingTerm.desc(t.recordedAt)])).get();
  }

  Future<int> countRecordings(String projectId) async {
    final count = _db.localRecordings.id.count();
    final query = _db.selectOnly(_db.localRecordings)
      ..addColumns([count])
      ..where(_db.localRecordings.projectId.equals(projectId));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  Future<double> totalDuration(String projectId) async {
    final sum = _db.localRecordings.durationSeconds.sum();
    final query = _db.selectOnly(_db.localRecordings)
      ..addColumns([sum])
      ..where(_db.localRecordings.projectId.equals(projectId));
    final result = await query.getSingle();
    return result.read(sum) ?? 0.0;
  }

  Future<int> deleteAllRecordings() async {
    return _db.delete(_db.localRecordings).go();
  }

  Future<int> deleteStaleRecordings(String projectId) async {
    return (_db.delete(_db.localRecordings)..where(
          (t) =>
              t.projectId.equals(projectId) &
              (t.uploadStatus.equals('failed') |
                  t.uploadStatus.equals('uploading')),
        ))
        .go();
  }

  Future<bool> resetRetryCount(String id) async {
    final rows =
        await (_db.update(
          _db.localRecordings,
        )..where((t) => t.id.equals(id))).write(
          const LocalRecordingsCompanion(
            uploadStatus: Value('local'),
            retryCount: Value(0),
            lastRetryAt: Value(null),
          ),
        );
    return rows > 0;
  }

  Future<bool> markAsFailed(String id, {bool incrementRetry = true}) async {
    if (incrementRetry) {
      final recording = await getRecordingById(id);
      if (recording == null) return false;

      final rows =
          await (_db.update(
            _db.localRecordings,
          )..where((t) => t.id.equals(id))).write(
            LocalRecordingsCompanion(
              uploadStatus: const Value('failed'),
              retryCount: Value(recording.retryCount + 1),
              lastRetryAt: Value(DateTime.now()),
            ),
          );
      return rows > 0;
    } else {
      final rows =
          await (_db.update(
            _db.localRecordings,
          )..where((t) => t.id.equals(id))).write(
            const LocalRecordingsCompanion(uploadStatus: Value('failed')),
          );
      return rows > 0;
    }
  }
}
