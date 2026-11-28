import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/theme/app_colors.dart';
import 'package:oral_collector/core/theme/app_theme.dart';
import 'package:oral_collector/shared/widgets/empty_state.dart';
import 'package:oral_collector/shared/widgets/hand_cut_disc.dart';

Future<void> _pump(
  WidgetTester tester,
  EmptyState child, {
  required bool dark,
}) => tester.pumpWidget(
  MaterialApp(
    theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
    home: Scaffold(body: child),
  ),
);

final _disc = find.byWidgetPredicate(
  (w) => w is CustomPaint && w.painter is HandCutDiscPainter,
);

HandCutDiscPainter _painter(WidgetTester tester) => tester
    .widgetList<CustomPaint>(find.byType(CustomPaint))
    .map((p) => p.painter)
    .whereType<HandCutDiscPainter>()
    .single;

void main() {
  for (final dark in [false, true]) {
    final mode = dark ? 'dark' : 'light';
    final colors = dark ? AppColors.dark : AppColors.light;

    group('EmptyState $mode', () {
      testWidgets('calm: pale disc of 88, no shadow, sign 40 in ink', (
        tester,
      ) async {
        await _pump(
          tester,
          const EmptyState(icon: Icons.mic, title: 'One', description: 'Two'),
          dark: dark,
        );
        expect(tester.getSize(_disc), const Size.square(88));
        expect(_painter(tester).fill, colors.pale);
        expect(_painter(tester).shadow, isNull);
        final theme = IconTheme.of(tester.element(find.byIcon(Icons.mic)));
        expect(theme.size, closeTo(40, 0.5));
        expect(theme.color, colors.foreground);
      });

      testWidgets('failed: soft disc, sign in onSoft', (tester) async {
        await _pump(
          tester,
          const EmptyState(
            icon: Icons.mic,
            title: 'One',
            tone: EmptyTone.failed,
          ),
          dark: dark,
        );
        expect(_painter(tester).fill, colors.soft);
        expect(
          IconTheme.of(tester.element(find.byIcon(Icons.mic))).color,
          const Color(0xFF872F00),
        );
      });

      testWidgets('one sentence alone: 16 in ink', (tester) async {
        await _pump(
          tester,
          const EmptyState(icon: Icons.mic, title: 'Only'),
          dark: dark,
        );
        final style = tester.widget<Text>(find.text('Only')).style!;
        expect(style.fontSize, 16);
        expect(style.color, colors.foreground);
      });

      testWidgets('two lines: 17 w600 ink, then 15 muted at 1.45', (
        tester,
      ) async {
        await _pump(
          tester,
          const EmptyState(icon: Icons.mic, title: 'One', description: 'Two'),
          dark: dark,
        );
        final first = tester.widget<Text>(find.text('One')).style!;
        final second = tester.widget<Text>(find.text('Two')).style!;
        expect(first.fontSize, 17);
        expect(first.fontWeight, FontWeight.w600);
        expect(first.color, colors.foreground);
        expect(second.fontSize, 15);
        expect(second.color, colors.secondary);
        expect(second.height, 1.45);
      });

      testWidgets('disc, text and button are 14 apart', (tester) async {
        await _pump(
          tester,
          EmptyState(
            icon: Icons.mic,
            title: 'One',
            description: 'Two',
            action: FilledButton(onPressed: () {}, child: const Text('Go')),
          ),
          dark: dark,
        );
        final disc = tester.getRect(_disc);
        final first = tester.getRect(find.text('One'));
        final second = tester.getRect(find.text('Two'));
        final button = tester.getRect(find.byType(FilledButton));
        expect(first.top - disc.bottom, 14);
        expect(second.top - first.bottom, 14);
        expect(button.top - second.bottom, 14);
      });
    });
  }
}
