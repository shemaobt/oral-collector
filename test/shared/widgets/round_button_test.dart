import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:oral_collector/core/theme/app_colors.dart';
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

  final tones = <RoundButtonTone, Color Function(AppColorSet)>{
    RoundButtonTone.accent: (c) => c.accent,
    RoundButtonTone.control: (c) => c.card,
    RoundButtonTone.soft: (c) => c.brickSoft,
  };
  final themes = {'light': AppTheme.lightTheme, 'dark': AppTheme.darkTheme};
  for (final theme in themes.entries) {
    testWidgets('tones fill their colour in ${theme.key}', (tester) async {
      for (final tone in tones.entries) {
        await pumpRound(
          tester,
          size: RoundButtonSize.action,
          tone: tone.key,
          theme: theme.value,
        );
        final colors = AppColors.of(tester.element(find.byType(RoundButton)));
        expect(disc(tester).color, tone.value(colors), reason: tone.key.name);
      }
    });
  }
}
