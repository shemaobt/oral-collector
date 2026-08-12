/// The shortest segment the trim editor lets you create or drag to (ENG-66).
/// Expressed in time rather than as a fraction of the file, so the floor stops
/// growing with the recording: the old 3% fraction meant ~1 s on a 33 s file and
/// ~5.4 s on a 3-minute one.
const Duration kMinTrimSegment = Duration(milliseconds: 250);

/// [kMinTrimSegment] as a fraction of [totalDuration], for the fraction-space
/// gesture maths. Split points are `double`s in `[0, 1]`, so every caller that
/// enforces the floor needs it in that space.
///
/// A recording shorter than twice the floor yields a gap of 0.5 or more, which
/// leaves no legal cut on either gesture path — refusing to split such a file is
/// the honest answer, and is why this is deliberately not capped. An unknown
/// duration refuses for the same reason: there is no time basis to convert from,
/// and guessing a fraction would silently pick a floor unrelated to 250 ms.
double minSplitGapFraction(Duration totalDuration) {
  final totalMs = totalDuration.inMilliseconds;
  if (totalMs <= 0) return 0.5;
  return kMinTrimSegment.inMilliseconds / totalMs;
}

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
