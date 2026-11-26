import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oral_collector/core/theme/app_colors.dart';
import 'package:oral_collector/core/theme/app_shadows.dart';
import 'package:oral_collector/core/theme/app_theme.dart';

void main() {
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

    test('light colour scheme reads the light tokens', () {
      final scheme = AppTheme.lightTheme.colorScheme;
      final c = AppColors.light;
      expect(scheme.error, c.error);
      expect(scheme.outline, c.border);
      expect(scheme.surface, c.background);
      expect(scheme.onSurface, c.foreground);
    });

    test('dark colour scheme reads the dark tokens', () {
      final scheme = AppTheme.darkTheme.colorScheme;
      final c = AppColors.dark;
      expect(scheme.error, c.error);
      expect(scheme.outline, c.border);
      expect(scheme.surface, c.background);
      expect(scheme.onSurface, c.foreground);
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
      expect(AppColors.meterWarning.toARGB32(), 0xFFC7A268);
      expect(AppColors.warningContainer.toARGB32(), 0xFFF4E3BF);
      expect(AppColors.onWarningContainer.toARGB32(), 0xFF6E4F1C);
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
