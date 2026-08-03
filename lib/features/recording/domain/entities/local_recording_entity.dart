/// Domain view of a recording, decoupled from the Drift `LocalRecording` row.
///
/// Carries the operational fields the UI reads (upload status, byte counts,
/// local path) but not pure persistence internals (`lastRetryAt`, `md5Hash`).
/// Value equality is hand-written so a watch stream emitting this entity keeps
/// deduping under `.distinct()` (which compares by `==`). See ENG-195.
library;

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
  });

  static const Object _sentinel = Object();

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
  }) {
    return LocalRecordingEntity(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      genreId: genreId ?? this.genreId,
      subcategoryId: identical(subcategoryId, _sentinel)
          ? this.subcategoryId
          : subcategoryId as String?,
      title: identical(title, _sentinel) ? this.title : title as String?,
      description: identical(description, _sentinel)
          ? this.description
          : description as String?,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      format: format ?? this.format,
      localFilePath: localFilePath ?? this.localFilePath,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      serverId: identical(serverId, _sentinel)
          ? this.serverId
          : serverId as String?,
      gcsUrl: identical(gcsUrl, _sentinel) ? this.gcsUrl : gcsUrl as String?,
      registerId: identical(registerId, _sentinel)
          ? this.registerId
          : registerId as String?,
      secondaryGenreId: identical(secondaryGenreId, _sentinel)
          ? this.secondaryGenreId
          : secondaryGenreId as String?,
      secondarySubcategoryId: identical(secondarySubcategoryId, _sentinel)
          ? this.secondarySubcategoryId
          : secondarySubcategoryId as String?,
      secondaryRegisterId: identical(secondaryRegisterId, _sentinel)
          ? this.secondaryRegisterId
          : secondaryRegisterId as String?,
      storytellerId: identical(storytellerId, _sentinel)
          ? this.storytellerId
          : storytellerId as String?,
      userId: identical(userId, _sentinel) ? this.userId : userId as String?,
      cleaningStatus: cleaningStatus ?? this.cleaningStatus,
      recordedAt: recordedAt ?? this.recordedAt,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      resumableSessionUri: identical(resumableSessionUri, _sentinel)
          ? this.resumableSessionUri
          : resumableSessionUri as String?,
      uploadedBytes: uploadedBytes ?? this.uploadedBytes,
      splitFromId: identical(splitFromId, _sentinel)
          ? this.splitFromId
          : splitFromId as String?,
      splitIndex: identical(splitIndex, _sentinel)
          ? this.splitIndex
          : splitIndex as int?,
      splitSegmentCount: identical(splitSegmentCount, _sentinel)
          ? this.splitSegmentCount
          : splitSegmentCount as int?,
      reviewFlags: reviewFlags ?? this.reviewFlags,
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
  ]);
}
