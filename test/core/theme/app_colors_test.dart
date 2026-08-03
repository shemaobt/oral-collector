import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oral_collector/core/theme/app_colors.dart';
import 'package:oral_collector/core/theme/app_theme.dart';

void main() {
  group('AppColorSet token values', () {
    // Intentional value-lock tripwire: these hex literals mirror the palette in
    // app_colors.dart. On a deliberate palette change, update both sides.
    test('light tokens match the design palette', () {
      final c = AppColors.light;
      expect(c.primary.toARGB32(), 0xFF3F3E20);
      expect(c.accent.toARGB32(), 0xFFBE4A01);
      expect(c.background.toARGB32(), 0xFFF6F5EB);
      expect(c.foreground.toARGB32(), 0xFF0A0703);
      expect(c.card.toARGB32(), 0xFFFDFCF3);
      expect(c.surfaceAlt.toARGB32(), 0xFFEDE9D5);
      expect(c.secondary.toARGB32(), 0xFF4A4830);
      expect(c.info.toARGB32(), 0xFF89AAA3);
      expect(c.infoText.toARGB32(), 0xFF4D6F68);
      expect(c.success.toARGB32(), 0xFF777D45);
      expect(c.successText.toARGB32(), 0xFF5D6233);
      expect(c.border.toARGB32(), 0xFFC5C29F);
      expect(c.error.toARGB32(), 0xFFB91C1C);
      expect(c.warning.toARGB32(), 0xFFFFA000);
    });

    test('dark tokens match the design palette', () {
      final c = AppColors.dark;
      expect(c.primary.toARGB32(), 0xFFD4D1A8);
      expect(c.accent.toARGB32(), 0xFFF09045);
      expect(c.background.toARGB32(), 0xFF1C1A14);
      expect(c.foreground.toARGB32(), 0xFFF2EFE4);
      expect(c.card.toARGB32(), 0xFF262318);
      expect(c.surfaceAlt.toARGB32(), 0xFF302D22);
      expect(c.secondary.toARGB32(), 0xFF9E9C7A);
      expect(c.info.toARGB32(), 0xFF4EC4AD);
      expect(c.infoText.toARGB32(), 0xFF9FD4C6);
      expect(c.success.toARGB32(), 0xFF9DC044);
      expect(c.successText.toARGB32(), 0xFFB4C976);
      expect(c.border.toARGB32(), 0xFF5A5440);
      expect(c.error.toARGB32(), 0xFFB91C1C);
      expect(c.warning.toARGB32(), 0xFFE0A458);
    });
  });

  group('AppColorSet ThemeExtension contract', () {
    test('copyWith() with no arguments yields a value-equal set', () {
      final copy = AppColors.light.copyWith();

      expect(copy, AppColors.light);
      expect(copy.hashCode, AppColors.light.hashCode);
    });

    test('copyWith replaces only the named field', () {
      const newAccent = Color(0xFF123456);
      final updated = AppColors.light.copyWith(accent: newAccent);

      expect(updated.accent, newAccent);
      expect(updated.primary, AppColors.light.primary);
      expect(updated.foreground, AppColors.light.foreground);
      expect(updated.error, AppColors.light.error);
      expect(updated.warning, AppColors.light.warning);
      expect(updated, isNot(AppColors.light));
    });

    test('lerp at t=1 yields the end set', () {
      expect(AppColors.light.lerp(AppColors.dark, 1), AppColors.dark);
    });

    test('lerp at t=0.5 interpolates every token', () {
      final light = AppColors.light;
      final dark = AppColors.dark;
      final mid = light.lerp(dark, 0.5);

      expect(
        mid,
        AppColorSet(
          primary: Color.lerp(light.primary, dark.primary, 0.5)!,
          accent: Color.lerp(light.accent, dark.accent, 0.5)!,
          background: Color.lerp(light.background, dark.background, 0.5)!,
          foreground: Color.lerp(light.foreground, dark.foreground, 0.5)!,
          card: Color.lerp(light.card, dark.card, 0.5)!,
          surfaceAlt: Color.lerp(light.surfaceAlt, dark.surfaceAlt, 0.5)!,
          secondary: Color.lerp(light.secondary, dark.secondary, 0.5)!,
          info: Color.lerp(light.info, dark.info, 0.5)!,
          infoText: Color.lerp(light.infoText, dark.infoText, 0.5)!,
          success: Color.lerp(light.success, dark.success, 0.5)!,
          successText: Color.lerp(light.successText, dark.successText, 0.5)!,
          onPrimary: Color.lerp(light.onPrimary, dark.onPrimary, 0.5)!,
          border: Color.lerp(light.border, dark.border, 0.5)!,
          error: Color.lerp(light.error, dark.error, 0.5)!,
          warning: Color.lerp(light.warning, dark.warning, 0.5)!,
        ),
      );
    });

    test('lerp(null, ...) returns the original set unchanged', () {
      expect(AppColors.light.lerp(null, 0.5), same(AppColors.light));
    });
  });

  group('ThemeData registration', () {
    test('lightTheme registers the light AppColorSet extension', () {
      expect(AppTheme.lightTheme.extension<AppColorSet>(), AppColors.light);
    });

    test('darkTheme registers the dark AppColorSet extension', () {
      expect(AppTheme.darkTheme.extension<AppColorSet>(), AppColors.dark);
    });
  });

  group('AppColors.of resolution', () {
    testWidgets(
      'prefers the registered extension over the brightness fallback',
      (tester) async {
        const sentinel = Color(0xFF010203);
        late AppColorSet resolved;
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light().copyWith(
              extensions: [AppColors.light.copyWith(primary: sentinel)],
            ),
            home: Builder(
              builder: (context) {
                resolved = AppColors.of(context);
                return const SizedBox();
              },
            ),
          ),
        );

        expect(resolved.primary, sentinel);
      },
    );

    testWidgets('falls back to light tokens when no extension is registered', (
      tester,
    ) async {
      late AppColorSet resolved;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Builder(
            builder: (context) {
              resolved = AppColors.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(resolved.primary, AppColors.light.primary);
    });

    testWidgets('falls back to dark tokens when no extension is registered', (
      tester,
    ) async {
      late AppColorSet resolved;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Builder(
            builder: (context) {
              resolved = AppColors.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(resolved.primary, AppColors.dark.primary);
    });
  });

  group('Neutral anchors and long-tail tokens', () {
    // Value-lock tripwire (pixel-identical refactor, ENG-183): these mirror raw
    // literals migrated out of widgets. Values must stay identical.
    test('neutral anchors are the pure ARGB primitives', () {
      expect(AppColors.white.toARGB32(), 0xFFFFFFFF);
      expect(AppColors.black.toARGB32(), 0xFF000000);
      expect(AppColors.transparent.toARGB32(), 0x00000000);
    });

    test('long-tail semantic tokens match the migrated literals', () {
      expect(AppColors.meterWarning.toARGB32(), 0xFFE0A526);
      expect(AppColors.warningContainer.toARGB32(), 0xFFFFEDCC);
      expect(AppColors.onWarningContainer.toARGB32(), 0xFF8A5A00);
      expect(AppColors.authHeroAccent.toARGB32(), 0xFFFFB380);
    });
  });
}
