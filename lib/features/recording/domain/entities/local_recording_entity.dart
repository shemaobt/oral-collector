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
