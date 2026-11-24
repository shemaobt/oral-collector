import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/theme/app_colors.dart';
import 'package:oral_collector/core/theme/app_theme.dart';
import 'package:oral_collector/l10n/app_localizations.dart';
import 'package:oral_collector/shared/widgets/record_button.dart';

Future<void> pumpButton(
  WidgetTester tester,
  ThemeData theme, {
  RecordButtonState state = RecordButtonState.ready,
}) => tester.pumpWidget(
  MaterialApp(
    theme: theme,
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    home: Scaffold(
      body: Center(child: RecordButton(state: state)),
    ),
  ),
);

BoxDecoration disc(WidgetTester tester) =>
    tester
            .widget<DecoratedBox>(
              find.descendant(
                of: find.byType(RecordButton),
                matching: find.byType(DecoratedBox),
              ),
            )
            .decoration
        as BoxDecoration;

double pulseScale(WidgetTester tester) => tester
    .widget<Transform>(
      find
          .descendant(
            of: find.byType(RecordButton),
            matching: find.byType(Transform),
          )
          .first,
    )
    .transform
    .getMaxScaleOnAxis();

void main() {
  final themes = {'light': AppTheme.lightTheme, 'dark': AppTheme.darkTheme};
  for (final theme in themes.entries) {
    testWidgets('disc is 88, error-coloured and ringed in ${theme.key}', (
      tester,
    ) async {
      for (final state in RecordButtonState.values) {
        await pumpButton(tester, theme.value, state: state);
        final colors = AppColors.of(tester.element(find.byType(RecordButton)));
        expect(disc(tester).color, colors.error, reason: state.name);
        expect(
          disc(
            tester,
          ).boxShadow!.any((s) => s.color == colors.error && s.blurRadius == 0),
          isTrue,
          reason: state.name,
        );
      }
      expect(tester.getSize(find.byType(RecordButton)), const Size(88, 88));
    });
  }

  testWidgets('pulses only while recording', (tester) async {
    await pumpButton(tester, AppTheme.lightTheme);
    await tester.pump(const Duration(milliseconds: 600));
    expect(pulseScale(tester), 1.0);

    await pumpButton(
      tester,
      AppTheme.lightTheme,
      state: RecordButtonState.recording,
    );
    await tester.pump(const Duration(milliseconds: 600));
    expect(pulseScale(tester), greaterThan(1.0));
  });
}
