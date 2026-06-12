import '../../../../core/serialization/safe_read.dart';

/// Aggregate counters for a project, from GET /api/oc/projects/{id}/stats.
/// Fields are nullable so callers can fall back to a project's own counts when
/// a field is absent.
class ProjectStats {
  final int? totalRecordings;
  final double? totalDurationSeconds;
  final int? totalStorytellers;

  const ProjectStats({
    this.totalRecordings,
    this.totalDurationSeconds,
    this.totalStorytellers,
  });

  factory ProjectStats.fromJson(Map<String, dynamic> json) {
    return ProjectStats(
      totalRecordings: readIntOrNull(json, 'total_recordings'),
      totalDurationSeconds: readDoubleOrNull(json, 'total_duration_seconds'),
      totalStorytellers: readIntOrNull(json, 'total_storytellers'),
    );
  }
}
