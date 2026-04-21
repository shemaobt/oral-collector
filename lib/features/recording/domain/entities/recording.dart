class Recording {
  final String id;
  final String projectId;
  final String genreId;
  final String subcategoryId;
  final String? registerId;
  final String? secondaryGenreId;
  final String? secondarySubcategoryId;
  final String? secondaryRegisterId;
  final String userId;
  final String? title;
  final double durationSeconds;
  final int fileSizeBytes;
  final String format;
  final String? gcsUrl;
  final String uploadStatus;
  final String cleaningStatus;
  final DateTime recordedAt;
  final DateTime? createdAt;
  final String? splitFromId;
  final int? splitIndex;
  final int? splitSegmentCount;

  const Recording({
    required this.id,
    required this.projectId,
    required this.genreId,
    required this.subcategoryId,
    this.registerId,
    this.secondaryGenreId,
    this.secondarySubcategoryId,
    this.secondaryRegisterId,
    required this.userId,
    this.title,
    required this.durationSeconds,
    required this.fileSizeBytes,
    required this.format,
    this.gcsUrl,
    required this.uploadStatus,
    required this.cleaningStatus,
    required this.recordedAt,
    this.createdAt,
    this.splitFromId,
    this.splitIndex,
    this.splitSegmentCount,
  });

  factory Recording.fromJson(Map<String, dynamic> json) {
    return Recording(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      genreId: json['genre_id'] as String,
      subcategoryId: json['subcategory_id'] as String,
      registerId: json['register_id'] as String?,
      secondaryGenreId: json['secondary_genre_id'] as String?,
      secondarySubcategoryId: json['secondary_subcategory_id'] as String?,
      secondaryRegisterId: json['secondary_register_id'] as String?,
      userId: json['user_id'] as String,
      title: json['title'] as String?,
      durationSeconds: (json['duration_seconds'] as num).toDouble(),
      fileSizeBytes: (json['file_size_bytes'] as num).toInt(),
      format: json['format'] as String,
      gcsUrl: json['gcs_url'] as String?,
      uploadStatus: json['upload_status'] as String,
      cleaningStatus: json['cleaning_status'] as String,
      recordedAt: DateTime.parse(json['recorded_at'] as String),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      splitFromId: json['split_from_id'] as String?,
      splitIndex: (json['split_index'] as num?)?.toInt(),
      splitSegmentCount: (json['split_segment_count'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project_id': projectId,
      'genre_id': genreId,
      'subcategory_id': subcategoryId,
      'register_id': registerId,
      'secondary_genre_id': secondaryGenreId,
      'secondary_subcategory_id': secondarySubcategoryId,
      'secondary_register_id': secondaryRegisterId,
      'user_id': userId,
      'title': title,
      'duration_seconds': durationSeconds,
      'file_size_bytes': fileSizeBytes,
      'format': format,
      'gcs_url': gcsUrl,
      'upload_status': uploadStatus,
      'cleaning_status': cleaningStatus,
      'recorded_at': recordedAt.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'split_from_id': splitFromId,
      'split_index': splitIndex,
      'split_segment_count': splitSegmentCount,
    };
  }
}

class LocalRecording {
  final String id;
  final String projectId;
  final String genreId;
  final String subcategoryId;
  final String? registerId;
  final String? secondaryGenreId;
  final String? secondarySubcategoryId;
  final String? secondaryRegisterId;
  final String? title;
  final double durationSeconds;
  final int fileSizeBytes;
  final String format;
  final String localFilePath;
  final String uploadStatus;
  final String? serverId;
  final String? gcsUrl;
  final String cleaningStatus;
  final DateTime recordedAt;
  final DateTime? createdAt;
  final int retryCount;
  final DateTime? lastRetryAt;
  final String? splitFromId;
  final int? splitIndex;
  final int? splitSegmentCount;

  const LocalRecording({
    required this.id,
    required this.projectId,
    required this.genreId,
    required this.subcategoryId,
    this.registerId,
    this.secondaryGenreId,
    this.secondarySubcategoryId,
    this.secondaryRegisterId,
    this.title,
    required this.durationSeconds,
    required this.fileSizeBytes,
    required this.format,
    required this.localFilePath,
    required this.uploadStatus,
    this.serverId,
    this.gcsUrl,
    required this.cleaningStatus,
    required this.recordedAt,
    this.createdAt,
    this.retryCount = 0,
    this.lastRetryAt,
    this.splitFromId,
    this.splitIndex,
    this.splitSegmentCount,
  });

  factory LocalRecording.fromJson(Map<String, dynamic> json) {
    return LocalRecording(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      genreId: json['genre_id'] as String,
      subcategoryId: json['subcategory_id'] as String,
      registerId: json['register_id'] as String?,
      secondaryGenreId: json['secondary_genre_id'] as String?,
      secondarySubcategoryId: json['secondary_subcategory_id'] as String?,
      secondaryRegisterId: json['secondary_register_id'] as String?,
      title: json['title'] as String?,
      durationSeconds: (json['duration_seconds'] as num).toDouble(),
      fileSizeBytes: (json['file_size_bytes'] as num).toInt(),
      format: json['format'] as String,
      localFilePath: json['local_file_path'] as String,
      uploadStatus: json['upload_status'] as String,
      serverId: json['server_id'] as String?,
      gcsUrl: json['gcs_url'] as String?,
      cleaningStatus: json['cleaning_status'] as String,
      recordedAt: DateTime.parse(json['recorded_at'] as String),
      retryCount: (json['retry_count'] as num?)?.toInt() ?? 0,
      lastRetryAt: json['last_retry_at'] != null
          ? DateTime.parse(json['last_retry_at'] as String)
          : null,
      splitFromId: json['split_from_id'] as String?,
      splitIndex: (json['split_index'] as num?)?.toInt(),
      splitSegmentCount: (json['split_segment_count'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project_id': projectId,
      'genre_id': genreId,
      'subcategory_id': subcategoryId,
      'register_id': registerId,
      'secondary_genre_id': secondaryGenreId,
      'secondary_subcategory_id': secondarySubcategoryId,
      'secondary_register_id': secondaryRegisterId,
      'title': title,
      'duration_seconds': durationSeconds,
      'file_size_bytes': fileSizeBytes,
      'format': format,
      'local_file_path': localFilePath,
      'upload_status': uploadStatus,
      'server_id': serverId,
      'gcs_url': gcsUrl,
      'cleaning_status': cleaningStatus,
      'recorded_at': recordedAt.toIso8601String(),
      'retry_count': retryCount,
      'last_retry_at': lastRetryAt?.toIso8601String(),
      'split_from_id': splitFromId,
      'split_index': splitIndex,
      'split_segment_count': splitSegmentCount,
    };
  }
}
