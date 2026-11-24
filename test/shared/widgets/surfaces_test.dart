import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/theme/app_colors.dart';
import 'package:oral_collector/core/theme/app_radii.dart';
import 'package:oral_collector/core/theme/app_theme.dart';
import 'package:oral_collector/shared/widgets/app_tile.dart';
import 'package:oral_collector/shared/widgets/row_group.dart';
import 'package:oral_collector/shared/widgets/slab_card.dart';
import 'package:oral_collector/shared/widgets/stat_tile.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  ThemeData? theme,
  TextDirection direction = TextDirection.ltr,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: theme ?? AppTheme.lightTheme,
      home: Directionality(
        textDirection: direction,
        child: Scaffold(
          body: Align(
            alignment: AlignmentDirectional.topStart,
            child: SizedBox(width: 200, child: child),
          ),
        ),
      ),
    ),
  );
}

BoxDecoration _surface(WidgetTester tester, Finder within) {
  final box = tester.widget<DecoratedBox>(
    find.descendant(of: within, matching: find.byType(DecoratedBox)).first,
  );
  return box.decoration as BoxDecoration;
}

void main() {
  group('AppTile', () {
    testWidgets('draws card fill, 1.5 wash border and radius 24', (
      tester,
    ) async {
      await _pump(tester, const AppTile(child: Text('x')));
      final decoration = _surface(tester, find.byType(AppTile));
      expect(decoration.color, AppColors.light.card);
      expect(
        decoration.border,
        Border.all(color: AppColors.light.wash, width: 1.5),
      );
      expect(decoration.borderRadius, BorderRadius.circular(RadiusScale.r24));
    });

    for (final direction in TextDirection.values) {
      testWidgets('stripe is 4 wide on the start side in $direction', (
        tester,
      ) async {
        await _pump(
          tester,
          const AppTile(stripe: StripeTone.brick, child: Text('x')),
          direction: direction,
        );
        final tile = tester.getRect(find.byType(AppTile));
        final stripe = tester.getRect(find.byKey(AppTile.stripeKey));
        expect(stripe.width, 4);
        if (direction == TextDirection.ltr) {
          expect(stripe.left, tile.left);
        } else {
          expect(stripe.right, tile.right);
        }
        final fill = tester.widget<ColoredBox>(find.byKey(AppTile.stripeKey));
        expect(fill.color, AppColors.light.error);
      });
    }
  });

  group('StatTile', () {
    Text number(WidgetTester tester) => tester.widget<Text>(find.text('128'));

    testWidgets('number uses displaySmall, in foreground colour', (
      tester,
    ) async {
      await _pump(tester, const StatTile(value: '128', label: 'recordings'));
      final theme = AppTheme.lightTheme.textTheme.displaySmall!;
      final style = number(tester).style!;
      expect(style.fontSize, theme.fontSize);
      expect(style.fontWeight, theme.fontWeight);
      expect(style.color, AppColors.light.foreground);
      expect(find.text('recordings'), findsOneWidget);
    });

    testWidgets('number takes the accent colour when hot', (tester) async {
      await _pump(
        tester,
        const StatTile(value: '128', label: 'recordings', hot: true),
      );
      expect(number(tester).style!.color, AppColors.light.accent);
    });
  });

  group('SlabCard', () {
    testWidgets('light: slab fill, text in the background colour', (
      tester,
    ) async {
      await _pump(tester, const SlabCard(child: Text('x')));
      expect(
        _surface(tester, find.byType(SlabCard)).color,
        AppColors.light.slab,
      );
      final style = DefaultTextStyle.of(tester.element(find.text('x'))).style;
      expect(style.color, AppColors.light.background);
    });

    testWidgets('dark: card fill', (tester) async {
      await _pump(
        tester,
        const SlabCard(child: Text('x')),
        theme: AppTheme.darkTheme,
      );
      expect(
        _surface(tester, find.byType(SlabCard)).color,
        AppColors.dark.card,
      );
    });
  });

  group('RowGroup', () {
    testWidgets('stacks its rows inside one tile, in order', (tester) async {
      await _pump(
        tester,
        const RowGroup(children: [Text('a'), Text('b'), Text('c')]),
      );
      expect(find.byType(AppTile), findsOneWidget);
      final tops = [
        'a',
        'b',
        'c',
      ].map((t) => tester.getTopLeft(find.text(t)).dy).toList();
      expect(tops, [...tops]..sort());
      expect(tops.toSet().length, 3);
    });
  });
}
