class AdminStats {
  final int totalProjects;
  final int totalLanguages;
  final int totalRecordings;
  final double totalDurationSeconds;
  final int activeUsers;

  const AdminStats({
    this.totalProjects = 0,
    this.totalLanguages = 0,
    this.totalRecordings = 0,
    this.totalDurationSeconds = 0,
    this.activeUsers = 0,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      totalProjects: (json['total_projects'] as num?)?.toInt() ?? 0,
      totalLanguages: (json['total_languages'] as num?)?.toInt() ?? 0,
      totalRecordings: (json['total_recordings'] as num?)?.toInt() ?? 0,
      totalDurationSeconds:
          (json['total_duration_seconds'] as num?)?.toDouble() ?? 0,
      activeUsers: (json['active_users'] as num?)?.toInt() ?? 0,
    );
  }

  double get totalHours => totalDurationSeconds / 3600;
}
