import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oral_collector/features/recording/presentation/notifiers/recording_session_state.dart';
import 'package:oral_collector/features/recording/presentation/widgets/finalizing_overlay.dart';
import 'package:oral_collector/l10n/app_localizations.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(body: child),
  );
}

void main() {
  group('FinalizingOverlay loading states', () {
    testWidgets('shows finalizing text and spinner for finalizing stage', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          FinalizingOverlay(
            stage: FinalizationStage.finalizing,
            onDiscard: () {},
          ),
        ),
      );
      expect(find.text('Finalizing recording…'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows combining segments text for that stage', (tester) async {
      await tester.pumpWidget(
        _wrap(
          FinalizingOverlay(
            stage: FinalizationStage.combiningSegments,
            onDiscard: () {},
          ),
        ),
      );
      expect(find.text('Combining segments…'), findsOneWidget);
    });

    testWidgets('shows compressing audio text for that stage', (tester) async {
      await tester.pumpWidget(
        _wrap(
          FinalizingOverlay(
            stage: FinalizationStage.compressingAudio,
            onDiscard: () {},
          ),
        ),
      );
      expect(find.text('Compressing audio…'), findsOneWidget);
    });

    testWidgets('shows degraded hint when degraded is true', (tester) async {
      await tester.pumpWidget(
        _wrap(
          FinalizingOverlay(
            stage: FinalizationStage.compressingAudio,
            degraded: true,
            onDiscard: () {},
          ),
        ),
      );
      expect(find.text('Audio quality may be reduced.'), findsOneWidget);
    });

    testWidgets('does not show degraded hint when degraded is false', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          FinalizingOverlay(
            stage: FinalizationStage.finalizing,
            onDiscard: () {},
          ),
        ),
      );
      expect(find.text('Audio quality may be reduced.'), findsNothing);
    });
  });

  group('FinalizingOverlay error state', () {
    testWidgets('shows error title and body when error is set', (tester) async {
      await tester.pumpWidget(
        _wrap(
          FinalizingOverlay(
            stage: FinalizationStage.idle,
            error: 'No audio segments were saved.',
            onDiscard: () {},
          ),
        ),
      );
      expect(find.text("Couldn't save this recording"), findsOneWidget);
      expect(
        find.text(
          'We tried to recover the audio but no segments were available.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('hides spinner when error is set', (tester) async {
      await tester.pumpWidget(
        _wrap(
          FinalizingOverlay(
            stage: FinalizationStage.idle,
            error: 'fail',
            onDiscard: () {},
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows discard button when error is set', (tester) async {
      await tester.pumpWidget(
        _wrap(
          FinalizingOverlay(
            stage: FinalizationStage.idle,
            error: 'fail',
            onDiscard: () {},
          ),
        ),
      );
      expect(find.text('Discard and return'), findsOneWidget);
    });

    testWidgets('tapping discard button invokes onDiscard callback', (
      tester,
    ) async {
      var tapped = 0;
      await tester.pumpWidget(
        _wrap(
          FinalizingOverlay(
            stage: FinalizationStage.idle,
            error: 'fail',
            onDiscard: () => tapped++,
          ),
        ),
      );
      await tester.tap(find.text('Discard and return'));
      await tester.pump();
      expect(tapped, 1);
    });

    testWidgets('does not show discard button without error', (tester) async {
      await tester.pumpWidget(
        _wrap(
          FinalizingOverlay(
            stage: FinalizationStage.finalizing,
            onDiscard: () {},
          ),
        ),
      );
      expect(find.text('Discard and return'), findsNothing);
    });
  });
}
