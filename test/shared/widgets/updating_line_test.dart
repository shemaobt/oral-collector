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
      builder: (_, on, _) =>
          UpdatingLine(checking: on, child: const SizedBox.expand()),
    ),
  );
  return checking;
}

void main() {
  final said = <String>[];

  setUp(() {
    said.clear();
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockDecodedMessageHandler<dynamic>(SystemChannels.accessibility, (
          message,
        ) async {
          said.add((message as Map)['data']['message'] as String);
        });
  });

  testWidgets('a check shorter than the wait shows nothing and says nothing', (
    tester,
  ) async {
    final checking = await _pump(tester);
    checking.value = true;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 249));
    checking.value = false;
    await tester.pump();
    await tester.pumpAndSettle();

    expect(_line, findsNothing);
    expect(said, isEmpty);
  });

  testWidgets('a longer check runs a 38% stroke, says it once, then leaves '
      'nothing running', (tester) async {
    final checking = await _pump(tester);
    checking.value = true;
    await tester.pump();
    await tester.pump(MotionScale.checkWait);
    await tester.pump(MotionScale.fast);
    await tester.pump(const Duration(milliseconds: 550));

    expect(tester.getSize(_line).width, closeTo(148.2, 0.01));
    expect(said, ['Updating']);

    checking.value = false;
    await tester.pumpAndSettle();
    expect(_line, findsNothing);
    expect(said, ['Updating']);
  });

  testWidgets('with less motion one still stroke fills the width', (
    tester,
  ) async {
    final checking = await _pump(tester, still: true);
    checking.value = true;
    await tester.pump();
    await tester.pump(MotionScale.checkWait);
    await tester.pump();

    expect(tester.getSize(_line).width, 390);
    expect(tester.getTopLeft(_line).dx, 0);

    checking.value = false;
    await tester.pumpAndSettle();
    expect(_line, findsNothing);
  });
}
