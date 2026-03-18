class ServerRecording {
  final String id;
  final String projectId;
  final String genreId;
  final String? subcategoryId;
  final String? registerId;
  final String? title;
  final double durationSeconds;
  final int fileSizeBytes;
  final String format;
  final String? gcsUrl;
  final String uploadStatus;
  final String cleaningStatus;
  final DateTime recordedAt;
  final DateTime? uploadedAt;

  const ServerRecording({
    required this.id,
    required this.projectId,
    required this.genreId,
    this.subcategoryId,
    this.registerId,
    this.title,
    required this.durationSeconds,
    required this.fileSizeBytes,
    required this.format,
    this.gcsUrl,
    required this.uploadStatus,
    required this.cleaningStatus,
    required this.recordedAt,
    this.uploadedAt,
  });

  factory ServerRecording.fromJson(Map<String, dynamic> json) {
    return ServerRecording(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      genreId: json['genre_id'] as String,
      subcategoryId: json['subcategory_id'] as String?,
      registerId: json['register_id'] as String?,
      title: json['title'] as String?,
      durationSeconds: (json['duration_seconds'] as num).toDouble(),
      fileSizeBytes: json['file_size_bytes'] as int,
      format: json['format'] as String,
      gcsUrl: json['gcs_url'] as String?,
      uploadStatus: json['upload_status'] as String,
      cleaningStatus: json['cleaning_status'] as String,
      recordedAt: DateTime.parse(json['recorded_at'] as String),
      uploadedAt: json['uploaded_at'] != null
          ? DateTime.parse(json['uploaded_at'] as String)
          : null,
    );
  }
}
