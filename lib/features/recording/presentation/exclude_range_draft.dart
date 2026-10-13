import 'excluded_range.dart';
import 'trim_edit_decision.dart';

const Duration kExcludeRangeReach = Duration(seconds: 5);

typedef ExcludeRangeDraft = ({double start, double end});

List<double> boundaryPointsOf(
  List<double> splitPoints,
  List<ExcludedRange> ranges,
) => [
  ...splitPoints,
  for (final r in ranges) ...[r.startFraction, r.endFraction],
];

double snapToBoundary(
  double fraction,
  List<double> boundaryPoints,
  double minGap,
) {
  var snapped = fraction;
  var nearest = minGap;
  for (final boundary in [0.0, 1.0, ...boundaryPoints]) {
    final distance = (boundary - fraction).abs();
    if (distance < nearest - 1e-9) {
      snapped = boundary;
      nearest = distance;
    }
  }
  return snapped;
}

ExcludeRangeDraft initialExcludeDraft({
  required Duration playhead,
  required Duration total,
  required List<double> boundaryPoints,
}) {
  final totalMs = total.inMilliseconds;
  final minGap = minSplitGapFraction(total);
  double edge(Duration at) => snapToBoundary(
    (at.inMilliseconds / totalMs).clamp(0.0, 1.0),
    boundaryPoints,
    minGap,
  );
  return (
    start: edge(playhead - kExcludeRangeReach),
    end: edge(playhead + kExcludeRangeReach),
  );
}
