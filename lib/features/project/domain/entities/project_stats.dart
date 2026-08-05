import '../../../../core/serialization/safe_read.dart';

/// Aggregate counters for a project, from GET /api/oc/projects/{id}/stats.
/// Fields are nullable so callers can fall back to a project's own counts when
/// a field is absent.
class ProjectStats {
  final int? totalRecordings;
  final double? totalDurationSeconds;
  final int? totalStorytellers;

  /// How many recordings carry each review flag code (ENG-374). A code nobody
  /// carries is absent rather than present with a zero.
  ///
  /// **These do not sum to [recordingsWithReviewFlags].** A recording with
  /// three open fields adds one to each of three codes but only one to the
  /// distinct count, so summing this to answer "how many recordings need
  /// attention" over-reports — by a plausible amount, which is the worst kind.
  final Map<String, int> reviewFlagCounts;

  /// How many distinct recordings carry at least one review flag. This is the
  /// number to show when the question is about recordings rather than fields.
  final int? recordingsWithReviewFlags;

  const ProjectStats({
    this.totalRecordings,
    this.totalDurationSeconds,
    this.totalStorytellers,
    this.reviewFlagCounts = const {},
    this.recordingsWithReviewFlags,
  });

  factory ProjectStats.fromJson(Map<String, dynamic> json) {
    return ProjectStats(
      totalRecordings: readIntOrNull(json, 'total_recordings'),
      totalDurationSeconds: readDoubleOrNull(json, 'total_duration_seconds'),
      totalStorytellers: readIntOrNull(json, 'total_storytellers'),
      reviewFlagCounts: _readFlagCounts(json),
      recordingsWithReviewFlags: _readCounter(
        json,
        'recordings_with_review_flags',
      ),
    );
  }

  /// **Both review counters are read tolerantly, and deliberately so.** They
  /// shipped after the rest of this endpoint, so absent reads as nothing, and a
  /// value of the wrong type is dropped like a malformed map entry rather than
  /// thrown on. The safe-readers' rule — a present value of the wrong type is a
  /// contract violation worth failing the parse for — is the right default and
  /// the wrong call here: these two feed one counter on a screen whose fetch is
  /// already best-effort, so losing a counter makes a poorer screen while
  /// throwing makes a broken one. Applying one rule to only one of the two
  /// would have made the map's tolerance pointless: whichever field the server
  /// got wrong, the reader would still lose the payload.
  static int? _readCounter(Map<String, dynamic> json, String key) {
    final value = json[key];
    // isFinite guards toInt(), which raises an uncatchable error on NaN.
    return value is num && value.isFinite ? value.toInt() : null;
  }

  /// See [_readCounter] for why an entry whose value is not a number is dropped
  /// on its own instead of failing the parse.
  static Map<String, int> _readFlagCounts(Map<String, dynamic> json) {
    final raw = json['review_flag_counts'];
    if (raw is! Map) return const {};
    final counts = <String, int>{};
    raw.forEach((key, value) {
      if (key is String && value is num) counts[key] = value.toInt();
    });
    return Map.unmodifiable(counts);
  }
}
