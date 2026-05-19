import 'package:flutter_test/flutter_test.dart';

import 'package:oral_collector/features/recording/presentation/notifiers/recording_session_state.dart';

void main() {
  group('RecordingState finalization fields', () {
    test('default finalization fields', () {
      const state = RecordingState();
      expect(state.finalizationStage, FinalizationStage.idle);
      expect(state.finalizationError, isNull);
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

    test('copyWith updates finalizationError', () {
      const state = RecordingState();
      final updated = state.copyWith(finalizationError: 'oops');
      expect(updated.finalizationError, 'oops');
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
      const state = RecordingState(finalizationError: 'failure');
      final updated = state.copyWith(clearFinalizationError: true);
      expect(updated.finalizationError, isNull);
    });

    test(
      'copyWith without explicit fields keeps existing finalizationError',
      () {
        const state = RecordingState(finalizationError: 'failure');
        final updated = state.copyWith(isRecording: true);
        expect(updated.finalizationError, 'failure');
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
  });
}
