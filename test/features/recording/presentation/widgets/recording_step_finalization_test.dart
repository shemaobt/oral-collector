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

  /// Pump enough frames for the listener-triggered showDialog to mount the
  /// overlay, without using pumpAndSettle (which hangs on the spinner anim).
  Future<void> settleOverlay(WidgetTester tester) async {
    await tester.pump(); // build
    await tester.pump(); // post-frame callback / showDialog
    await tester.pump(const Duration(milliseconds: 250)); // dialog transition
    await tester.pump(const Duration(milliseconds: 250));
  }

  testWidgets('does not show overlay when stage is idle', (tester) async {
    await tester.pumpWidget(_wrap(state: const RecordingState()));
    await settleOverlay(tester);
    expect(find.byType(FinalizingOverlay), findsNothing);
  });

  testWidgets('shows FinalizingOverlay when initial stage is finalizing', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        state: const RecordingState(
          finalizationStage: FinalizationStage.finalizing,
        ),
      ),
    );
    await settleOverlay(tester);
    expect(find.byType(FinalizingOverlay), findsOneWidget);
    expect(find.text('Finalizing recording…'), findsOneWidget);
  });

  testWidgets('shows FinalizingOverlay with combining text', (tester) async {
    await tester.pumpWidget(
      _wrap(
        state: const RecordingState(
          finalizationStage: FinalizationStage.combiningSegments,
        ),
      ),
    );
    await settleOverlay(tester);
    expect(find.text('Combining segments…'), findsOneWidget);
  });

  testWidgets('shows error variant when finalizationError is set', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(state: const RecordingState(finalizationError: 'No segments')),
    );
    await settleOverlay(tester);
    expect(find.byType(FinalizingOverlay), findsOneWidget);
    expect(find.text("Couldn't save this recording"), findsOneWidget);
  });

  testWidgets('overlay appears when state transitions idle → finalizing', (
    tester,
  ) async {
    final notifier = _MutableRecordingSessionNotifier(const RecordingState());
    await tester.pumpWidget(
      _wrap(state: const RecordingState(), notifier: notifier),
    );
    await settleOverlay(tester);
    expect(find.byType(FinalizingOverlay), findsNothing);

    notifier.setStateForTest(
      const RecordingState(finalizationStage: FinalizationStage.finalizing),
    );
    await settleOverlay(tester);
    expect(find.byType(FinalizingOverlay), findsOneWidget);
  });

  testWidgets('overlay dismisses when state transitions finalizing → idle', (
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
    await settleOverlay(tester);
    expect(find.byType(FinalizingOverlay), findsOneWidget);

    notifier.setStateForTest(const RecordingState());
    await settleOverlay(tester);
    expect(find.byType(FinalizingOverlay), findsNothing);
  });

  testWidgets(
    'overlay updates text when stage changes finalizing → combining',
    (tester) async {
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
      await settleOverlay(tester);
      expect(find.text('Finalizing recording…'), findsOneWidget);

      notifier.setStateForTest(
        const RecordingState(
          finalizationStage: FinalizationStage.combiningSegments,
        ),
      );
      await settleOverlay(tester);
      expect(find.text('Combining segments…'), findsOneWidget);
      expect(find.text('Finalizing recording…'), findsNothing);
    },
  );

  testWidgets('overlay is rendered as a modal route blocking back navigation', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        state: const RecordingState(
          finalizationStage: FinalizationStage.compressingAudio,
        ),
      ),
    );
    await settleOverlay(tester);

    expect(find.byType(FinalizingOverlay), findsOneWidget);

    // PopScope wrapping the overlay (ancestor) must have canPop:false so the
    // system back gesture cannot dismiss the dialog.
    final popScopeAncestor = find.ancestor(
      of: find.byType(FinalizingOverlay),
      matching: find.byType(PopScope),
    );
    expect(popScopeAncestor, findsAtLeastNWidgets(1));
    final popScope = tester.widget<PopScope>(popScopeAncestor.first);
    expect(popScope.canPop, isFalse);
  });

  testWidgets(
    'overlay is hosted in a modal route (covers any siblings in stack)',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          state: const RecordingState(
            finalizationStage: FinalizationStage.finalizing,
          ),
        ),
      );
      await settleOverlay(tester);

      // showDialog inserts a ModalBarrier above the underlying route.
      // We assert the overlay's ModalRoute differs from the host scaffold's.
      final overlayElement = tester.element(find.byType(FinalizingOverlay));
      final scaffoldElement = tester.element(find.byType(Scaffold).first);

      expect(ModalRoute.of(overlayElement), isNotNull);
      expect(ModalRoute.of(scaffoldElement), isNotNull);
      expect(
        ModalRoute.of(overlayElement),
        isNot(equals(ModalRoute.of(scaffoldElement))),
        reason:
            'FinalizingOverlay must be on a dialog route, not the underlying scaffold route',
      );
    },
  );
}
