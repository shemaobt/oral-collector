import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/theme/app_theme.dart';
import 'package:oral_collector/shared/widgets/app_choice.dart';
import 'package:oral_collector/shared/widgets/app_switch.dart';
import 'package:oral_collector/shared/widgets/app_tick.dart';

Future<void> pumpTight(WidgetTester tester, Widget piece) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.lightTheme,
    home: Scaffold(body: ListView(children: [piece])),
  ),
);

Future<void> pressKey(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pump();
}

void main() {
  testWidgets('a bare tick keeps its mark and ignores a tap beside it', (
    tester,
  ) async {
    var marked = false;
    await pumpTight(
      tester,
      AppTick(marked: marked, onChanged: (value) => marked = value),
    );
    final box = tester.getSize(find.byType(CustomPaint).last);
    expect(box, const Size.square(26));
    await tester.tapAt(const Offset(780, 20));
    expect(marked, isFalse);
    await tester.tap(find.byType(InkWell));
    expect(marked, isTrue);
  });

  testWidgets('a bare choice ignores a tap beside its ring', (tester) async {
    var chosen = false;
    await pumpTight(
      tester,
      AppChoice(chosen: false, onChosen: () => chosen = true),
    );
    await tester.tapAt(const Offset(780, 20));
    expect(chosen, isFalse);
    await tester.tap(find.byType(InkWell));
    expect(chosen, isTrue);
  });

  testWidgets('the switch stays 52 by 30 under a tight width', (tester) async {
    await pumpTight(tester, AppSwitch(on: false, onChanged: (_) {}));
    expect(
      tester.getSize(
        find
            .descendant(
              of: find.byType(AppSwitch),
              matching: find.byType(SizedBox),
            )
            .first,
      ),
      const Size(52, 30),
    );
  });

  testWidgets('the switch toggles from the keyboard', (tester) async {
    final heard = <bool>[];
    await pumpTight(tester, AppSwitch(on: false, onChanged: heard.add));
    await pressKey(tester, LogicalKeyboardKey.tab);
    await pressKey(tester, LogicalKeyboardKey.space);
    await pressKey(tester, LogicalKeyboardKey.enter);
    expect(heard, [true, true]);
  });
}
