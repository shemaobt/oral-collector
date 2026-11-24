import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/theme/app_opacity.dart';
import 'package:oral_collector/core/theme/app_radii.dart';
import 'package:oral_collector/core/theme/app_spacing.dart';
import 'package:oral_collector/core/theme/app_theme.dart';

BorderRadiusGeometry? _radiusOf(ShapeBorder? shape) =>
    (shape as RoundedRectangleBorder?)?.borderRadius;

OutlinedBorder? _buttonShape(ButtonStyle? style) =>
    style?.shape?.resolve(<WidgetState>{});

EdgeInsetsGeometry? _buttonPadding(ButtonStyle? style) =>
    style?.padding?.resolve(<WidgetState>{});

void _expectComponentRadiiFromTokens(ThemeData theme) {
  expect(
    _radiusOf(theme.cardTheme.shape),
    BorderRadius.circular(RadiusScale.r16),
  );
  expect(
    _radiusOf(theme.floatingActionButtonTheme.shape),
    BorderRadius.circular(RadiusScale.r16),
  );
  expect(
    _radiusOf(_buttonShape(theme.elevatedButtonTheme.style)),
    BorderRadius.circular(RadiusScale.r12),
  );
  expect(
    _radiusOf(_buttonShape(theme.filledButtonTheme.style)),
    BorderRadius.circular(RadiusScale.r12),
  );
  expect(
    _radiusOf(_buttonShape(theme.outlinedButtonTheme.style)),
    BorderRadius.circular(RadiusScale.r12),
  );
  expect(
    (theme.inputDecorationTheme.border! as OutlineInputBorder).borderRadius,
    BorderRadius.circular(RadiusScale.r12),
  );
  expect(
    _radiusOf(theme.chipTheme.shape),
    BorderRadius.circular(RadiusScale.r20),
  );
  expect(
    _radiusOf(theme.dialogTheme.shape),
    BorderRadius.circular(RadiusScale.r20),
  );
}

void _expectPaddingFromTokens(ThemeData theme) {
  const buttonPadding = EdgeInsets.symmetric(
    horizontal: SpacingScale.s28,
    vertical: 14,
  );
  expect(_buttonPadding(theme.elevatedButtonTheme.style), buttonPadding);
  expect(_buttonPadding(theme.filledButtonTheme.style), buttonPadding);
  expect(
    theme.inputDecorationTheme.contentPadding,
    const EdgeInsets.symmetric(
      horizontal: SpacingScale.s16,
      vertical: SpacingScale.s16,
    ),
  );
}

const _brush = 'CaveatBrush';
const _sans = 'Montserrat';

final _roles = <String, (String, double, FontWeight)>{
  'displayLarge': (_brush, 44, FontWeight.w400),
  'displayMedium': (_brush, 36, FontWeight.w400),
  'displaySmall': (_brush, 28, FontWeight.w400),
  'headlineLarge': (_brush, 28, FontWeight.w400),
  'headlineMedium': (_brush, 23, FontWeight.w400),
  'headlineSmall': (_sans, 16, FontWeight.w700),
  'titleLarge': (_sans, 16, FontWeight.w700),
  'titleMedium': (_sans, 14, FontWeight.w700),
  'titleSmall': (_sans, 14, FontWeight.w600),
  'bodyLarge': (_sans, 16, FontWeight.w500),
  'bodyMedium': (_sans, 14, FontWeight.w500),
  'bodySmall': (_sans, 13, FontWeight.w500),
  'labelLarge': (_sans, 14, FontWeight.w700),
  'labelMedium': (_sans, 12, FontWeight.w700),
  'labelSmall': (_sans, 11, FontWeight.w700),
};

Map<String, TextStyle?> _styles(TextTheme t) => {
  'displayLarge': t.displayLarge,
  'displayMedium': t.displayMedium,
  'displaySmall': t.displaySmall,
  'headlineLarge': t.headlineLarge,
  'headlineMedium': t.headlineMedium,
  'headlineSmall': t.headlineSmall,
  'titleLarge': t.titleLarge,
  'titleMedium': t.titleMedium,
  'titleSmall': t.titleSmall,
  'bodyLarge': t.bodyLarge,
  'bodyMedium': t.bodyMedium,
  'bodySmall': t.bodySmall,
  'labelLarge': t.labelLarge,
  'labelMedium': t.labelMedium,
  'labelSmall': t.labelSmall,
};

void _expectTypography(ThemeData theme) {
  final styles = _styles(theme.textTheme);
  for (final MapEntry(key: role, value: (family, size, weight))
      in _roles.entries) {
    final style = styles[role]!;
    expect(style.fontFamily, family, reason: role);
    expect(style.fontSize, size, reason: role);
    expect(style.fontWeight, weight, reason: role);
    expect(style.fontStyle, isNot(FontStyle.italic), reason: role);
    if (family == _brush) {
      expect(style.fontFamilyFallback, [_sans], reason: role);
    }
  }
}

void _expectBrushTitles(ThemeData theme) {
  for (final style in [
    theme.appBarTheme.titleTextStyle,
    theme.dialogTheme.titleTextStyle,
  ]) {
    expect(style?.fontFamily, _brush);
    expect(style?.fontSize, 28);
    expect(style?.fontFamilyFallback, [_sans]);
  }
}

void main() {
  for (final (name, theme) in [
    ('lightTheme', AppTheme.lightTheme),
    ('darkTheme', AppTheme.darkTheme),
  ]) {
    group('$name typography', () {
      test('titles read in the brush and the rest in Montserrat', () {
        _expectTypography(theme);
      });

      test('app bar and dialog titles read in the brush at 28', () {
        _expectBrushTitles(theme);
      });
    });
  }

  test(
    'the font manifest ships Montserrat and Caveat Brush, not Plus Jakarta Sans',
    () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final manifest =
          jsonDecode(await rootBundle.loadString('FontManifest.json')) as List;
      final families = manifest.map((f) => (f as Map)['family']).toSet();
      expect(families, containsAll([_sans, _brush]));
      expect(families, isNot(contains('PlusJakartaSans')));
    },
  );

  group('lightTheme component geometry reads from tokens', () {
    final theme = AppTheme.lightTheme;

    test('radii map to RadiusScale', () {
      _expectComponentRadiiFromTokens(theme);
    });

    test(
      'button and input padding map to SpacingScale, keeping off-grid 14',
      () {
        _expectPaddingFromTokens(theme);
      },
    );

    test('bottom sheet top radius maps to RadiusScale.r20', () {
      final shape = theme.bottomSheetTheme.shape! as RoundedRectangleBorder;
      expect(
        shape.borderRadius,
        const BorderRadius.vertical(top: Radius.circular(RadiusScale.r20)),
      );
    });

    test('representative resolved opacity maps to OpacityScale', () {
      expect(theme.dividerTheme.color!.a, closeTo(OpacityScale.o40, 0.001));
    });
  });

  group('darkTheme component geometry reads from tokens', () {
    final theme = AppTheme.darkTheme;

    test('radii map to RadiusScale', () {
      _expectComponentRadiiFromTokens(theme);
    });

    test(
      'button and input padding map to SpacingScale, keeping off-grid 14',
      () {
        _expectPaddingFromTokens(theme);
      },
    );

    test('representative resolved opacity maps to OpacityScale', () {
      expect(theme.dividerTheme.color!.a, closeTo(OpacityScale.o30, 0.001));
    });
  });

  testWidgets('light theme mounts a MaterialApp without exceptions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(body: SizedBox.shrink()),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('dark theme mounts a MaterialApp without exceptions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(body: SizedBox.shrink()),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
