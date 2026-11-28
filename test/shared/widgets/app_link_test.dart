import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/theme/app_colors.dart';
import 'package:oral_collector/core/theme/app_theme.dart';
import 'package:oral_collector/shared/widgets/app_link.dart';

Future<void> pumpLink(WidgetTester tester, VoidCallback? onPressed) =>
    tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: AppLink(label: 'Saiba mais', onPressed: onPressed),
        ),
      ),
    );

DefaultTextStyle labelStyle(WidgetTester tester) => tester.widget(
  find
      .descendant(
        of: find.byType(AppLink),
        matching: find.byType(DefaultTextStyle),
      )
      .first,
);

void main() {
  testWidgets('underline follows the label colour when enabled', (
    tester,
  ) async {
    await pumpLink(tester, () {});
    final c = AppColors.of(tester.element(find.byType(AppLink)));
    final style = labelStyle(tester).style;
    expect(style.color, c.foreground);
    expect(style.decorationColor, c.foreground);
  });

  testWidgets('underline follows the label colour when disabled', (
    tester,
  ) async {
    await pumpLink(tester, null);
    final c = AppColors.of(tester.element(find.byType(AppLink)));
    final style = labelStyle(tester).style;
    expect(style.color, c.secondary);
    expect(style.decorationColor, c.secondary);
  });
}
