// ENG-374: main.dart caps the system text scale at 2.0x, so the guided-steps
// sheet has to stay usable there. It is opened through a real
// showModalBottomSheet(isScrollControlled: true) because the defect is the
// sheet growing past the screen and taking its primary action with it.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/theme/app_colors.dart';
import 'package:oral_collector/features/recording/domain/entities/review_pendency.dart';
import 'package:oral_collector/features/recording/presentation/widgets/complete_ficha_sheet.dart';
import 'package:oral_collector/l10n/app_localizations.dart';

import '../../../../support/text_scale.dart';

/// Sub-pixel slack: layout arithmetic lands a hair off round numbers.
const _epsilon = 0.01;

/// The full set of steps — the worst case, and the one a fresh recording gets.
const _allSteps = [
  PendencyKind.classification,
  PendencyKind.description,
  PendencyKind.storyteller,
];

Future<void> _openSheet(
  WidgetTester tester, {
  required double scale,
  required Locale locale,
}) async {
  tester.view.physicalSize = kPhoneSize * 3.0;
  tester.view.devicePixelRatio = 3.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      // The sheet renders in the app Overlay, so the scaler has to sit above
      // the Navigator to reach it.
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                backgroundColor: AppColors.transparent,
                builder: (_) => CompleteFichaSheet(
                  steps: _allSteps,
                  resolved: const {},
                  onStep: (_) {},
                ),
              ),
              child: const Text('Go'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Go'));
  await tester.pumpAndSettle();
}

void main() {
  // fr is the worst case: its step titles and context lines are the longest.
  for (final locale in const [Locale('en'), Locale('fr')]) {
    final lang = locale.languageCode;

    for (final scale in const [1.0, 1.5, 2.0]) {
      testWidgets('the sheet has no overflow at ${scale}x ($lang)', (
        tester,
      ) async {
        await _openSheet(tester, scale: scale, locale: locale);
        expectNoOverflow(tester);
      });

      testWidgets('the primary action stays on screen at ${scale}x ($lang)', (
        tester,
      ) async {
        await _openSheet(tester, scale: scale, locale: locale);

        // A sheet that grows past the screen leaves its own call to action
        // below the bottom edge, where nothing can scroll it back into view.
        final cta = tester.getRect(find.byKey(CompleteFichaSheet.ctaKey));
        expect(
          cta.bottom,
          lessThanOrEqualTo(kPhoneSize.height + _epsilon),
          reason: 'the call to action sits below the bottom of the screen',
        );
        expect(
          cta.top,
          greaterThanOrEqualTo(-_epsilon),
          reason: 'the call to action sits above the top of the screen',
        );
      });

      testWidgets('the primary action can still be tapped at ${scale}x '
          '($lang)', (tester) async {
        await _openSheet(tester, scale: scale, locale: locale);

        // On screen is not enough: it also has to take the tap.
        await tester.tap(find.byKey(CompleteFichaSheet.ctaKey));
        await tester.pumpAndSettle();
      });
    }
  }
}
