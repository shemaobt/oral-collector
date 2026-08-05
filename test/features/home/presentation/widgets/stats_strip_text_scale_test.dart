// ENG-181: the home StatsStrip tiles must not overflow under large system
// fonts. The numeric value sits in a FittedBox and labels ellipsize, so this
// locks that resilience as the hardcoded font size is removed.
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/theme/app_colors.dart';
import 'package:oral_collector/features/home/presentation/widgets/stats_strip.dart';

import '../../../../support/text_scale.dart';

Future<void> _pump(WidgetTester tester, double scale) async {
  await pumpAtTextScale(
    tester,
    scale: scale,
    child: const StatsStrip(
      totalRecordings: 128,
      totalDuration: 4521,
      memberCount: 7,
      colors: AppColors.light,
      storytellerCount: 3,
      unclassifiedCount: 5,
    ),
  );
  await tester.pump();
}

void main() {
  for (final scale in const [1.0, 1.3, 2.0]) {
    testWidgets('does not overflow at ${scale}x', (tester) async {
      await _pump(tester, scale);
      expectNoOverflow(tester);
    });
  }
}
