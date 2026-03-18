class Recording {
  final String id;
  final String projectId;
  final String genreId;
  final String subcategoryId;
  final String? registerId;
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

  const Recording({
    required this.id,
    required this.projectId,
    required this.genreId,
    required this.subcategoryId,
    this.registerId,
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
  });

  factory Recording.fromJson(Map<String, dynamic> json) {
    return Recording(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      genreId: json['genre_id'] as String,
      subcategoryId: json['subcategory_id'] as String,
      registerId: json['register_id'] as String?,
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project_id': projectId,
      'genre_id': genreId,
      'subcategory_id': subcategoryId,
      'register_id': registerId,
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
    };
  }
}

class LocalRecording {
  final String id;
  final String projectId;
  final String genreId;
  final String subcategoryId;
  final String? registerId;
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

  const LocalRecording({
    required this.id,
    required this.projectId,
    required this.genreId,
    required this.subcategoryId,
    this.registerId,
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
  });

  factory LocalRecording.fromJson(Map<String, dynamic> json) {
    return LocalRecording(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      genreId: json['genre_id'] as String,
      subcategoryId: json['subcategory_id'] as String,
      registerId: json['register_id'] as String?,
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project_id': projectId,
      'genre_id': genreId,
      'subcategory_id': subcategoryId,
      'register_id': registerId,
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
    };
  }
}
