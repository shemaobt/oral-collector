enum TrimSaveMode { boostOnly, split }

class TrimSegment {
  const TrimSegment({
    required this.startSeconds,
    required this.endSeconds,
    required this.gainDb,
  });

  final double startSeconds;
  final double endSeconds;
  final double gainDb;
}

class TrimEditDecision {
  const TrimEditDecision({
    required this.splitPoints,
    required this.excludedSegments,
    required this.gainDb,
    required this.totalDuration,
  });

  final List<double> splitPoints;
  final Set<int> excludedSegments;
  final double gainDb;
  final Duration totalDuration;

  static const double _gainDeadzoneDb = 0.01;
  static const int _minDurationMs = 200;

  bool get hasSplits => splitPoints.isNotEmpty;
  bool get hasGainChange => gainDb.abs() > _gainDeadzoneDb;
  bool get hasEdits => hasSplits || hasGainChange;
  bool get isAudioLongEnough => totalDuration.inMilliseconds > _minDurationMs;

  int get segmentCount => splitPoints.length + 1;
  int get keptCount => segmentCount - excludedSegments.length;

  TrimSaveMode get mode =>
      hasSplits ? TrimSaveMode.split : TrimSaveMode.boostOnly;

  bool get canSave {
    if (!isAudioLongEnough) return false;
    if (!hasEdits) return false;
    if (hasSplits && keptCount == 0) return false;
    return true;
  }

  List<TrimSegment> get segments {
    final sortedSplits = [...splitPoints]..sort();
    final boundaries = [0.0, ...sortedSplits, 1.0];
    final totalMs = totalDuration.inMilliseconds;
    final out = <TrimSegment>[];
    for (var i = 0; i < segmentCount; i++) {
      if (excludedSegments.contains(i)) continue;
      out.add(
        TrimSegment(
          startSeconds: (boundaries[i] * totalMs).round() / 1000.0,
          endSeconds: (boundaries[i + 1] * totalMs).round() / 1000.0,
          gainDb: gainDb,
        ),
      );
    }
    return out;
  }
}
