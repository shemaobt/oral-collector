/// Domain view of a recording, decoupled from the Drift `LocalRecording` row.
///
/// Carries the operational fields the UI reads (upload status, byte counts,
/// local path) but not pure persistence internals (`lastRetryAt`, `md5Hash`).
/// Value equality is hand-written so a watch stream emitting this entity keeps
/// deduping under `.distinct()` (which compares by `==`). See ENG-195.
library;

import 'pending_metadata_field.dart';
import 'review_flag.dart';

class LocalRecordingEntity {
  final String id;
  final String projectId;
  final String genreId;
  final String? subcategoryId;
  final String? title;
  final String? description;
  final double durationSeconds;
  final int fileSizeBytes;
  final String format;

  /// Empty string is the sentinel for "not on this device"; callers check
  /// `localFilePath.isEmpty` before touching the file.
  final String localFilePath;
  final String uploadStatus;
  final String? serverId;
  final String? gcsUrl;
  final String? registerId;
  final String? secondaryGenreId;
  final String? secondarySubcategoryId;
  final String? secondaryRegisterId;
  final String? storytellerId;
  final String? userId;
  final String cleaningStatus;
  final DateTime recordedAt;
  final DateTime createdAt;
  final int retryCount;
  final String? resumableSessionUri;
  final int uploadedBytes;
  final String? splitFromId;
  final int? splitIndex;
  final int? splitSegmentCount;

  /// What the server says this recording still owes. Empty is the normal state
  /// and the default, so a recording that predates the field — or one this
  /// device made and has not uploaded — is not mistaken for one under review.
  final List<ReviewFlag> reviewFlags;

  /// Where this recording stands with the metadata outbox (ENG-403), one of
  /// [MetadataSyncStatus]. Carried on the entity because the list and the card
  /// read the entity, not the row, and they are what tells the user an edit is
  /// still waiting to go up.
  final String metadataSyncStatus;

  /// Which fields are waiting to go up. Kept alongside the status rather than
  /// derived from it because a retired row keeps owing them — the screen needs
  /// to say *what* is stuck, not only that something is.
  final Set<PendingMetadataField> pendingMetadataFields;

  bool get hasPendingMetadata => pendingMetadataFields.isNotEmpty;

  const LocalRecordingEntity({
    required this.id,
    required this.projectId,
    required this.genreId,
    this.subcategoryId,
    this.title,
    this.description,
    required this.durationSeconds,
    required this.fileSizeBytes,
    required this.format,
    required this.localFilePath,
    required this.uploadStatus,
    this.serverId,
    this.gcsUrl,
    this.registerId,
    this.secondaryGenreId,
    this.secondarySubcategoryId,
    this.secondaryRegisterId,
    this.storytellerId,
    this.userId,
    required this.cleaningStatus,
    required this.recordedAt,
    required this.createdAt,
    required this.retryCount,
    this.resumableSessionUri,
    required this.uploadedBytes,
    this.splitFromId,
    this.splitIndex,
    this.splitSegmentCount,
    this.reviewFlags = const [],
    this.metadataSyncStatus = MetadataSyncStatus.synced,
    this.pendingMetadataFields = const {},
  });

  static const Object _sentinel = Object();

  /// Resolves one sentinel-defaulted [copyWith] argument: [_sentinel] means the
  /// caller omitted it, so [current] stands; anything else — `null` included —
  /// is the new value.
  static T? _orKeep<T>(Object? incoming, T? current) =>
      identical(incoming, _sentinel) ? current : incoming as T?;

  /// Passing `null` to a nullable field clears it; omitting a field preserves
  /// the current value. The [_sentinel] default is what distinguishes "clear"
  /// from "leave unchanged" — a plain `value ?? this.value` could not.
  LocalRecordingEntity copyWith({
    String? id,
    String? projectId,
    String? genreId,
    Object? subcategoryId = _sentinel,
    Object? title = _sentinel,
    Object? description = _sentinel,
    double? durationSeconds,
    int? fileSizeBytes,
    String? format,
    String? localFilePath,
    String? uploadStatus,
    Object? serverId = _sentinel,
    Object? gcsUrl = _sentinel,
    Object? registerId = _sentinel,
    Object? secondaryGenreId = _sentinel,
    Object? secondarySubcategoryId = _sentinel,
    Object? secondaryRegisterId = _sentinel,
    Object? storytellerId = _sentinel,
    Object? userId = _sentinel,
    String? cleaningStatus,
    DateTime? recordedAt,
    DateTime? createdAt,
    int? retryCount,
    Object? resumableSessionUri = _sentinel,
    int? uploadedBytes,
    Object? splitFromId = _sentinel,
    Object? splitIndex = _sentinel,
    Object? splitSegmentCount = _sentinel,
    List<ReviewFlag>? reviewFlags,
    String? metadataSyncStatus,
    Set<PendingMetadataField>? pendingMetadataFields,
  }) {
    return LocalRecordingEntity(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      genreId: genreId ?? this.genreId,
      subcategoryId: _orKeep(subcategoryId, this.subcategoryId),
      title: _orKeep(title, this.title),
      description: _orKeep(description, this.description),
      durationSeconds: durationSeconds ?? this.durationSeconds,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      format: format ?? this.format,
      localFilePath: localFilePath ?? this.localFilePath,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      serverId: _orKeep(serverId, this.serverId),
      gcsUrl: _orKeep(gcsUrl, this.gcsUrl),
      registerId: _orKeep(registerId, this.registerId),
      secondaryGenreId: _orKeep(secondaryGenreId, this.secondaryGenreId),
      secondarySubcategoryId: _orKeep(
        secondarySubcategoryId,
        this.secondarySubcategoryId,
      ),
      secondaryRegisterId: _orKeep(
        secondaryRegisterId,
        this.secondaryRegisterId,
      ),
      storytellerId: _orKeep(storytellerId, this.storytellerId),
      userId: _orKeep(userId, this.userId),
      cleaningStatus: cleaningStatus ?? this.cleaningStatus,
      recordedAt: recordedAt ?? this.recordedAt,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      resumableSessionUri: _orKeep(
        resumableSessionUri,
        this.resumableSessionUri,
      ),
      uploadedBytes: uploadedBytes ?? this.uploadedBytes,
      splitFromId: _orKeep(splitFromId, this.splitFromId),
      splitIndex: _orKeep(splitIndex, this.splitIndex),
      splitSegmentCount: _orKeep(splitSegmentCount, this.splitSegmentCount),
      reviewFlags: reviewFlags ?? this.reviewFlags,
      metadataSyncStatus: metadataSyncStatus ?? this.metadataSyncStatus,
      pendingMetadataFields:
          pendingMetadataFields ?? this.pendingMetadataFields,
    );
  }

