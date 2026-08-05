import '../../../../core/serialization/safe_read.dart';
import 'review_flag.dart';

class ServerRecording {
  final String id;
  final String projectId;
  final String genreId;
  final String? subcategoryId;
  final String? registerId;
  final String? secondaryGenreId;
  final String? secondarySubcategoryId;
  final String? secondaryRegisterId;
  final String? storytellerId;
  final String? userId;
  final String? title;
  final String? description;
  final double durationSeconds;
  final int fileSizeBytes;
  final String format;
  final String? gcsUrl;
  final String uploadStatus;
  final String cleaningStatus;
  final DateTime recordedAt;
  final DateTime? uploadedAt;
  final String? splitFromId;
  final int? splitIndex;
  final int? splitSegmentCount;
  final List<ReviewFlag> reviewFlags;

  const ServerRecording({
    required this.id,
    required this.projectId,
    required this.genreId,
    this.subcategoryId,
    this.registerId,
    this.secondaryGenreId,
    this.secondarySubcategoryId,
    this.secondaryRegisterId,
    this.storytellerId,
    this.userId,
    this.title,
    this.description,
    required this.durationSeconds,
    required this.fileSizeBytes,
    required this.format,
    this.gcsUrl,
    required this.uploadStatus,
    required this.cleaningStatus,
    required this.recordedAt,
    this.uploadedAt,
    this.splitFromId,
    this.splitIndex,
    this.splitSegmentCount,
    this.reviewFlags = const [],
  });

  /// A server that predates ENG-373 omits the key, a serializer may send it as
  /// null, and a broken payload may send something that is not a list; none of
  /// those is worth losing the recording over, so all three read as "owes
  /// nothing" here. The caller of a *write* endpoint needs to tell absent from
  /// empty — it stores what came back — and uses [readReviewFlagsOrNull]
  /// directly for that (ENG-379).
  ///
  /// No `onSkip` reporter reaches this (ENG-166): it runs inside a `fromJson`
  /// factory that is itself handed to an outer `parseList` as a tear-off, so no
  /// reporter can get here without changing the factory's signature.
  /// Deliberate, not forgotten.
  static List<ReviewFlag> _readReviewFlags(Map<String, dynamic> json) =>
      readReviewFlagsOrNull(json) ?? const [];

  factory ServerRecording.fromJson(Map<String, dynamic> json) {
    return ServerRecording(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      genreId: json['genre_id'] as String,
      subcategoryId: json['subcategory_id'] as String?,
      registerId: json['register_id'] as String?,
      secondaryGenreId: json['secondary_genre_id'] as String?,
      secondarySubcategoryId: json['secondary_subcategory_id'] as String?,
      secondaryRegisterId: json['secondary_register_id'] as String?,
      storytellerId: json['storyteller_id'] as String?,
      userId: json['user_id'] as String?,
      title: json['title'] as String?,
      description: json['description'] as String?,
      durationSeconds: (json['duration_seconds'] as num).toDouble(),
      fileSizeBytes: readInt(json, 'file_size_bytes'),
      format: json['format'] as String,
      gcsUrl: json['gcs_url'] as String?,
      uploadStatus: readString(json, 'upload_status'),
      cleaningStatus: readString(json, 'cleaning_status'),
      recordedAt: readDate(json, 'recorded_at'),
      uploadedAt: readDateOrNull(json, 'uploaded_at'),
      splitFromId: json['split_from_id'] as String?,
      splitIndex: (json['split_index'] as num?)?.toInt(),
      splitSegmentCount: (json['split_segment_count'] as num?)?.toInt(),
      reviewFlags: _readReviewFlags(json),
    );
  }
}
