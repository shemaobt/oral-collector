import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:oral_collector/features/recording/presentation/notifiers/input_device_notifier.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recording_session_notifier.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recording_session_state.dart';
import 'package:oral_collector/features/recording/presentation/widgets/finalizing_overlay.dart';
import 'package:oral_collector/features/recording/presentation/widgets/finalizing_status_card.dart';
import 'package:oral_collector/features/recording/presentation/widgets/finalizing_waveform.dart';
import 'package:oral_collector/features/recording/presentation/widgets/recording_step.dart';
import 'package:oral_collector/features/recording/presentation/widgets/saving_recording_label.dart';
import 'package:oral_collector/l10n/app_localizations.dart';

class _MutableRecordingSessionNotifier extends RecordingSessionNotifier {
  _MutableRecordingSessionNotifier(this._initial);
  final RecordingState _initial;

  @override
  RecordingState build() => _initial;

  void setStateForTest(RecordingState newState) {
    state = newState;
  }
}

class _FakeInputDeviceNotifier extends InputDeviceNotifier {
  @override
  InputDeviceState build() => const InputDeviceState();

  @override
  Future<void> refresh() async {}
}

Widget _wrap({
  required RecordingState state,
  _MutableRecordingSessionNotifier? notifier,
}) {
  final notif = notifier ?? _MutableRecordingSessionNotifier(state);
  return ProviderScope(
    overrides: [
      recordingSessionNotifierProvider.overrideWith(() => notif),
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

  testWidgets('does not show finalization UI in idle state', (tester) async {
    await tester.pumpWidget(_wrap(state: const RecordingState()));
    await tester.pump();
    expect(find.byType(SavingRecordingLabel), findsNothing);
    expect(find.byType(FinalizingStatusCard), findsNothing);
    expect(find.byType(FinalizingWaveform), findsNothing);
    expect(find.byType(FinalizingOverlay), findsNothing);
  });

  testWidgets('shows inline finalization UI when state is finalizing', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        state: const RecordingState(
          finalizationStage: FinalizationStage.finalizing,
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(SavingRecordingLabel), findsOneWidget);
    expect(find.byType(FinalizingWaveform), findsOneWidget);
    expect(find.byType(FinalizingStatusCard), findsOneWidget);
    // Error overlay should NOT be shown during normal finalization.
    expect(find.byType(FinalizingOverlay), findsNothing);
  });

  testWidgets('shows "Saving recording…" label while finalizing', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        state: const RecordingState(
          finalizationStage: FinalizationStage.combiningSegments,
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Saving recording…'), findsOneWidget);
  });

  testWidgets('status card shows the current stage tag', (tester) async {
    await tester.pumpWidget(
      _wrap(
        state: const RecordingState(
          finalizationStage: FinalizationStage.compressingAudio,
        ),
      ),
    );
    await tester.pump();
    expect(find.text('COMPRESSING'), findsOneWidget);
    expect(find.text('Processing your audio'), findsOneWidget);
  });

  testWidgets('status card shows reassurance copy', (tester) async {
    await tester.pumpWidget(
      _wrap(
        state: const RecordingState(
          finalizationStage: FinalizationStage.finalizing,
        ),
      ),
    );
    await tester.pump();
    expect(
      find.text("Don't close — we'll open the save screen next."),
      findsOneWidget,
    );
  });

  testWidgets('status card swaps to degraded hint when recovery happened', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        state: const RecordingState(
          finalizationStage: FinalizationStage.finalizing,
          finalizationDegraded: true,
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Audio quality may be reduced.'), findsOneWidget);
    expect(
      find.text("Don't close — we'll open the save screen next."),
      findsNothing,
    );
  });

  testWidgets('shows error overlay when finalizationError is set', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        state: const RecordingState(
          finalizationErrorKind: FinalizationErrorKind.noSegments,
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(FinalizingOverlay), findsOneWidget);
    expect(find.text("Couldn't save this recording"), findsOneWidget);
    // Inline finalization widgets should NOT render in error state.
    expect(find.byType(SavingRecordingLabel), findsNothing);
    expect(find.byType(FinalizingStatusCard), findsNothing);
  });

  testWidgets('inline UI appears when state transitions idle → finalizing', (
    tester,
  ) async {
    final notifier = _MutableRecordingSessionNotifier(const RecordingState());
    await tester.pumpWidget(
      _wrap(state: const RecordingState(), notifier: notifier),
    );
    await tester.pump();
    expect(find.byType(FinalizingStatusCard), findsNothing);

    notifier.setStateForTest(
      const RecordingState(finalizationStage: FinalizationStage.finalizing),
    );
    await tester.pump();
    expect(find.byType(FinalizingStatusCard), findsOneWidget);
  });

  testWidgets('inline UI dismisses when state transitions finalizing → idle', (
    tester,
  ) async {
    final notifier = _MutableRecordingSessionNotifier(
      const RecordingState(finalizationStage: FinalizationStage.finalizing),
    );
    await tester.pumpWidget(
      _wrap(
        state: const RecordingState(
          finalizationStage: FinalizationStage.finalizing,
        ),
        notifier: notifier,
      ),
    );
    await tester.pump();
    expect(find.byType(FinalizingStatusCard), findsOneWidget);

    notifier.setStateForTest(const RecordingState());
    await tester.pump();
    expect(find.byType(FinalizingStatusCard), findsNothing);
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

    final popScope = tester.widget<PopScope>(find.byType(PopScope).first);
    expect(popScope.canPop, isFalse);
  });

  testWidgets('blocks back navigation while error overlay is up', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        state: const RecordingState(
          finalizationErrorKind: FinalizationErrorKind.noSegments,
        ),
      ),
    );
    await tester.pump();
    final popScope = tester.widget<PopScope>(find.byType(PopScope).first);
    expect(popScope.canPop, isFalse);
  });

  testWidgets('allows back navigation when idle', (tester) async {
    await tester.pumpWidget(_wrap(state: const RecordingState()));
    await tester.pump();
    final popScope = tester.widget<PopScope>(find.byType(PopScope).first);
    expect(popScope.canPop, isTrue);
  });
}
