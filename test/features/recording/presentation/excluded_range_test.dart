import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/recording/presentation/excluded_range.dart';

void main() {
  test('A range ending where a split mark sits leaves no sliver beside it', () {
    final parts = keptPartsOf(
      splitPoints: const [0.5],
      excludedSegments: const {},
      excludedRanges: const [
        ExcludedRange(startFraction: 0.2, endFraction: 0.5 - 1e-12),
      ],
    );

    expect(
      [for (final p in parts) (p.startFraction, p.endFraction)],
      [(0.0, 0.2), (0.5, 1.0)],
    );
  });
}
