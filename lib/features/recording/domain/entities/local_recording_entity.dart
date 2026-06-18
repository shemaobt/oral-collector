/// Domain view of a recording, decoupled from the Drift `LocalRecording` row.
///
/// Carries the operational fields the UI reads (upload status, byte counts,
/// local path) but not pure persistence internals (`lastRetryAt`, `md5Hash`).
/// Value equality is hand-written so a watch stream emitting this entity keeps
/// deduping under `.distinct()` (which compares by `==`). See ENG-195.
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
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalRecordingEntity &&
          other.id == id &&
          other.projectId == projectId &&
          other.genreId == genreId &&
          other.subcategoryId == subcategoryId &&
          other.title == title &&
          other.description == description &&
          other.durationSeconds == durationSeconds &&
          other.fileSizeBytes == fileSizeBytes &&
          other.format == format &&
          other.localFilePath == localFilePath &&
          other.uploadStatus == uploadStatus &&
          other.serverId == serverId &&
          other.gcsUrl == gcsUrl &&
          other.registerId == registerId &&
          other.secondaryGenreId == secondaryGenreId &&
          other.secondarySubcategoryId == secondarySubcategoryId &&
          other.secondaryRegisterId == secondaryRegisterId &&
          other.storytellerId == storytellerId &&
          other.userId == userId &&
          other.cleaningStatus == cleaningStatus &&
          other.recordedAt == recordedAt &&
          other.createdAt == createdAt &&
          other.retryCount == retryCount &&
          other.resumableSessionUri == resumableSessionUri &&
          other.uploadedBytes == uploadedBytes &&
          other.splitFromId == splitFromId &&
          other.splitIndex == splitIndex &&
          other.splitSegmentCount == splitSegmentCount);

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
  ]);
}
