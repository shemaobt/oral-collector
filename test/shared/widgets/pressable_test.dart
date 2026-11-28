import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/theme/app_theme.dart';
import 'package:oral_collector/l10n/app_localizations.dart';
import 'package:oral_collector/shared/widgets/app_disc.dart';
import 'package:oral_collector/shared/widgets/record_button.dart';
import 'package:oral_collector/shared/widgets/round_button.dart';

Future<void> pumpPiece(
  WidgetTester tester,
  Widget piece, {
  bool reduceMotion = false,
}) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.lightTheme,
    locale: const Locale('en'),
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

double discWidth(WidgetTester tester) =>
    tester.getRect(find.byType(AppDisc)).width;

const _ms = Duration(milliseconds: 1);

void main() {
  testWidgets('a round button shrinks to 95% held and rests at 100% after', (
    tester,
  ) async {
    await pumpPiece(
      tester,
      RoundButton(icon: Icons.add, semanticLabel: 'add', onPressed: () {}),
    );
    expect(discWidth(tester), 56);

    final finger = await tester.startGesture(
      tester.getCenter(find.byType(RoundButton)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(discWidth(tester), closeTo(53.2, 0.05));

    await finger.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(discWidth(tester), greaterThan(56));
    await tester.pump(const Duration(milliseconds: 220));
    expect(discWidth(tester), closeTo(56, 0.01));
  });

  testWidgets('the record disc, not recording, shrinks from 96 to 91.2', (
    tester,
  ) async {
    await pumpPiece(tester, RecordButton(onTap: () {}));

    final finger = await tester.startGesture(
      tester.getCenter(find.byType(RecordButton)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(discWidth(tester), closeTo(91.2, 0.05));
    await finger.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(discWidth(tester), closeTo(96, 0.01));
  });

  testWidgets('a finger that slides off and lifts fires nothing and the piece '
      'comes back', (tester) async {
    var taps = 0;
    await pumpPiece(
      tester,
      RoundButton(
        icon: Icons.add,
        semanticLabel: 'add',
        onPressed: () => taps++,
      ),
    );

    final finger = await tester.startGesture(
      tester.getCenter(find.byType(RoundButton)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    await finger.moveBy(const Offset(0, 200));
    await tester.pump(_ms);
    await finger.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(taps, 0);
    expect(discWidth(tester), closeTo(56, 0.01));
  });

  testWidgets('a piece with nothing to do does not shrink', (tester) async {
    await pumpPiece(
      tester,
      const RoundButton(icon: Icons.add, semanticLabel: 'add'),
    );

    await tester.startGesture(tester.getCenter(find.byType(RoundButton)));
    await tester.pump(const Duration(milliseconds: 200));

    expect(discWidth(tester), 56);
  });

  testWidgets('with less motion the piece never changes size', (tester) async {
    await pumpPiece(
      tester,
      RoundButton(icon: Icons.add, semanticLabel: 'add', onPressed: () {}),
      reduceMotion: true,
    );

    final finger = await tester.startGesture(
      tester.getCenter(find.byType(RoundButton)),
    );
    await tester.pump(_ms);
    expect(discWidth(tester), 56);
    await finger.up();
    await tester.pump(_ms);
    expect(discWidth(tester), 56);
  });

  testWidgets('a round button of 44 answers a tap from its 48 target', (
    tester,
  ) async {
    var taps = 0;
    await pumpPiece(
      tester,
      RoundButton(
        icon: Icons.add,
        semanticLabel: 'add',
        size: RoundButtonSize.small,
        onPressed: () => taps++,
      ),
    );

    final box = tester.getRect(find.byType(RoundButton));
    await tester.tapAt(box.topLeft + const Offset(24, 1));

    expect(taps, 1);
  });

  testWidgets('either disc focused with the keyboard is pressed by Enter', (
    tester,
  ) async {
    var taps = 0;
    await pumpPiece(tester, RecordButton(onTap: () => taps++));

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);

    expect(taps, 1);
  });
}
