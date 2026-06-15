// ENG-178: the shared CleaningStatusBadge must keep its label readable under
// large system fonts. Under severe width pressure it must ellipsize rather than
// overflow; unconstrained, the full label stays in the tree.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/shared/widgets/cleaning_status_badge.dart';

import '../../support/text_scale.dart';

Future<void> _pump(
  WidgetTester tester, {
  bool compact = false,
  double? width,
}) async {
  final badge = CleaningStatusBadge(status: 'needs_cleaning', compact: compact);
  await pumpAtTextScale(
    tester,
    scale: 2.0,
    child: Center(
      child: width == null ? badge : SizedBox(width: width, child: badge),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets(
    'ellipsizes instead of overflowing under width pressure at 2.0x',
    (tester) async {
      await _pump(tester, width: 80);
      expectNoOverflow(tester);
    },
  );

  testWidgets('compact ellipsizes under width pressure at 2.0x', (
    tester,
  ) async {
    await _pump(tester, compact: true, width: 80);
    expectNoOverflow(tester);
  });

  testWidgets('full label stays in the tree at 2.0x', (tester) async {
    await _pump(tester);
    expect(find.text('Needs Cleaning'), findsOneWidget);
  });
}
