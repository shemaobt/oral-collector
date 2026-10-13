class ExcludedRange {
  const ExcludedRange({required this.startFraction, required this.endFraction});

  final double startFraction;
  final double endFraction;
}

class KeptPart {
  const KeptPart({
    required this.segmentIndex,
    required this.startFraction,
    required this.endFraction,
  });

  final int segmentIndex;
  final double startFraction;
  final double endFraction;
}

bool isNearRangeEdge(
  double fraction,
  List<ExcludedRange> ranges,
  double minGap,
) => ranges.any(
  (r) =>
      (fraction - r.startFraction).abs() < minGap ||
      (fraction - r.endFraction).abs() < minGap,
);

double keepClearOfRangeEdges(
  double fraction,
  double previous,
  List<ExcludedRange> ranges,
  double minGap,
) {
  var clear = fraction;
  for (final r in ranges) {
    for (final edge in [r.startFraction, r.endFraction]) {
      if ((clear - edge).abs() < minGap) {
        clear = previous < edge ? edge - minGap : edge + minGap;
      }
    }
  }
  return clear;
}

List<KeptPart> keptPartsOf({
  required List<double> splitPoints,
  required Set<int> excludedSegments,
  required List<ExcludedRange> excludedRanges,
}) {
  final boundaries = [
    0.0,
    ...[...splitPoints]..sort(),
    1.0,
  ];
  final holes = mergedRanges(excludedRanges);
  return [
    for (var i = 0; i < boundaries.length - 1; i++)
      if (!excludedSegments.contains(i))
        ..._outsideHoles(i, boundaries[i], boundaries[i + 1], holes),
  ];
}

List<ExcludedRange> mergedRanges(List<ExcludedRange> ranges) {
  final sorted = [...ranges]
    ..sort((a, b) => a.startFraction.compareTo(b.startFraction));
  final merged = <ExcludedRange>[];
  for (final r in sorted) {
    if (merged.isNotEmpty && r.startFraction <= merged.last.endFraction) {
      final last = merged.removeLast();
      merged.add(
        ExcludedRange(
          startFraction: last.startFraction,
          endFraction: r.endFraction > last.endFraction
              ? r.endFraction
              : last.endFraction,
        ),
      );
    } else {
      merged.add(r);
    }
  }
  return merged;
}

List<KeptPart> _outsideHoles(
  int segmentIndex,
  double start,
  double end,
  List<ExcludedRange> holes,
) {
  final parts = <KeptPart>[];
  var cursor = start;
  for (final h in holes) {
    if (h.endFraction <= cursor) continue;
    if (h.startFraction >= end) break;
    if (h.startFraction > cursor) {
      parts.add(
        KeptPart(
          segmentIndex: segmentIndex,
          startFraction: cursor,
          endFraction: h.startFraction,
        ),
      );
    }
    cursor = h.endFraction;
  }
  if (cursor < end) {
    parts.add(
      KeptPart(
        segmentIndex: segmentIndex,
        startFraction: cursor,
        endFraction: end,
      ),
    );
  }
  return parts;
}
