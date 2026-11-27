import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/theme/app_colors.dart';
import 'package:oral_collector/core/theme/app_theme.dart';
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

void main() {
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
}
