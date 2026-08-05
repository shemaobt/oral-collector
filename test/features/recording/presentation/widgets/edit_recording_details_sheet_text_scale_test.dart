// ENG-179: the edit-details bottom sheet must survive a large system font.
// The sheet renders in the app Overlay, so the textScaler is applied at the
// MaterialApp.builder level (above the Navigator) instead of via the home body.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/recording/presentation/widgets/edit_recording_details_sheet.dart';
import 'package:oral_collector/l10n/app_localizations.dart';

import '../../../../support/text_scale.dart';

Future<void> _openSheetAtScale(WidgetTester tester, double scale) async {
  tester.view.physicalSize = kPhoneSize * 3.0;
  tester.view.devicePixelRatio = 3.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
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
              onPressed: () => showEditRecordingDetailsSheet(
                context,
                initialTitle: 'A recording title that is reasonably long',
                initialDescription: 'A description spanning a few words here',
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
  for (final scale in const [1.0, 1.3, 2.0]) {
    testWidgets('edit-details sheet has no overflow at ${scale}x', (
      tester,
    ) async {
      await _openSheetAtScale(tester, scale);
      expectNoOverflow(tester);
    });
  }
}
