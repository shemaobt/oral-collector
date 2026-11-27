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

Future<void> _shown(WidgetTester tester, ValueNotifier<bool> on) async {
  on.value = true;
  await tester.pump();
  await tester.pump(MotionScale.checkWait);
  await tester.pump(MotionScale.fast);
  await tester.pump(MotionScale.fast);
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
  });

  testWidgets('a longer check runs a 38% stroke under the status bar and says '
      'it once, even when it comes back mid fade-out', (tester) async {
    final checking = await _pump(tester);
    await _shown(tester, checking);
    await tester.pump(const Duration(milliseconds: 350));

    expect(tester.getSize(_line).width, closeTo(148.2, 0.01));
    expect(tester.getTopLeft(_line).dy, 24);

    checking.value = false;
    await tester.pump();
    await tester.pump(MotionScale.fast ~/ 4);
    checking.value = true;
    await tester.pump();
    await tester.pump(MotionScale.fast);
    expect(_line, findsOneWidget);

    checking.value = false;
    await tester.pumpAndSettle();
    expect(_line, findsNothing);
    expect(said, ['Updating']);
  });

  testWidgets('with less motion one still stroke fills the width until the '
      'person turns less motion off', (tester) async {
    final checking = await _pump(tester, still: true);
    await _shown(tester, checking);

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
