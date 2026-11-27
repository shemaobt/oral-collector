import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/theme/app_colors.dart';
import 'package:oral_collector/core/theme/app_theme.dart';
import 'package:oral_collector/shared/widgets/user_avatar.dart';

Future<void> pump(WidgetTester tester, Widget child, {bool dark = false}) =>
    tester.pumpWidget(
      MaterialApp(
        theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
        home: Scaffold(body: Center(child: child)),
      ),
    );

BoxDecoration decorationOf(WidgetTester tester, Finder f) =>
    (tester.widget<Container>(f).decoration! as BoxDecoration);

void main() {
  for (final dark in [false, true]) {
    final mode = dark ? 'dark' : 'light';
    final colors = dark ? AppColors.dark : AppColors.light;

    group('UserAvatar $mode', () {
      testWidgets('without photo: brush initial on wood, ring in background', (
        tester,
      ) async {
        await pump(
          tester,
          const UserAvatar(radius: 22, displayName: 'Marta Souza'),
          dark: dark,
        );
        final d = decorationOf(tester, find.byType(Container));
        expect(d.color, colors.wood);
        expect(d.boxShadow!.last.color, colors.background);
        final text = tester.widget<Text>(find.text('MS'));
        expect(text.style!.fontFamily, 'CaveatBrush');
        expect(text.style!.color, colors.primary);
      });
    });
  }
}
