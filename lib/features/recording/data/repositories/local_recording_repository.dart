import 'package:drift/drift.dart';

import '../../../../core/config/upload_retry_policy.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/entities/classification.dart';
import '../../domain/entities/local_recording_entity.dart';
import '../../domain/entities/review_flag.dart';
import '../local_recording_entity_to_companion.dart';
import '../local_recording_to_entity.dart';

class LocalRecordingRepository {
  final AppDatabase _db;

  LocalRecordingRepository(this._db);

  Future<void> insertRecording(LocalRecordingsCompanion data) async {
    await _db.into(_db.localRecordings).insert(data);
  }

  /// Persists a freshly captured recording from its domain entity. Delegates to
  /// [localRecordingEntityToCompanion], which drops empty optional metadata and
  /// leaves the DB-managed columns to their Drift defaults. See ENG-192,
  /// ENG-201.
  Future<void> saveRecording(LocalRecordingEntity entity) async {
    await insertRecording(localRecordingEntityToCompanion(entity));
  }

  /// Inserts [data], or updates the row in place when its primary key already
  /// exists. Columns absent from [data] are left untouched, so an in-progress
  /// upload's resume state (`resumableSessionUri`, `uploadedBytes`) survives a
  /// retry that reuses the same id.
  Future<void> upsertRecording(LocalRecordingsCompanion data) async {
    await _db.into(_db.localRecordings).insertOnConflictUpdate(data);
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

  /// One-shot, row-decoupled analogue of [getRecordingById]: projects to the
  /// domain entity so callers (the trim editor load path) never see a Drift
  /// row. See ENG-202.
  Future<LocalRecordingEntity?> getRecordingEntityById(String id) async {
    final row = await getRecordingById(id);
    return row == null ? null : _fromRow(row);
  }

  /// Row-decoupled analogue of [getRecordingByServerId]. See ENG-202.
  Future<LocalRecordingEntity?> getRecordingEntityByServerId(
    String serverId,
  ) async {
    final row = await getRecordingByServerId(serverId);
    return row == null ? null : _fromRow(row);
  }

  /// Watches a single recording as the row-decoupled domain entity. Maps before
  /// `.distinct()` so dedup runs on [LocalRecordingEntity]'s value equality —
  /// the detail watch stream consumes this (ENG-199/ENG-200). See ENG-195.
  Stream<LocalRecordingEntity?> watchRecordingEntityById(String id) {
    return (_db.select(_db.localRecordings)..where((t) => t.id.equals(id)))
        .watchSingleOrNull()
        .map((row) => row == null ? null : _fromRow(row))
        .distinct();
  }

  Future<bool> updateRecording(String id, LocalRecordingsCompanion data) async {
    final rows = await (_db.update(
      _db.localRecordings,
    )..where((t) => t.id.equals(id))).write(data);
    return rows > 0;
  }

  // Typed classification/metadata writes (ENG-194): the detail screen used to
  // build these companions inline in the presentation layer. The null handling
  // is load-bearing and intentionally NOT unified — `classify` omits a null
  // register (Value.absent, preserve), while `moveCategory`/secondary write
  // null (clear).

  Future<bool> setStoryteller(String id, {required String? storytellerId}) {
    return updateRecording(
      id,
      LocalRecordingsCompanion(
        storytellerId: storytellerId == null
            ? const Value(null)
            : Value(storytellerId),
      ),
    );
  }

  Future<bool> updateDescription(String id, String description) {
    return updateRecording(
      id,
      LocalRecordingsCompanion(description: Value(description)),
    );
  }

  Future<bool> updateCleaningStatus(String id, String cleaningStatus) {
    return updateRecording(
      id,
      LocalRecordingsCompanion(cleaningStatus: Value(cleaningStatus)),
    );
  }

  Future<bool> moveCategory(
    String id, {
    required String genreId,
    required String? subcategoryId,
    required bool clearSecondary,
    String? secondaryGenreId,
    String? secondarySubcategoryId,
    String? secondaryRegisterId,
  }) {
    return updateRecording(
      id,
      LocalRecordingsCompanion(
        genreId: Value(genreId),
        subcategoryId: Value(subcategoryId),
        secondaryGenreId: clearSecondary
            ? const Value(null)
            : Value(secondaryGenreId),
        secondarySubcategoryId: clearSecondary
            ? const Value(null)
            : Value(secondarySubcategoryId),
        secondaryRegisterId: clearSecondary
            ? const Value(null)
            : Value(secondaryRegisterId),
      ),
    );
  }

  Future<bool> classify(
    String id, {
    required String genreId,
    String? subcategoryId,
    String? registerId,
    String? secondaryGenreId,
    String? secondarySubcategoryId,
    String? secondaryRegisterId,
  }) {
    return updateRecording(
      id,
      LocalRecordingsCompanion(
        genreId: Value(genreId),
        subcategoryId: Value(subcategoryId),
        registerId: registerId != null
            ? Value(registerId)
            : const Value.absent(),
        secondaryGenreId: Value(secondaryGenreId),
        secondarySubcategoryId: Value(secondarySubcategoryId),
        secondaryRegisterId: Value(secondaryRegisterId),
      ),
    );
  }

  Future<bool> updateSecondaryClassification(
    String id, {
    String? genreId,
    String? subcategoryId,
    String? registerId,
  }) {
    return updateRecording(
      id,
      LocalRecordingsCompanion(
        secondaryGenreId: Value(genreId),
        secondarySubcategoryId: Value(subcategoryId),
        secondaryRegisterId: Value(registerId),
      ),
    );
  }

  Future<int> reassignStorytellerId({
    required String fromId,
    required String toId,
  }) async {
    return (_db.update(_db.localRecordings)
          ..where((t) => t.storytellerId.equals(fromId)))
        .write(LocalRecordingsCompanion(storytellerId: Value(toId)));
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
          ..orderBy([
            (t) => OrderingTerm.asc(t.createdAt),
            (t) => OrderingTerm.asc(t.id),
          ]))
        .get();
  }

