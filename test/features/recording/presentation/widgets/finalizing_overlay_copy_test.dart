import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recording_session_state.dart';
import 'package:oral_collector/features/recording/presentation/widgets/finalizing_overlay.dart';
import 'package:oral_collector/l10n/app_localizations.dart';

Future<void> pumpOverlay(WidgetTester tester, FinalizationErrorKind kind) {
  return tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: FinalizingOverlay(
          stage: FinalizationStage.idle,
          hasError: true,
          errorKind: kind,
          onDiscard: () {},
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'the browser ending capture is not described as missing segments',
    (tester) async {
      await pumpOverlay(tester, FinalizationErrorKind.captureInterrupted);

      expect(
        find.text(
          'We tried to recover the audio but no segments were available.',
        ),
        findsNothing,
        reason:
            'there are no segments in a browser; this copy promises a recovery '
            'that cannot happen there',
      );
      expect(
        find.text(
          'Recording stopped before you pressed stop, so no audio was kept.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('audio that could not be read back says so', (tester) async {
    await pumpOverlay(tester, FinalizationErrorKind.downloadFailed);

    expect(
      find.text(
        'We tried to recover the audio but no segments were available.',
      ),
      findsNothing,
    );
    expect(
      find.text('The audio was recorded but could not be read back.'),
      findsOneWidget,
    );
  });

  testWidgets('storage refusing the audio is not blamed on reading it', (
    tester,
  ) async {
    await pumpOverlay(tester, FinalizationErrorKind.storageUnavailable);

    expect(
      find.text('The audio was recorded but could not be read back.'),
      findsNothing,
      reason:
          'the read succeeded and the write was refused; this copy sends the '
          'person looking in the wrong place',
    );
    expect(
      find.text(
        "We couldn't finish processing this recording. It is kept in your "
        'unsaved recordings.',
      ),
      findsNothing,
      reason: 'nothing was kept — the write is what failed',
    );
    expect(
      find.text('Something went wrong. Please try again later.'),
      findsOneWidget,
    );
  });

  testWidgets('the browser producing no audio at all says so', (tester) async {
    await pumpOverlay(tester, FinalizationErrorKind.noAudio);

    expect(
      find.text(
        'We tried to recover the audio but no segments were available.',
      ),
      findsNothing,
    );
    expect(find.text('No audio came back from the recorder.'), findsOneWidget);
  });

  testWidgets(
    'a pipeline failure points at the unsaved list, where the audio still is',
    (tester) async {
      await pumpOverlay(tester, FinalizationErrorKind.finalizationFailed);

      expect(
        find.text(
          "We couldn't finish processing this recording. It is kept in your "
          'unsaved recordings.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('the segment wording survives where it is actually true', (
    tester,
  ) async {
    await pumpOverlay(tester, FinalizationErrorKind.noSegments);

    expect(
      find.text(
        'We tried to recover the audio but no segments were available.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('the only action does not claim to discard anything', (
    tester,
  ) async {
    await pumpOverlay(tester, FinalizationErrorKind.captureInterrupted);

    expect(
      find.text('Discard and return'),
      findsNothing,
      reason:
          'dismissing only clears the error — it deletes nothing, and telling '
          'someone they are discarding 18 minutes is worse than untrue',
    );
    expect(find.text('Back'), findsOneWidget);
  });
}
