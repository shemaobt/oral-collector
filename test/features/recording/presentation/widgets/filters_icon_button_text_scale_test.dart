// ENG-179: the filters icon button's count badge must survive a large system
// font without overflowing.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/recording/presentation/widgets/filters_icon_button.dart';

import '../../../../support/text_scale.dart';

Future<void> _pump(WidgetTester tester, double scale) async {
  await pumpAtTextScale(
    tester,
    scale: scale,
    child: Align(
      alignment: Alignment.topRight,
      child: FiltersIconButton(count: 99, onTap: () {}),
    ),
  );
  await tester.pump();
}

void main() {
  for (final scale in const [1.0, 1.3, 2.0]) {
    testWidgets('filters badge has no overflow at ${scale}x', (tester) async {
      await _pump(tester, scale);
      expectNoOverflow(tester);
    });
  }
}
