import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/theme/app_colors.dart';
import 'package:oral_collector/core/theme/app_opacity.dart';
import 'package:oral_collector/core/theme/app_radii.dart';
import 'package:oral_collector/core/theme/app_spacing.dart';
import 'package:oral_collector/core/theme/app_theme.dart';

BorderRadiusGeometry? _radiusOf(ShapeBorder? shape) =>
    (shape as RoundedRectangleBorder?)?.borderRadius;

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
}

void _expectPaddingFromTokens(ThemeData theme) {
  const buttonPadding = EdgeInsets.symmetric(horizontal: SpacingScale.s20);
  expect(_buttonPadding(theme.elevatedButtonTheme.style), buttonPadding);
  expect(_buttonPadding(theme.filledButtonTheme.style), buttonPadding);
}

const _brush = 'CaveatBrush';
const _sans = 'Montserrat';

final _roles = <String, (String, double, FontWeight)>{
  'displayLarge': (_brush, 44, FontWeight.w400),
  'displayMedium': (_brush, 42, FontWeight.w400),
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
  final style = theme.appBarTheme.titleTextStyle;
  expect(style?.fontFamily, _brush);
  expect(style?.fontSize, 28);
  expect(style?.fontFamilyFallback, [_sans]);
  expect(theme.appBarTheme.toolbarHeight, 64);
  final line = (theme.appBarTheme.shape! as Border).bottom;
  expect(line.width, 1.5);
  expect(line.color, theme.extension<AppColorSet>()!.border);
}

T? _on<T>(WidgetStateProperty<T>? p, [Set<WidgetState> s = const {}]) =>
    p?.resolve(s);

void _expectButtons(ThemeData theme) {
  final c = theme.extension<AppColorSet>()!;
  const stadium = StadiumBorder();
  final filled = theme.filledButtonTheme.style!;
  final elevated = theme.elevatedButtonTheme.style!;
  final outlined = theme.outlinedButtonTheme.style!;
  final icon = theme.iconButtonTheme.style!;

  for (final style in [filled, elevated]) {
    expect(_on(style.shape), stadium);
    expect(_on(style.minimumSize), const Size(0, 46));
    expect(_on(style.backgroundColor), c.accent);
    expect(_on(style.backgroundColor, {WidgetState.disabled}), c.surfaceAlt);
  }

  expect(_on(outlined.shape), stadium);
  expect(_on(outlined.minimumSize), const Size(0, 46));
  expect(_on(outlined.foregroundColor), c.primary);
  expect(_on(outlined.side), BorderSide(color: c.border, width: 1.5));

  expect(_on(icon.shape), const CircleBorder());
  expect(_on(icon.fixedSize), const Size(44, 44));
  expect(_on(icon.side), BorderSide(color: c.border, width: 1.5));
}

void _expectOverlays(ThemeData theme) {
  final c = theme.extension<AppColorSet>()!;
  final dialog = theme.dialogTheme;
  expect(dialog.backgroundColor, c.card);
  expect(_radiusOf(dialog.shape), BorderRadius.circular(RadiusScale.r24));

  final snack = theme.snackBarTheme;
  expect(snack.backgroundColor, c.primary);
  expect(snack.actionTextColor, c.wood);
  expect(_radiusOf(snack.shape), BorderRadius.circular(RadiusScale.r16));

  expect(theme.popupMenuTheme.color, c.card);
  expect(_on(theme.menuTheme.style!.backgroundColor), c.card);

  expect(theme.dividerTheme.color, c.border);
}

void _expectControls(ThemeData theme) {
  final c = theme.extension<AppColorSet>()!;
  final progress = theme.progressIndicatorTheme;
  expect(progress.color, c.accent);
  expect(progress.linearTrackColor, c.surfaceAlt);
  expect(progress.circularTrackColor, c.surfaceAlt);

  expect(theme.sliderTheme.activeTrackColor, c.accent);
  expect(theme.sliderTheme.inactiveTrackColor, c.border);
}

void main() {
  for (final (name, theme) in [
    ('lightTheme', AppTheme.lightTheme),
    ('darkTheme', AppTheme.darkTheme),
  ]) {
    group('$name buttons', () {
      test('read as the design pills and round icon buttons', () {
        _expectButtons(theme);
      });

      testWidgets('filled button label reads in the labelLarge role', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: FilledButton(onPressed: () {}, child: const Text('Go')),
          ),
        );
        final style = DefaultTextStyle.of(
          tester.element(find.text('Go')),
        ).style;
        expect(style.fontFamily, theme.textTheme.labelLarge!.fontFamily);
        expect(style.fontSize, theme.textTheme.labelLarge!.fontSize);
        expect(style.fontWeight, theme.textTheme.labelLarge!.fontWeight);
      });

      testWidgets('danger style reads the error colour', (tester) async {
        late ButtonStyle danger;
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Builder(
              builder: (context) {
                danger = AppButtonStyles.danger(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        final c = theme.extension<AppColorSet>()!;
        expect(_on(danger.backgroundColor), c.error);
        expect(_on(danger.shape), const StadiumBorder());
        expect(_on(danger.minimumSize), const Size(0, 46));
      });
    });

    test('$name dialogs, notices and menus read as the design', () {
      _expectOverlays(theme);
    });

    test(
      '$name chips, tabs, switches, checkboxes, sliders and progress read as the design',
      () {
        _expectControls(theme);
      },
    );

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

    test('button and input padding map to SpacingScale', () {
      _expectPaddingFromTokens(theme);
    });

    test('representative resolved opacity maps to OpacityScale', () {
      expect(theme.cardTheme.shadowColor!.a, closeTo(OpacityScale.o06, 0.001));
    });
  });

  group('darkTheme component geometry reads from tokens', () {
    final theme = AppTheme.darkTheme;

    test('radii map to RadiusScale', () {
      _expectComponentRadiiFromTokens(theme);
    });

    test('button and input padding map to SpacingScale', () {
      _expectPaddingFromTokens(theme);
    });

    test('representative resolved opacity maps to OpacityScale', () {
      expect(theme.cardTheme.shadowColor!.a, closeTo(OpacityScale.o40, 0.001));
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
