import 'trim_edit_decision.dart';

const Duration kExcludeRangeReach = Duration(seconds: 5);

typedef ExcludeRangeDraft = ({double start, double end});

double snapToBoundary(
  double fraction,
  List<double> splitPoints,
  double minGap,
) {
  var snapped = fraction;
  var nearest = minGap;
  for (final boundary in [0.0, 1.0, ...splitPoints]) {
    final distance = (boundary - fraction).abs();
    if (distance <= nearest) {
      snapped = boundary;
      nearest = distance;
    }
  }
  return snapped;
}

ExcludeRangeDraft initialExcludeDraft({
  required Duration playhead,
  required Duration total,
  required List<double> splitPoints,
}) {
  final totalMs = total.inMilliseconds;
  final minGap = minSplitGapFraction(total);
  double edge(Duration at) => snapToBoundary(
    (at.inMilliseconds / totalMs).clamp(0.0, 1.0),
    splitPoints,
    minGap,
  );
  return (
    start: edge(playhead - kExcludeRangeReach),
    end: edge(playhead + kExcludeRangeReach),
  );
}
