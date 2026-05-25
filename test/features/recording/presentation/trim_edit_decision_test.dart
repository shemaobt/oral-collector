import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/recording/presentation/trim_edit_decision.dart';

void main() {
  group('TrimEditDecision', () {
    const oneMinute = Duration(minutes: 1);

    test('not saveable when nothing was edited', () {
      final decision = TrimEditDecision(
        splitPoints: const [],
        excludedSegments: const {},
        gainDb: 0.0,
        totalDuration: oneMinute,
      );

      expect(decision.canSave, isFalse);
    });

    test('saveable when only the volume changed', () {
      final decision = TrimEditDecision(
        splitPoints: const [],
        excludedSegments: const {},
        gainDb: 3.0,
        totalDuration: oneMinute,
      );

      expect(decision.canSave, isTrue);
      expect(decision.mode, TrimSaveMode.boostOnly);
    });

    test('saveable when only splits were added', () {
      final decision = TrimEditDecision(
        splitPoints: const [0.5],
        excludedSegments: const {},
        gainDb: 0.0,
        totalDuration: oneMinute,
      );

      expect(decision.canSave, isTrue);
      expect(decision.mode, TrimSaveMode.split);
    });

    test('saveable when splits and gain change happen together', () {
      final decision = TrimEditDecision(
        splitPoints: const [0.3, 0.7],
        excludedSegments: const {},
        gainDb: -4.0,
        totalDuration: oneMinute,
      );

      expect(decision.canSave, isTrue);
      expect(decision.mode, TrimSaveMode.split);
    });

    test('not saveable when every split segment was excluded', () {
      final decision = TrimEditDecision(
        splitPoints: const [0.5],
        excludedSegments: const {0, 1},
        gainDb: 0.0,
        totalDuration: oneMinute,
      );

      expect(decision.canSave, isFalse);
    });

    test('keptCount reflects the number of surviving segments', () {
      final decision = TrimEditDecision(
        splitPoints: const [0.25, 0.5, 0.75],
        excludedSegments: const {1},
        gainDb: 0.0,
        totalDuration: oneMinute,
      );

      expect(decision.keptCount, 3);
      expect(decision.canSave, isTrue);
    });

    test(
      'boost-only mode produces a single virtual segment covering full audio',
      () {
        final decision = TrimEditDecision(
          splitPoints: const [],
          excludedSegments: const {},
          gainDb: 5.0,
          totalDuration: oneMinute,
        );

        final segments = decision.segments;

        expect(segments, hasLength(1));
        expect(segments.single.startSeconds, 0.0);
        expect(segments.single.endSeconds, 60.0);
        expect(segments.single.gainDb, 5.0);
      },
    );

    test('split mode emits one segment per kept slice with applied gain', () {
      final decision = TrimEditDecision(
        splitPoints: const [0.5],
        excludedSegments: const {},
        gainDb: 2.0,
        totalDuration: oneMinute,
      );

      final segments = decision.segments;

      expect(segments, hasLength(2));
      expect(segments[0].startSeconds, closeTo(0.0, 0.001));
      expect(segments[0].endSeconds, closeTo(30.0, 0.001));
      expect(segments[0].gainDb, 2.0);
      expect(segments[1].startSeconds, closeTo(30.0, 0.001));
      expect(segments[1].endSeconds, closeTo(60.0, 0.001));
      expect(segments[1].gainDb, 2.0);
    });

    test('excluded segments do not appear in the output list', () {
      final decision = TrimEditDecision(
        splitPoints: const [0.25, 0.75],
        excludedSegments: const {1},
        gainDb: 0.0,
        totalDuration: oneMinute,
      );

      final segments = decision.segments;

      expect(segments, hasLength(2));
      expect(segments[0].endSeconds, closeTo(15.0, 0.001));
      expect(segments[1].startSeconds, closeTo(45.0, 0.001));
    });

    test('negative gain inside the deadzone is treated as unchanged', () {
      final decision = TrimEditDecision(
        splitPoints: const [],
        excludedSegments: const {},
        gainDb: -0.005,
        totalDuration: oneMinute,
      );

      expect(decision.canSave, isFalse);
    });

    test(
      'gain exactly equal to the deadzone threshold is treated as no change',
      () {
        final decision = TrimEditDecision(
          splitPoints: const [],
          excludedSegments: const {},
          gainDb: 0.01,
          totalDuration: oneMinute,
        );

        expect(decision.canSave, isFalse);
      },
    );

    test('audio exactly at minimum duration is still too short', () {
      final decision = TrimEditDecision(
        splitPoints: const [],
        excludedSegments: const {},
        gainDb: 6.0,
        totalDuration: const Duration(milliseconds: 200),
      );

      expect(decision.canSave, isFalse);
    });

    test('unsorted split points still produce sliced segments in order', () {
      final decision = TrimEditDecision(
        splitPoints: const [0.75, 0.25],
        excludedSegments: const {},
        gainDb: 0.0,
        totalDuration: oneMinute,
      );

      final segments = decision.segments;

      expect(segments, hasLength(3));
      expect(segments[0].startSeconds, closeTo(0.0, 0.001));
      expect(segments[0].endSeconds, closeTo(15.0, 0.001));
      expect(segments[1].startSeconds, closeTo(15.0, 0.001));
      expect(segments[1].endSeconds, closeTo(45.0, 0.001));
      expect(segments[2].startSeconds, closeTo(45.0, 0.001));
      expect(segments[2].endSeconds, closeTo(60.0, 0.001));
    });
  });
}
