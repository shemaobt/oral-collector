import '../../../../core/serialization/safe_read.dart';

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
      totalProjects: readIntOrNull(json, 'total_projects') ?? 0,
      totalLanguages: readIntOrNull(json, 'total_languages') ?? 0,
      totalRecordings: readIntOrNull(json, 'total_recordings') ?? 0,
      totalDurationSeconds:
          readDoubleOrNull(json, 'total_duration_seconds') ?? 0,
      activeUsers: readIntOrNull(json, 'active_users') ?? 0,
    );
  }

  double get totalHours => totalDurationSeconds / 3600;
}
