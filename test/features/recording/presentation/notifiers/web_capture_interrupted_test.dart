import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/input_device_notifier.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recording_session_notifier.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/recording_session_state.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockAudioRecorder extends Mock implements AudioRecorder {}

class _FakeRecordConfig extends Fake implements RecordConfig {}

class _FakeInputDeviceNotifier extends InputDeviceNotifier {
  @override
  InputDeviceState build() => const InputDeviceState();

  @override
  Future<void> refresh() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(_FakeRecordConfig());
    registerFallbackValue(Duration.zero);
  });

  late _MockAudioRecorder recorder;
  late StreamController<RecordState> recorderState;
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    recorder = _MockAudioRecorder();
    recorderState = StreamController<RecordState>.broadcast();

    when(() => recorder.hasPermission()).thenAnswer((_) async => true);
    when(
      () => recorder.start(any(), path: any(named: 'path')),
    ).thenAnswer((_) async {});
    when(
      () => recorder.onAmplitudeChanged(any()),
    ).thenAnswer((_) => const Stream<Amplitude>.empty());
    when(
      () => recorder.onStateChanged(),
    ).thenAnswer((_) => recorderState.stream);
    when(() => recorder.stop()).thenAnswer((_) async => null);
    when(() => recorder.dispose()).thenAnswer((_) async {});

    container = ProviderContainer(
      overrides: [
        isWebPlatformProvider.overrideWithValue(true),
        webAudioRecorderFactoryProvider.overrideWithValue(() => recorder),
        inputDeviceNotifierProvider.overrideWith(_FakeInputDeviceNotifier.new),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await recorderState.close();
  });

  RecordingState state() => container.read(recordingSessionNotifierProvider);

  Future<void> startRecording() async {
    final ok = await container
        .read(recordingSessionNotifierProvider.notifier)
        .startRecording('genre-1', 'sub-1');
    expect(ok, isTrue);
    expect(state().isRecording, isTrue);
  }

  test('ENG-408: when the browser ends capture on its own, the person is told '
      'right away instead of at stop', () async {
    await startRecording();

    // Something took the microphone: the MediaRecorder leaves the recording
    // state without anyone pressing stop.
    recorderState.add(RecordState.stop);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(
      state().isRecording,
      isFalse,
      reason: 'the session is over whether the app noticed it or not',
    );
    expect(
      state().finalizationErrorKind,
      FinalizationErrorKind.captureInterrupted,
      reason: 'the person must learn this now, not 18 minutes later',
    );
  });

  test(
    'ENG-408: the elapsed counter stops counting once capture is gone',
    () async {
      await startRecording();
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      expect(
        state().elapsed,
        greaterThan(Duration.zero),
        reason: 'the counter runs while capture is live',
      );

      recorderState.add(RecordState.stop);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final frozenAt = state().elapsed;

      await Future<void>.delayed(const Duration(milliseconds: 1200));

      expect(
        state().elapsed,
        frozenAt,
        reason:
            'a counter that keeps climbing over a dead microphone is the '
            'reason someone recorded 18 minutes of nothing',
      );
    },
  );

  test('a recorder that pauses or resumes is not an interruption', () async {
    await startRecording();

    recorderState
      ..add(RecordState.pause)
      ..add(RecordState.record);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(state().isRecording, isTrue);
    expect(state().finalizationErrorKind, isNull);
  });

  test(
    'the stop the user asked for is not reported as an interruption',
    () async {
      await startRecording();

      final stopping = container
          .read(recordingSessionNotifierProvider.notifier)
          .stopRecording();
      // record emits the same stop event for a solicited stop.
      recorderState.add(RecordState.stop);
      await stopping;
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(
        state().finalizationErrorKind,
        FinalizationErrorKind.noAudio,
        reason:
            'this recorder produced no blob; that is the honest kind, and the '
            'interruption watcher must not overwrite it',
      );
    },
  );
}
