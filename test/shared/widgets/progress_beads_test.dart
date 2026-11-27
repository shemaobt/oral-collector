import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/theme/app_colors.dart';
import 'package:oral_collector/shared/widgets/progress_beads.dart';

Future<void> _pump(WidgetTester tester, int percent) => tester.pumpWidget(
  Directionality(
    textDirection: TextDirection.ltr,
    child: Center(child: ProgressBeads(percent: percent)),
  ),
);

void _expectLit(WidgetTester tester, int lit) {
  const colors = AppColors.light;
  final pattern = paints;
  for (var i = 0; i < 10; i++) {
    pattern.path(color: i < lit ? colors.accent : colors.pale);
  }
  expect(tester.renderObject(find.byType(CustomPaint).last), pattern);
}

void main() {
  const cases = {0: 0, 9: 0, 10: 1, 42: 4, 99: 9, 100: 10, 140: 10, -5: 0};
  for (final MapEntry(key: percent, value: lit) in cases.entries) {
    testWidgets('$percent% lights $lit beads', (tester) async {
      await _pump(tester, percent);
      _expectLit(tester, lit);
    });
  }

  testWidgets('is 140 wide and 10 high', (tester) async {
    await _pump(tester, 42);
    expect(tester.getSize(find.byType(ProgressBeads)), const Size(140, 10));
  });
}
