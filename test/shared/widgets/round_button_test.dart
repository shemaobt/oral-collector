import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:oral_collector/core/theme/app_theme.dart';
import 'package:oral_collector/shared/widgets/round_button.dart';

Future<void> pumpRound(
  WidgetTester tester, {
  required RoundButtonSize size,
  RoundButtonTone tone = RoundButtonTone.accent,
  ThemeData? theme,
  VoidCallback? onPressed,
}) => tester.pumpWidget(
  MaterialApp(
    theme: theme ?? AppTheme.lightTheme,
    home: Scaffold(
      body: Center(
        child: RoundButton(
          icon: LucideIcons.mic,
          semanticLabel: 'Record',
          size: size,
          tone: tone,
          onPressed: onPressed,
        ),
      ),
    ),
  ),
);

Finder get ink =>
    find.descendant(of: find.byType(RoundButton), matching: find.byType(Ink));

BoxDecoration disc(WidgetTester tester) =>
    tester.widget<Ink>(ink).decoration! as BoxDecoration;

void main() {
  const sizes = {
    RoundButtonSize.play: 44.0,
    RoundButtonSize.playLarge: 56.0,
    RoundButtonSize.action: 58.0,
    RoundButtonSize.control: 64.0,
  };
  for (final entry in sizes.entries) {
    testWidgets('${entry.key.name} draws a ${entry.value} disc, taps from 48', (
      tester,
    ) async {
      var presses = 0;
      await pumpRound(tester, size: entry.key, onPressed: () => presses++);
      expect(tester.getSize(ink), Size.square(entry.value));
      final target = tester.getSize(find.byType(InkWell));
      expect(target.shortestSide, greaterThanOrEqualTo(48));

      await tester.tapAt(tester.getCenter(ink) + const Offset(23, 0));
      expect(presses, 1);
    });
  }
}