  Future<List<LocalRecording>> getPendingWebUploads() async {
    return (_db.select(_db.localRecordings)
          ..where((t) => t.uploadStatus.equals('web_uploading'))
          ..orderBy([
            (t) => OrderingTerm.asc(t.createdAt),
            (t) => OrderingTerm.asc(t.id),
          ]))
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

  /// Hands rows orphaned in `uploading` (the app died mid-upload) back to the
  /// queue at startup. Only [uploadStatus] is rewritten — retry budget and the
  /// resumable offset survive, so the upload resumes instead of restarting.
  /// Target `local` (not `failed`) keeps the row clear of [deleteStaleRecordings].
  Future<int> resetStuckUploading() async {
    return (_db.update(_db.localRecordings)
          ..where((t) => t.uploadStatus.equals('uploading')))
        .write(const LocalRecordingsCompanion(uploadStatus: Value('local')));
  }

  /// Stores what the server says the recording still owes (ENG-379).
  ///
  /// Its own write rather than a field on the typed metadata writes: the flags
  /// are the server's answer, not the user's edit, and the two arrive from
  /// different places at different times.
  Future<bool> updateReviewFlags(String id, List<ReviewFlag> flags) {
    return updateRecording(
      id,
      LocalRecordingsCompanion(
        reviewFlagsJson: Value(encodeReviewFlags(flags)),
      ),
    );
  }

  /// Retires rows that already spent their retry budget under the old generic
  /// `failed` status (ENG-377), at startup.
  ///
  /// The writers no longer produce this shape, but that only helps recordings
  /// made after the update. Devices are carrying these rows now — that is what
  /// was reported — and each one keeps the pending counter high and the sync
  /// chip lit over a queue that refuses it. Without this sweep the person who
  /// reported the bug would install the fix and still see the bug.
  ///
  /// Runs on every launch, so it is written to be idempotent: the `failed`
  /// clause stops matching as soon as a row is retired. Deliberately a data
  /// normalisation here rather than a schema migration — nothing about the
  /// table changes, only rows the old code left behind.
  Future<int> normalizeExhaustedUploads() async {
    return (_db.update(_db.localRecordings)..where(
          (t) =>
              t.uploadStatus.equals('failed') &
              t.retryCount.isBiggerOrEqualValue(kMaxUploadRetries),
        ))
        .write(
          const LocalRecordingsCompanion(
            uploadStatus: Value('failed_exhausted'),
          ),
        );
  }

  /// Persists a freshly-downloaded audio file alongside its full metadata.
  /// If a row for [recording.id] already exists locally, only [localFilePath]
  /// and the server's review flags are updated, so local edits (description,
  /// storyteller, secondary classification) are preserved. Otherwise the full
  /// row is inserted from
  /// every entity field, so all metadata reaches the database — the
  /// hand-picked-subset bug from ENG-64 cannot recur here. The persistence-only
  /// columns (`lastRetryAt`, `md5Hash`) are left absent (null), which is correct
  /// for a server-sourced recording with no prior local row.
  Future<void> cacheDownloadedAudio({
    required LocalRecordingEntity recording,
    required String localFilePath,
  }) async {
    await _db.transaction(() async {
      final existing = await getRecordingById(recording.id);
      if (existing != null) {
        // The review flags ride along with the path even though the rest of the
        // server's metadata does not. The narrow update exists to protect local
        // *edits*; the flags are not an edit — only the server produces them,
        // and it recomputed them just before answering (ENG-373). Leaving them
        // stale here would mean a downloaded recording never learns what it
        // still owes (ENG-379).
        await (_db.update(
          _db.localRecordings,
        )..where((t) => t.id.equals(recording.id))).write(
          LocalRecordingsCompanion(
            localFilePath: Value(localFilePath),
            reviewFlagsJson: Value(encodeReviewFlags(recording.reviewFlags)),
          ),
        );
      } else {
        await _db
            .into(_db.localRecordings)
            .insert(
              LocalRecordingsCompanion(
                id: Value(recording.id),
                projectId: Value(recording.projectId),
                genreId: Value(recording.genreId),
                subcategoryId: Value(recording.subcategoryId),
                title: Value(recording.title),
                description: Value(recording.description),
                durationSeconds: Value(recording.durationSeconds),
                fileSizeBytes: Value(recording.fileSizeBytes),
                format: Value(recording.format),
                localFilePath: Value(localFilePath),
                uploadStatus: Value(recording.uploadStatus),
                serverId: Value(recording.serverId),
                gcsUrl: Value(recording.gcsUrl),
                registerId: Value(recording.registerId),
                secondaryGenreId: Value(recording.secondaryGenreId),
                secondarySubcategoryId: Value(recording.secondarySubcategoryId),
                secondaryRegisterId: Value(recording.secondaryRegisterId),
                storytellerId: Value(recording.storytellerId),
                userId: Value(recording.userId),
                cleaningStatus: Value(recording.cleaningStatus),
                recordedAt: Value(recording.recordedAt),
                createdAt: Value(recording.createdAt),
                retryCount: Value(recording.retryCount),
                resumableSessionUri: Value(recording.resumableSessionUri),
                uploadedBytes: Value(recording.uploadedBytes),
                splitFromId: Value(recording.splitFromId),
                splitIndex: Value(recording.splitIndex),
                splitSegmentCount: Value(recording.splitSegmentCount),
                reviewFlagsJson: Value(
                  encodeReviewFlags(recording.reviewFlags),
                ),
              ),
            );
      }
    });
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

  /// Defense in depth: throws [SegmentClassificationCollisionException] when a
  /// child's effective primary triple would be identical to the secondary
  /// triple it inherits from [parent]. Só o trio inteiro colide (ENG-72):
  /// mesmo gênero com subcategoria diferente é um par legítimo.
  /// The server enforces `secondary != primary` and would reject the upload
  /// with a 422; the UI is expected to block this case before reaching here.
  void _assertNoSecondaryCollision(
    LocalRecordingEntity parent,
    List<SplitSegmentSpec> segments,
  ) {
    for (final seg in segments) {
      if (secondaryEqualsPrimary(
        primaryRegisterId: _effective(seg.registerOverride, parent.registerId),
        primaryGenreId: _effective(seg.genreOverride, parent.genreId),
        primarySubcategoryId: _effective(
          seg.subcategoryOverride,
          parent.subcategoryId,
        ),
        secondaryRegisterId: parent.secondaryRegisterId,
        secondaryGenreId: parent.secondaryGenreId,
        secondarySubcategoryId: parent.secondarySubcategoryId,
      )) {
        throw SegmentClassificationCollisionException(seg.id);
      }
    }
  }

  static String? _effective(String? override, String? inherited) =>
      (override != null && override.isNotEmpty) ? override : inherited;

  /// Atomically replaces [parent] with its split children: inserts one child
  /// row per segment and deletes the parent row in a single transaction, so a
  /// partial failure can never leave orphaned children alongside a surviving
  /// parent. See ENG-125.
  Future<List<String>> splitRecordingReplacingParent({
    required LocalRecordingEntity parent,
    required List<SplitSegmentSpec> segments,
  }) async {
    _assertNoSecondaryCollision(parent, segments);
    return _db.transaction(() async {
      final ids = await _insertSplitChildren(parent, segments);
      await (_db.delete(
        _db.localRecordings,
      )..where((t) => t.id.equals(parent.id))).go();
      return ids;
    });
  }

  /// Inserts one child row per segment, propagating parent metadata per the
  /// contract in `docs/recording-split-semantics.md`. Runs in the caller's
  /// transaction; does not open its own.
  Future<List<String>> _insertSplitChildren(
    LocalRecordingEntity parent,
    List<SplitSegmentSpec> segments,
  ) async {
    final ids = <String>[];
    for (final seg in segments) {
      await _db
          .into(_db.localRecordings)
          .insert(
            LocalRecordingsCompanion(
              id: Value(seg.id),
              projectId: Value(parent.projectId),
              genreId: Value(
                (seg.genreOverride != null && seg.genreOverride!.isNotEmpty)
                    ? seg.genreOverride!
                    : parent.genreId,
              ),
              subcategoryId:
                  (seg.subcategoryOverride != null &&
                      seg.subcategoryOverride!.isNotEmpty)
                  ? Value(seg.subcategoryOverride)
                  : Value(parent.subcategoryId),
              registerId:
                  (seg.registerOverride != null &&
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
  }

  /// Spends one retry, and retires the row when that was the last one.
  ///
  /// The ceiling is decided here rather than by the caller because this is
  /// where the count is read: an attempt that failed before it could read the
  /// row would otherwise start counting from zero and leave the row at `failed`
  /// with a spent budget — queued by [getPendingUploads], refused by the drain,
  /// forever (ENG-377). `failed` therefore always means a retry is still
  /// coming, whatever threw and wherever.
  Future<bool> markAsFailed(String id) async {
    final recording = await getRecordingById(id);
    if (recording == null) return false;

    final spent = recording.retryCount + 1;
    final rows =
        await (_db.update(
          _db.localRecordings,
        )..where((t) => t.id.equals(id))).write(
          LocalRecordingsCompanion(
            uploadStatus: Value(
              spent >= kMaxUploadRetries ? 'failed_exhausted' : 'failed',
            ),
            retryCount: Value(spent),
            lastRetryAt: Value(DateTime.now()),
          ),
        );
    return rows > 0;
  }

  LocalRecordingEntity _fromRow(LocalRecording row) =>
      localRecordingToEntity(row);
}

/// Per-segment input for [LocalRecordingRepository.splitRecordingReplacingParent].
/// Fields that vary per child; the rest are inherited from the parent.
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
