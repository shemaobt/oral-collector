import 'package:flutter_test/flutter_test.dart';

import 'package:oral_collector/features/recording/presentation/notifiers/recording_session_state.dart';

void main() {
  group('RecordingState.isInProgress', () {
    test('is false on a freshly constructed state', () {
      const state = RecordingState();

      expect(state.isInProgress, isFalse);
    });

    test('is true when recording is active and not paused', () {
      const state = RecordingState(isRecording: true);

      expect(state.isInProgress, isTrue);
    });

    test('is true when recording is active and paused', () {
      const state = RecordingState(isRecording: true, isPaused: true);

      expect(state.isInProgress, isTrue);
    });

    test('is true when only the paused flag is set', () {
      const state = RecordingState(isPaused: true);

      expect(state.isInProgress, isTrue);
    });
  });
}
