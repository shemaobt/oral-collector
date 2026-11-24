import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oral_collector/core/theme/app_colors.dart';
import 'package:oral_collector/core/theme/app_shadows.dart';
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

    test('light carries the new design roles', () {
      final c = AppColors.light;
      expect(c.wash.toARGB32(), 0xFFE3DFCA);
      expect(c.deep.toARGB32(), 0xFFA63B00);
      expect(c.soft.toARGB32(), 0xFFF9DAC4);
      expect(c.brickSoft.toARGB32(), 0xFFF6D7D2);
      expect(c.wood.toARGB32(), 0xFFC7A268);
      expect(c.woodSoft.toARGB32(), 0xFFF4E3BF);
      expect(c.woodText.toARGB32(), 0xFF6E4F1C);
      expect(c.bridgeSoft.toARGB32(), 0xFFD3E6E0);
      expect(c.slab.toARGB32(), 0xFF34331A);
    });

    test('dark carries the new design roles', () {
      final c = AppColors.dark;
      expect(c.wash.toARGB32(), 0xFF383124);
      expect(c.deep.toARGB32(), 0xFFF2955A);
      expect(c.soft.toARGB32(), 0xFF3A2416);
      expect(c.brickSoft.toARGB32(), 0xFF3A1F1B);
      expect(c.wood.toARGB32(), 0xFFE2C08F);
      expect(c.woodSoft.toARGB32(), 0xFF332A1B);
      expect(c.woodText.toARGB32(), 0xFFE2C08F);
      expect(c.bridgeSoft.toARGB32(), 0xFF1D2A27);
      expect(c.slab.toARGB32(), 0xFF2C271D);
    });

    test('chipSurface is its own colour in light and surfaceAlt in dark', () {
      // ENG-382 weighed retiring chipSurface and kept it on this measurement:
      // the two tokens coincide in dark, so a card repainted with surfaceAlt
      // would look right there and shift the chip a shade in light. Folding
      // the field away is the change this test exists to catch.
      expect(AppColors.light.chipSurface, isNot(AppColors.light.surfaceAlt));
      expect(AppColors.dark.chipSurface, AppColors.dark.surfaceAlt);
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
          chipSurface: Color.lerp(light.chipSurface, dark.chipSurface, 0.5)!,
          border: Color.lerp(light.border, dark.border, 0.5)!,
          error: Color.lerp(light.error, dark.error, 0.5)!,
          warning: Color.lerp(light.warning, dark.warning, 0.5)!,
          wash: Color.lerp(light.wash, dark.wash, 0.5)!,
          deep: Color.lerp(light.deep, dark.deep, 0.5)!,
          soft: Color.lerp(light.soft, dark.soft, 0.5)!,
          brickSoft: Color.lerp(light.brickSoft, dark.brickSoft, 0.5)!,
          wood: Color.lerp(light.wood, dark.wood, 0.5)!,
          woodSoft: Color.lerp(light.woodSoft, dark.woodSoft, 0.5)!,
          woodText: Color.lerp(light.woodText, dark.woodText, 0.5)!,
          bridgeSoft: Color.lerp(light.bridgeSoft, dark.bridgeSoft, 0.5)!,
          slab: Color.lerp(light.slab, dark.slab, 0.5)!,
        ),
      );
    });

    test('lerp at t=0.5 lands on the midpoint of each new role', () {
      final mid = AppColors.light.lerp(AppColors.dark, 0.5);

      expect(mid.wash.toARGB32(), isNot(AppColors.light.wash.toARGB32()));
      expect(mid.slab.toARGB32(), isNot(AppColors.dark.slab.toARGB32()));
      expect(
        mid.woodText,
        Color.lerp(AppColors.light.woodText, AppColors.dark.woodText, 0.5),
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

  group('ShadowTints', () {
    test('light shadows are olive and dark shadows are black', () {
      expect(ShadowTints.light.card, const Color.fromRGBO(63, 62, 32, 0.45));
      expect(ShadowTints.light.slab, const Color.fromRGBO(52, 51, 26, 0.7));
      expect(ShadowTints.dark.card, const Color.fromRGBO(0, 0, 0, 0.45));
      expect(ShadowTints.dark.slab, const Color.fromRGBO(0, 0, 0, 0.7));
    });

    testWidgets('of(context) follows the theme brightness', (tester) async {
      late ShadowTints resolved;
      Widget app(ThemeData theme) => MaterialApp(
        theme: theme,
        home: Builder(
          builder: (context) {
            resolved = ShadowTints.of(context);
            return const SizedBox();
          },
        ),
      );

      await tester.pumpWidget(app(ThemeData.light()));
      expect(resolved, same(ShadowTints.light));
      await tester.pumpWidget(app(ThemeData.dark()));
      await tester.pumpAndSettle();
      expect(resolved, same(ShadowTints.dark));
    });
  });
}
