import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/theme/app_theme.dart';
import 'package:oral_collector/l10n/app_localizations.dart';
import 'package:oral_collector/shared/widgets/app_disc.dart';
import 'package:oral_collector/shared/widgets/pressable.dart';
import 'package:oral_collector/shared/widgets/record_button.dart';
import 'package:oral_collector/shared/widgets/round_button.dart';

Future<void> pumpPiece(
  WidgetTester tester,
  Widget piece, {
  bool reduceMotion = false,
}) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.lightTheme,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
      child: child!,
    ),
    home: Scaffold(body: Center(child: piece)),
  ),
);

RoundButton add(
  VoidCallback onPressed, [
  RoundButtonSize size = RoundButtonSize.medium,
]) => RoundButton(
  icon: Icons.add,
  semanticLabel: 'add',
  size: size,
  onPressed: onPressed,
);

double discWidth(WidgetTester tester) =>
    tester.getRect(find.byType(AppDisc)).width;

Future<TestGesture> hold(WidgetTester tester, Finder piece) async {
  final finger = await tester.startGesture(tester.getCenter(piece));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 120));
  return finger;
}

void main() {
  testWidgets('a pressed piece is one button holding its label and its tap', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpPiece(
      tester,
      Pressable(onTap: () {}, child: const Text('Alpha')),
    );

    expect(
      tester.getSemantics(find.text('Alpha')),
      matchesSemantics(
        label: 'Alpha',
        isButton: true,
        isFocusable: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('the record button stays one node with its label and tap', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpPiece(tester, RecordButton(onTap: () {}));

    expect(
      tester.getSemantics(find.bySemanticsLabel('Start recording')),
      matchesSemantics(
        label: 'Start recording',
        isButton: true,
        isFocusable: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('a slid-off finger fires nothing and the disc springs back', (
    tester,
  ) async {
    var taps = 0;
    await pumpPiece(tester, add(() => taps++));

    final finger = await hold(tester, find.byType(RoundButton));
    expect(discWidth(tester), closeTo(53.2, 0.05));
    await finger.moveBy(const Offset(0, 200));
    await finger.up();
    await tester.pumpAndSettle();

    expect(taps, 0);
    expect(discWidth(tester), closeTo(56, 0.01));
  });

  testWidgets('with less motion the disc never changes size', (tester) async {
    await pumpPiece(tester, add(() {}), reduceMotion: true);

    await hold(tester, find.byType(RoundButton));

    expect(discWidth(tester), 56);
  });

  testWidgets('the 44 button answers a tap in its 48 target', (tester) async {
    var taps = 0;
    await pumpPiece(tester, add(() => taps++, RoundButtonSize.small));

    await tester.tapAt(
      tester.getCenter(find.byType(RoundButton)) + const Offset(0, 23),
    );

    expect(taps, 1);
  });

  testWidgets('Enter presses the focused disc', (tester) async {
    var taps = 0;
    await pumpPiece(tester, RecordButton(onTap: () => taps++));

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);

    expect(taps, 1);
  });
}
