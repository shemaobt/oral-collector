import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:oral_collector/features/recording/presentation/notifiers/input_device_notifier.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recording_session_notifier.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recording_session_state.dart';
import 'package:oral_collector/features/recording/presentation/widgets/finalizing_overlay.dart';
import 'package:oral_collector/features/recording/presentation/widgets/recording_step.dart';
import 'package:oral_collector/l10n/app_localizations.dart';

class _FakeRecordingSessionNotifier extends RecordingSessionNotifier {
  _FakeRecordingSessionNotifier(this._initial);
  final RecordingState _initial;

  @override
  RecordingState build() => _initial;
}

class _FakeInputDeviceNotifier extends InputDeviceNotifier {
  @override
  InputDeviceState build() => const InputDeviceState();

  @override
  Future<void> refresh() async {}
}

Widget _wrap({required RecordingState state}) {
  return ProviderScope(
    overrides: [
      recordingSessionNotifierProvider.overrideWith(
        () => _FakeRecordingSessionNotifier(state),
      ),
      inputDeviceNotifierProvider.overrideWith(_FakeInputDeviceNotifier.new),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: RecordingStep(
          genreId: 'g1',
          subcategoryId: 's1',
          genreName: 'Genre',
          subcategoryName: 'Sub',
          onRecordingComplete: (_) {},
        ),
      ),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('renders FinalizingOverlay when isFinalizing is true', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        state: const RecordingState(
          isRecording: false,
          finalizationStage: FinalizationStage.finalizing,
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(FinalizingOverlay), findsOneWidget);
    expect(find.text('Finalizing recording…'), findsOneWidget);
  });

  testWidgets('renders FinalizingOverlay with combining text', (tester) async {
    await tester.pumpWidget(
      _wrap(
        state: const RecordingState(
          isRecording: false,
          finalizationStage: FinalizationStage.combiningSegments,
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Combining segments…'), findsOneWidget);
  });

  testWidgets('does not render FinalizingOverlay when stage is idle', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(state: const RecordingState()));
    await tester.pump();
    expect(find.byType(FinalizingOverlay), findsNothing);
  });

  testWidgets('renders FinalizingOverlay when finalizationError is set', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(state: const RecordingState(finalizationError: 'No segments')),
    );
    await tester.pump();
    expect(find.byType(FinalizingOverlay), findsOneWidget);
    expect(find.text("Couldn't save this recording"), findsOneWidget);
  });

  testWidgets('blocks back navigation while finalizing', (tester) async {
    await tester.pumpWidget(
      _wrap(
        state: const RecordingState(
          finalizationStage: FinalizationStage.compressingAudio,
        ),
      ),
    );
    await tester.pump();

    final popScope = tester.widget<PopScope>(find.byType(PopScope));
    expect(popScope.canPop, isFalse);
  });

  testWidgets('allows back navigation when idle', (tester) async {
    await tester.pumpWidget(_wrap(state: const RecordingState()));
    await tester.pump();

    final popScope = tester.widget<PopScope>(find.byType(PopScope));
    expect(popScope.canPop, isTrue);
  });
}
