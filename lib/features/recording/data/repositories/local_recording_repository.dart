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

  Stream<LocalRecording?> watchRecordingById(String id) {
    return (_db.select(
      _db.localRecordings,
    )..where((t) => t.id.equals(id))).watchSingleOrNull();
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
                t.uploadStatus.equals('local') |
                t.uploadStatus.equals('failed') |
                t.uploadStatus.equals('uploading'),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.recordedAt)]))
        .get();
  }

  Future<List<LocalRecording>> getPendingWebUploads() async {
    return (_db.select(_db.localRecordings)
          ..where((t) => t.uploadStatus.equals('web_uploading'))
          ..orderBy([(t) => OrderingTerm.asc(t.recordedAt)]))
        .get();
  }

  Future<({int count, double durationSeconds})> getLocalUnclassifiedStats(
    String projectId,
  ) async {
    final countExpr = _db.localRecordings.id.count();
    final durationExpr = _db.localRecordings.durationSeconds.sum();
    final query = _db.selectOnly(_db.localRecordings)
      ..addColumns([countExpr, durationExpr])
      ..where(
        _db.localRecordings.projectId.equals(projectId) &
            (_db.localRecordings.genreId.equals(kUnclassifiedGenreId) |
                _db.localRecordings.registerId.isNull()) &
            _db.localRecordings.uploadStatus.equals('uploaded').not() &
            _db.localRecordings.uploadStatus.equals('verified').not(),
      );
    final row = await query.getSingle();
    return (
      count: row.read(countExpr) ?? 0,
      durationSeconds: row.read(durationExpr) ?? 0.0,
    );
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

  Future<bool> replaceAudio({
    required String recordingId,
    required String newFilePath,
    required double newDurationSeconds,
    required int newFileSizeBytes,
  }) async {
    final rows =
        await (_db.update(
          _db.localRecordings,
        )..where((t) => t.id.equals(recordingId))).write(
          LocalRecordingsCompanion(
            localFilePath: Value(newFilePath),
            durationSeconds: Value(newDurationSeconds),
            fileSizeBytes: Value(newFileSizeBytes),
            uploadStatus: const Value('local'),
            md5Hash: const Value(null),
            resumableSessionUri: const Value(null),
            uploadedBytes: const Value(0),
            retryCount: const Value(0),
            lastRetryAt: const Value(null),
          ),
        );
    return rows > 0;
  }

  /// Inserts one child row per segment, propagating parent metadata per the
  /// contract in `docs/recording-split-semantics.md`. See ENG-64.
  Future<List<String>> splitRecording({
    required LocalRecording parent,
    required List<SplitSegmentSpec> segments,
  }) async {
    return _db.transaction(() async {
      final ids = <String>[];
      for (final seg in segments) {
        await _db.into(_db.localRecordings).insert(
              LocalRecordingsCompanion(
                id: Value(seg.id),
                projectId: Value(parent.projectId),
                genreId: Value(
                  (seg.genreOverride != null && seg.genreOverride!.isNotEmpty)
                      ? seg.genreOverride!
                      : parent.genreId,
                ),
                subcategoryId: (seg.subcategoryOverride != null &&
                        seg.subcategoryOverride!.isNotEmpty)
                    ? Value(seg.subcategoryOverride)
                    : Value(parent.subcategoryId),
                registerId: (seg.registerOverride != null &&
                        seg.registerOverride!.isNotEmpty)
                    ? Value(seg.registerOverride)
                    : Value(parent.registerId),
                secondaryGenreId: Value(parent.secondaryGenreId),
                secondarySubcategoryId: Value(parent.secondarySubcategoryId),
                secondaryRegisterId: Value(parent.secondaryRegisterId),
                storytellerId: Value(parent.storytellerId),
                userId: Value(parent.userId),
                title: Value(seg.title),
                description: Value(parent.description),
                durationSeconds: Value(seg.durationSeconds),
                fileSizeBytes: Value(seg.fileSizeBytes),
                format: Value(parent.format),
                localFilePath: Value(seg.localFilePath),
                uploadStatus: const Value('local'),
                cleaningStatus: const Value('none'),
                recordedAt: Value(parent.recordedAt),
              ),
            );
        ids.add(seg.id);
      }
      return ids;
    });
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

/// Per-segment input for [LocalRecordingRepository.splitRecording]. Fields
/// that vary per child; the rest are inherited from the parent.
class SplitSegmentSpec {
  final String id;
  final String title;
  final String localFilePath;
  final double durationSeconds;
  final int fileSizeBytes;
  final String? genreOverride;
  final String? subcategoryOverride;
  final String? registerOverride;

  const SplitSegmentSpec({
    required this.id,
    required this.title,
    required this.localFilePath,
    required this.durationSeconds,
    required this.fileSizeBytes,
    this.genreOverride,
    this.subcategoryOverride,
    this.registerOverride,
  });
}
