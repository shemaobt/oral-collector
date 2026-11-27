import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/theme/app_motion.dart';
import 'package:oral_collector/shared/widgets/updating_line.dart';

import '../../support/text_scale.dart';

final _line = find.descendant(
  of: find.byType(UpdatingLine),
  matching: find.byType(DecoratedBox),
);

Future<ValueNotifier<bool>> _pump(
  WidgetTester tester, {
  bool still = false,
}) async {
  final checking = ValueNotifier(false);
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(disableAnimations: still);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  await pumpAtTextScale(
    tester,
    child: ValueListenableBuilder(
      valueListenable: checking,
      builder: (context, on, _) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(padding: const EdgeInsets.only(top: 24)),
        child: UpdatingLine(checking: on, child: const SizedBox.expand()),
      ),
    ),
  );
  return checking;
}

void main() {
  final said = <String>[];

  setUp(() {
    said.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockDecodedMessageHandler<dynamic>(SystemChannels.accessibility, (
          message,
        ) async {
          said.add((message as Map)['data']['message'] as String);
        });
  });

  testWidgets('a check ending before the line shows leaves nothing running '
      'and says nothing', (tester) async {
    final checking = await _pump(tester);
    checking.value = true;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 249));
    checking.value = false;
    await tester.pump();
    await tester.pump(MotionScale.checkWait * 2);
    expect(tester.hasRunningAnimations, isFalse);
    expect(said, isEmpty);
    checking.value = true;
    await tester.pump();
    await tester.pump(MotionScale.checkWait);
    checking.value = false;
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();
    expect(_line, findsNothing);
    checking.value = true;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(const SizedBox());
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('a longer check runs a 38% stroke under the status bar, fades '
      'in on enter and out on leave, and says it once', (tester) async {
    final checking = await _pump(tester);
    double opacity() => tester
        .widget<FadeTransition>(
          find.ancestor(of: _line, matching: find.byType(FadeTransition)).first,
        )
        .opacity
        .value;
    checking.value = true;
    await tester.pump();
    await tester.pump(MotionScale.checkWait);
    await tester.pump(MotionScale.checkWait);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(opacity(), closeTo(0.950, 0.001));
    await tester.pump(MotionScale.fast);
    expect(tester.getSize(_line).width, closeTo(148.2, 0.01));
    expect(tester.getTopLeft(_line).dy, 24);
    checking.value = false;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final out = opacity();
    expect(out, closeTo(0.846, 0.001));
    checking.value = true;
    await tester.pump();
    expect(opacity(), closeTo(out, 0.001));
    checking.value = false;
    await tester.pumpAndSettle();
    expect(_line, findsNothing);
    expect(said, ['Updating']);
  });

  testWidgets('with less motion one still stroke fills the width until the '
      'person turns less motion off', (tester) async {
    final checking = await _pump(tester, still: true);
    checking.value = true;
    await tester.pump();
    await tester.pump(MotionScale.checkWait + MotionScale.fast * 2);
    expect(tester.getSize(_line).width, 390);
    expect(tester.getTopLeft(_line).dx, 0);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures();
    await tester.pump();
    await tester.pump(MotionScale.fast);
    final before = tester.getTopLeft(_line).dx;
    await tester.pump(MotionScale.fast);
    expect(tester.getTopLeft(_line).dx, isNot(before));
  });
}
