import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/theme/app_colors.dart';
import 'package:oral_collector/core/theme/app_theme.dart';
import 'package:oral_collector/core/theme/genre_colors.dart';
import 'package:oral_collector/shared/widgets/app_disc.dart';
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
    final genres = dark ? GenreColors.dark : GenreColors.light;

    group('AppDisc $mode', () {
      final disc = find.descendant(
        of: find.byType(AppDisc),
        matching: find.byType(Container),
      );

      for (final size in DiscSize.values) {
        testWidgets('${size.name} is ${size.diameter} round', (tester) async {
          await pump(
            tester,
            AppDisc(size: size, child: const Icon(Icons.mic)),
            dark: dark,
          );
          expect(tester.getSize(disc), Size.square(size.diameter));
          expect(decorationOf(tester, disc).shape, BoxShape.circle);
        });
      }

      final fills = <DiscTone, Color>{
        DiscTone.inset: colors.surfaceAlt,
        DiscTone.ink: colors.primary,
        DiscTone.g1: genres.tones[0].disc,
        DiscTone.g2: genres.tones[1].disc,
        DiscTone.g3: genres.tones[2].disc,
        DiscTone.g4: genres.tones[3].disc,
      };
      fills.forEach((tone, fill) {
        testWidgets('${tone.name} fills with its colour', (tester) async {
          await pump(
            tester,
            AppDisc(tone: tone, child: const Icon(Icons.mic)),
            dark: dark,
          );
          expect(decorationOf(tester, disc).color, fill);
        });
      });

      testWidgets('none is transparent with a border', (tester) async {
        await pump(
          tester,
          const AppDisc(tone: DiscTone.none, child: Icon(Icons.mic)),
          dark: dark,
        );
        final d = decorationOf(tester, disc);
        expect(d.color, Colors.transparent);
        expect((d.border! as Border).top.color, colors.border);
      });
    });

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
