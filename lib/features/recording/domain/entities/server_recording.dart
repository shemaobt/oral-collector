import '../../../../core/serialization/parse_list.dart';
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

  /// A server that predates ENG-373 omits the key, and a serializer may send it
  /// as null; neither is a broken payload, so both read as "owes nothing".
  ///
  /// A value that is not a list at all reads the same way. [parseList] would
  /// throw for that shape, and the throw would escape `fromJson` and cost the
  /// caller the entire recording — dropped from the list, or a failed detail
  /// load. The flags are advisory, so losing them must never cost the user the
  /// recording they describe. Malformed *elements* are still dropped
  /// individually by [parseList], which is the same policy one level down.
  ///
  /// No `onSkip` reporter is passed here (ENG-166): this runs inside a
  /// `fromJson` factory that is itself handed to an outer `parseList` as a
  /// tear-off, so no reporter can reach it without changing the factory's
  /// signature. Deliberate, not forgotten.
  static List<ReviewFlag> _readReviewFlags(Map<String, dynamic> json) {
    final raw = json['review_flags'];
    if (raw is! List) return const [];
    return List.unmodifiable(
      parseList(
        raw,
        ReviewFlag.fromJson,
        context: 'ServerRecording.reviewFlags',
      ),
    );
  }

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