  /// Split into groups only to keep the comparison under the cyclomatic
  /// complexity gate; every field still participates, and the grouping is by
  /// what the fields describe rather than by any difference in treatment.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalRecordingEntity &&
          _sameSubject(other) &&
          _sameClassification(other) &&
          _sameAudio(other) &&
          _sameUpload(other) &&
          _sameSplit(other) &&
          _sameOutbox(other) &&
          _sameFlags(other.reviewFlags, reviewFlags));

  bool _sameSubject(LocalRecordingEntity other) =>
      other.id == id &&
      other.projectId == projectId &&
      other.title == title &&
      other.description == description &&
      other.storytellerId == storytellerId &&
      other.userId == userId;

  bool _sameClassification(LocalRecordingEntity other) =>
      other.genreId == genreId &&
      other.subcategoryId == subcategoryId &&
      other.registerId == registerId &&
      other.secondaryGenreId == secondaryGenreId &&
      other.secondarySubcategoryId == secondarySubcategoryId &&
      other.secondaryRegisterId == secondaryRegisterId;

  bool _sameAudio(LocalRecordingEntity other) =>
      other.durationSeconds == durationSeconds &&
      other.fileSizeBytes == fileSizeBytes &&
      other.format == format &&
      other.localFilePath == localFilePath &&
      other.recordedAt == recordedAt &&
      other.createdAt == createdAt;

  bool _sameUpload(LocalRecordingEntity other) =>
      other.uploadStatus == uploadStatus &&
      other.serverId == serverId &&
      other.gcsUrl == gcsUrl &&
      other.cleaningStatus == cleaningStatus &&
      other.retryCount == retryCount &&
      other.resumableSessionUri == resumableSessionUri &&
      other.uploadedBytes == uploadedBytes;

  bool _sameSplit(LocalRecordingEntity other) =>
      other.splitFromId == splitFromId &&
      other.splitIndex == splitIndex &&
      other.splitSegmentCount == splitSegmentCount;

  /// A `Set` compares by identity too, so the owed fields need the same
  /// treatment as the flags below — otherwise the watch stream's `.distinct()`
  /// stops deduping the moment a recording owes anything.
  bool _sameOutbox(LocalRecordingEntity other) =>
      other.metadataSyncStatus == metadataSyncStatus &&
      other.pendingMetadataFields.length == pendingMetadataFields.length &&
      other.pendingMetadataFields.containsAll(pendingMetadataFields);

  /// A `List` compares by identity, so the flags need an element-wise check or
  /// two structurally identical entities would read as different and the watch
  /// stream's `.distinct()` would rebuild the screen on every emission.
  ///
  /// The comparison is order-sensitive, which relies on the server emitting the
  /// flags in a stable order — it does, by contract (ENG-373 fixes the order so
  /// its own backfill can compare lists). If that ever stops holding, this
  /// stops deduping rather than reporting anything wrong.
  static bool _sameFlags(List<ReviewFlag> a, List<ReviewFlag> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    projectId,
    genreId,
    subcategoryId,
    title,
    description,
    durationSeconds,
    fileSizeBytes,
    format,
    localFilePath,
    uploadStatus,
    serverId,
    gcsUrl,
    registerId,
    secondaryGenreId,
    secondarySubcategoryId,
    secondaryRegisterId,
    storytellerId,
    userId,
    cleaningStatus,
    recordedAt,
    createdAt,
    retryCount,
    resumableSessionUri,
    uploadedBytes,
    splitFromId,
    splitIndex,
    splitSegmentCount,
    Object.hashAll(reviewFlags),
    metadataSyncStatus,
    Object.hashAllUnordered(pendingMetadataFields),
  ]);
}
