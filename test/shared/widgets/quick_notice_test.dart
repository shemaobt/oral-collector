import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/theme/app_motion.dart';
import 'package:oral_collector/shared/widgets/quick_notice.dart';

const _heldFor = Duration(milliseconds: 2900);

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
  await tester.pump();
  while (tester.binding.hasScheduledFrame) {
    await tester.pump(const Duration(milliseconds: 10));
  }
}

void main() {
  for (final still in [false, true]) {
    testWidgets('a notice stays, then leaves by itself'
        '${still ? ' with reduced motion' : ''}', (tester) async {
      await _pump(tester, still: still);

      await _show(tester);
      for (var i = 0; i < 29; i++) {
        await tester.pump(_heldFor ~/ 29);
      }
      expect(find.text('Saved 1'), findsOneWidget);

      await tester.pump(MotionScale.noticeStay - _heldFor);
      await tester.pumpAndSettle();
      expect(find.text('Saved 1'), findsNothing);
    });
  }

  testWidgets('a new notice replaces the one on screen, even as it leaves', (
    tester,
  ) async {
    final live = <Object>{};
    void track(ObjectEvent e) =>
        e is ObjectCreated ? live.add(e.object) : live.remove(e.object);

    await _pump(tester);
    FlutterMemoryAllocations.instance.addListener(track);
    addTearDown(() => FlutterMemoryAllocations.instance.removeListener(track));
    await _show(tester);
    await _show(tester);
    expect(find.text('Saved 1'), findsNothing);
    expect(find.text('Saved 2'), findsOneWidget);

    await tester.pump(MotionScale.noticeStay);
    await tester.pump(MotionScale.fast - const Duration(milliseconds: 1));
    await tester.tap(find.text('show'));
    await tester.pump(const Duration(milliseconds: 2));
    expect(find.text('Saved 3'), findsOneWidget);

    await tester.pumpAndSettle();
    await tester.pump(MotionScale.noticeStay);
    await tester.pumpAndSettle();
    expect(live.whereType<OverlayEntry>(), isEmpty);
  });

  testWidgets(
    'a notice shown from a route that is gone still leaves by itself',
    (tester) async {
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(navigatorKey: navigator, home: const Text('home')),
      );
      Route<void> page(String name) => MaterialPageRoute(
        builder: (context) => TextButton(
          onPressed: () => showQuickNotice(context, 'Saved'),
          child: Text(name),
        ),
      );

      unawaited(navigator.currentState!.push(page('first')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('first'));
      await tester.pumpAndSettle();

      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      unawaited(navigator.currentState!.push(page('second')));
      await tester.pumpAndSettle();
      expect(find.text('Saved'), findsOneWidget);

      await tester.pump(MotionScale.noticeStay);
      await tester.pumpAndSettle();
      expect(find.text('Saved'), findsNothing);
    },
  );

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
