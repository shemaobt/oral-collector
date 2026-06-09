import 'package:flutter/material.dart';
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

void main() {
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
