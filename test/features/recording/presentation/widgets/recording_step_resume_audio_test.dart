// Regression test for ENG-80 ("resume with dead mic").
//
// When the app returns to the foreground during an active recording, the audio
// session must be re-activated. The engine synthesizes intermediate states, so
// the real return path is `paused → hidden → inactive → resumed`: the state
// immediately before `resumed` is ALWAYS `inactive`, never `paused`. The old
// `previous == paused` check therefore never fired on Android 14+, leaving the
// mic dead. We only re-activate (and show the "continued in background" banner)
// when the app actually went to background (passed through `hidden`/`paused`),
// not on a transient `inactive` blip (e.g. iOS control center).
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/input_device_notifier.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recording_session_notifier.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recording_session_state.dart';
import 'package:oral_collector/features/recording/presentation/widgets/recording_step.dart';
import 'package:oral_collector/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _bannerText = 'Recording continued in background';

class _SpyRecordingSessionNotifier extends RecordingSessionNotifier {
  _SpyRecordingSessionNotifier(this._initial);
  final RecordingState _initial;
  int _reactivateCount = 0;

  @override
  RecordingState build() => _initial;

  // Overridden so the test never touches the native audio_session plugin;
  // we only record that the widget asked for a re-activation.
  @override
  Future<void> reactivateAudioSession() async {
    _reactivateCount++;
  }
}

class _FakeInputDeviceNotifier extends InputDeviceNotifier {
  @override
  InputDeviceState build() => const InputDeviceState();

  @override
  Future<void> refresh() async {}
}

Widget _harness(_SpyRecordingSessionNotifier spy) {
  return ProviderScope(
    overrides: [
      recordingSessionNotifierProvider.overrideWith(() => spy),
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

// Drives lifecycle states through the binding. We step through adjacent states
// to mirror real device ordering; `handleAppLifecycleStateChanged` only
// notifies observers, so non-adjacent jumps would not throw here either.
void _drive(WidgetTester tester, List<AppLifecycleState> states) {
  for (final state in states) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
}

// Baseline resumed, then the full background round-trip as produced on
// Android 14+/modern Flutter. The return half (…→ inactive → resumed) is the
// part the old `previous == paused` check got wrong.
const _backgroundRoundTrip = <AppLifecycleState>[
  AppLifecycleState.resumed, // baseline
  AppLifecycleState.inactive,
  AppLifecycleState.hidden,
  AppLifecycleState.paused,
  AppLifecycleState.hidden,
  AppLifecycleState.inactive,
  AppLifecycleState.resumed, // back to foreground
];

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // RecordingStep at isRecording renders a tall Column; give it room so an
    // overflow doesn't mask the real assertion.
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(
      400 * 3.0,
      1200 * 3.0,
    );
    binding.platformDispatcher.views.first.devicePixelRatio = 3.0;
  });

  tearDown(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.resetPhysicalSize();
    binding.platformDispatcher.views.first.resetDevicePixelRatio();
  });

  testWidgets(
    'reactivates audio session and shows banner when resuming from background '
    'while recording',
    (tester) async {
      final spy = _SpyRecordingSessionNotifier(
        const RecordingState(isRecording: true),
      );
      await tester.pumpWidget(_harness(spy));
      await tester.pump();

      _drive(tester, _backgroundRoundTrip);
      await tester.pump();

      expect(spy._reactivateCount, 1);
      expect(find.text(_bannerText), findsOneWidget);

      // Unmount to cancel the 3s banner timer via dispose.
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    },
  );

  testWidgets(
    'does NOT reactivate or show banner on a transient inactive blip',
    (tester) async {
      final spy = _SpyRecordingSessionNotifier(
        const RecordingState(isRecording: true),
      );
      await tester.pumpWidget(_harness(spy));
      await tester.pump();

      _drive(tester, const [
        AppLifecycleState.resumed,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]);
      await tester.pump();

      expect(spy._reactivateCount, 0);
      expect(find.text(_bannerText), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    },
  );

  testWidgets('does NOT reactivate when not recording', (tester) async {
    final spy = _SpyRecordingSessionNotifier(
      const RecordingState(isRecording: false),
    );
    await tester.pumpWidget(_harness(spy));
    await tester.pump();

    _drive(tester, _backgroundRoundTrip);
    await tester.pump();

    expect(spy._reactivateCount, 0);
    expect(find.text(_bannerText), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('re-arms: reactivates again on a second background round-trip', (
    tester,
  ) async {
    final spy = _SpyRecordingSessionNotifier(
      const RecordingState(isRecording: true),
    );
    await tester.pumpWidget(_harness(spy));
    await tester.pump();

    _drive(tester, _backgroundRoundTrip);
    await tester.pump();
    expect(spy._reactivateCount, 1);

    _drive(tester, _backgroundRoundTrip);
    await tester.pump();
    expect(spy._reactivateCount, 2);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
