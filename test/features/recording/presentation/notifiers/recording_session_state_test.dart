import 'package:flutter_test/flutter_test.dart';

import 'package:oral_collector/features/recording/presentation/notifiers/recording_session_state.dart';

void main() {
  group('RecordingState finalization fields', () {
    test('default finalization fields', () {
      const state = RecordingState();
      expect(state.finalizationStage, FinalizationStage.idle);
      expect(state.finalizationErrorKind, isNull);
      expect(state.hasFinalizationError, isFalse);
      expect(state.finalizationDegraded, isFalse);
      expect(state.isFinalizing, isFalse);
    });

    test('isFinalizing is true for finalizing stage', () {
      const state = RecordingState(
        finalizationStage: FinalizationStage.finalizing,
      );
      expect(state.isFinalizing, isTrue);
    });

    test('isFinalizing is true for combiningSegments stage', () {
      const state = RecordingState(
        finalizationStage: FinalizationStage.combiningSegments,
      );
      expect(state.isFinalizing, isTrue);
    });

    test('isFinalizing is true for compressingAudio stage', () {
      const state = RecordingState(
        finalizationStage: FinalizationStage.compressingAudio,
      );
      expect(state.isFinalizing, isTrue);
    });

    test('isFinalizing is false for idle stage', () {
      const state = RecordingState(finalizationStage: FinalizationStage.idle);
      expect(state.isFinalizing, isFalse);
    });

    test('copyWith updates finalizationStage', () {
      const state = RecordingState();
      final updated = state.copyWith(
        finalizationStage: FinalizationStage.combiningSegments,
      );
      expect(updated.finalizationStage, FinalizationStage.combiningSegments);
    });

    test('copyWith updates finalizationErrorKind', () {
      const state = RecordingState();
      final updated = state.copyWith(
        finalizationErrorKind: FinalizationErrorKind.noSegments,
      );
      expect(updated.finalizationErrorKind, FinalizationErrorKind.noSegments);
      expect(updated.hasFinalizationError, isTrue);
    });

    test('copyWith updates finalizationDegraded', () {
      const state = RecordingState();
      final updated = state.copyWith(finalizationDegraded: true);
      expect(updated.finalizationDegraded, isTrue);
    });

    test('copyWith preserves existing finalizationStage when not passed', () {
      const state = RecordingState(
        finalizationStage: FinalizationStage.compressingAudio,
      );
      final updated = state.copyWith(isRecording: false);
      expect(updated.finalizationStage, FinalizationStage.compressingAudio);
    });

    test('copyWith clearFinalizationError nulls out the error', () {
      const state = RecordingState(
        finalizationErrorKind: FinalizationErrorKind.noSegments,
      );
      final updated = state.copyWith(clearFinalizationError: true);
      expect(updated.finalizationErrorKind, isNull);
      expect(updated.hasFinalizationError, isFalse);
    });

    test(
      'copyWith without explicit fields keeps existing finalizationErrorKind',
      () {
        const state = RecordingState(
          finalizationErrorKind: FinalizationErrorKind.downloadFailed,
        );
        final updated = state.copyWith(isRecording: true);
        expect(
          updated.finalizationErrorKind,
          FinalizationErrorKind.downloadFailed,
        );
      },
    );

    test('finalization fields do not affect unrelated copyWith calls', () {
      const state = RecordingState(
        isRecording: true,
        finalizationStage: FinalizationStage.finalizing,
        finalizationDegraded: true,
      );
      final updated = state.copyWith(isPaused: true);
      expect(updated.isRecording, isTrue);
      expect(updated.isPaused, isTrue);
      expect(updated.finalizationStage, FinalizationStage.finalizing);
      expect(updated.finalizationDegraded, isTrue);
    });

    test(
      'stop→finalize transition keeps elapsed visible for the saving overlay',
      () {
        // Mirrors stopRecording's state mutation: isRecording flips off and
        // finalizationStage moves to finalizing. The recording_step UI reads
        // state.elapsed to render the duration label on the saving overlay,
        // so a Duration.zero leak here surfaces as a 00:00:00 timer.
        const recording = RecordingState(
          isRecording: true,
          elapsed: Duration(seconds: 30),
        );
        final finalizing = recording.copyWith(
          isRecording: false,
          isPaused: false,
          finalizationStage: FinalizationStage.finalizing,
        );
        expect(finalizing.elapsed, const Duration(seconds: 30));
        expect(finalizing.isFinalizing, isTrue);
      },
    );
  });

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
