import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/theme/app_colors.dart';
import 'package:oral_collector/core/theme/app_theme.dart';
import 'package:oral_collector/shared/widgets/app_tag.dart';

Future<void> _pump(WidgetTester tester, Widget child, {bool dark = false}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

(Color, Color) _drawn(WidgetTester tester) {
  final box = tester.widget<DecoratedBox>(
    find.descendant(
      of: find.byType(AppTag),
      matching: find.byType(DecoratedBox),
    ),
  );
  final fill = (box.decoration as BoxDecoration).color!;
  final ink = tester.widget<Text>(find.byType(Text)).style!.color!;
  return (fill, ink);
}

void main() {
  group('AppTag size', () {
    testWidgets('pill is 30 high', (tester) async {
      await _pump(tester, const AppTag(label: 'Sem narrador'));
      expect(tester.getSize(find.byType(AppTag)).height, 30);
    });

    testWidgets('chip is 22 high', (tester) async {
      await _pump(
        tester,
        const AppTag(label: 'Enviado', size: AppTagSize.chip),
      );
      expect(tester.getSize(find.byType(AppTag)).height, 22);
    });

    testWidgets('caps tag shows its label in uppercase at 11', (tester) async {
      await _pump(
        tester,
        const AppTag(label: 'Kaingang', size: AppTagSize.caps),
      );
      final text = tester.widget<Text>(find.byType(Text));
      expect(text.data, 'KAINGANG');
      expect(text.style!.fontSize, 11);
    });
  });

  for (final dark in [false, true]) {
    final colors = dark ? AppColors.dark : AppColors.light;
    final expected = {
      AppTagTone.telha: (colors.soft, colors.deep),
      AppTagTone.wood: (colors.woodSoft, colors.woodText),
      AppTagTone.plain: (colors.surfaceAlt, colors.secondary),
      AppTagTone.error: (colors.brickSoft, colors.error),
      AppTagTone.bridge: (colors.bridgeSoft, colors.info),
      AppTagTone.ink: (colors.slab, colors.onPrimary),
    };
    for (final entry in expected.entries) {
      testWidgets('${entry.key.name} tone in ${dark ? 'dark' : 'light'}', (
        tester,
      ) async {
        await _pump(
          tester,
          AppTag(label: 'x', tone: entry.key),
          dark: dark,
        );
        expect(_drawn(tester), entry.value);
      });
    }
  }
}
