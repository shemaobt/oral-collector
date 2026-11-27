import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/theme/app_motion.dart';
import 'package:oral_collector/shared/widgets/quick_notice.dart';

const _gap = Duration(milliseconds: 200);

Future<void> _pump(WidgetTester tester, {bool still = false}) async {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(disableAnimations: still);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  var count = 0;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => showQuickNotice(context, 'Saved ${++count}'),
          child: const Text('show'),
        ),
      ),
    ),
  );
}

Future<void> _show(WidgetTester tester) async {
  await tester.tap(find.text('show'));
  await tester.pumpAndSettle();
}

void main() {
  for (final still in [false, true]) {
    testWidgets('a notice stays, then leaves by itself'
        '${still ? ' with reduced motion' : ''}', (tester) async {
      await _pump(tester, still: still);

      await _show(tester);
      await tester.pump(MotionScale.noticeStay - _gap);
      expect(find.text('Saved 1'), findsOneWidget);

      await tester.pump(_gap);
      await tester.pumpAndSettle();
      expect(find.text('Saved 1'), findsNothing);
    });
  }

  testWidgets('a second notice takes the first one\'s place at once', (
    tester,
  ) async {
    await _pump(tester);
    await _show(tester);
    expect(find.text('Saved 1'), findsOneWidget);

    await _show(tester);
    expect(find.text('Saved 1'), findsNothing);
    expect(find.text('Saved 2'), findsOneWidget);

    await tester.pump(MotionScale.noticeStay);
    await tester.pumpAndSettle();
    expect(find.text('Saved 2'), findsNothing);
  });

  testWidgets('screen readers hear the sentence when the notice arrives', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(tester);
    await _show(tester);

    final node = tester.getSemantics(find.bySemanticsLabel('Saved 1'));
    expect(node.flagsCollection.isLiveRegion, isTrue);

    await tester.pump(MotionScale.noticeStay);
    await tester.pumpAndSettle();
    handle.dispose();
  });
}
