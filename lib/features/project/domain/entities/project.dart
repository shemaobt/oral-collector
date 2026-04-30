class Project {
  final String id;
  final String name;
  final String languageId;
  final String? languageName;
  final String? languageCode;
  final String? description;
  final int memberCount;
  final int recordingCount;
  final double totalDurationSeconds;
  final int storytellerCount;
  final DateTime? createdAt;

  const Project({
    required this.id,
    required this.name,
    required this.languageId,
    this.languageName,
    this.languageCode,
    this.description,
    this.memberCount = 0,
    this.recordingCount = 0,
    this.totalDurationSeconds = 0,
    this.storytellerCount = 0,
    this.createdAt,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      name: json['name'] as String,
      languageId: json['language_id'] as String,
      languageName: json['language_name'] as String?,
      languageCode: json['language_code'] as String?,
      description: json['description'] as String?,
      memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
      recordingCount: (json['recording_count'] as num?)?.toInt() ?? 0,
      totalDurationSeconds:
          (json['total_duration_seconds'] as num?)?.toDouble() ?? 0,
      storytellerCount: (json['storyteller_count'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'language_id': languageId,
      'language_name': languageName,
      'language_code': languageCode,
      'description': description,
      'member_count': memberCount,
      'recording_count': recordingCount,
      'total_duration_seconds': totalDurationSeconds,
      'storyteller_count': storytellerCount,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
