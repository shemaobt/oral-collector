import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/recording/presentation/trim_edit_decision.dart';

void main() {
  group('TrimEditDecision', () {
    const oneMinute = Duration(minutes: 1);

    test('not saveable when nothing was edited', () {
      final decision = const TrimEditDecision(
        splitPoints: [],
        excludedSegments: {},
        gainDb: 0.0,
        totalDuration: oneMinute,
      );

      expect(decision.canSave, isFalse);
    });

    test('saveable when only the volume changed', () {
      final decision = const TrimEditDecision(
        splitPoints: [],
        excludedSegments: {},
        gainDb: 3.0,
        totalDuration: oneMinute,
      );

      expect(decision.canSave, isTrue);
      expect(decision.mode, TrimSaveMode.boostOnly);
    });

    test('saveable when only splits were added', () {
      final decision = const TrimEditDecision(
        splitPoints: [0.5],
        excludedSegments: {},
        gainDb: 0.0,
        totalDuration: oneMinute,
      );

      expect(decision.canSave, isTrue);
      expect(decision.mode, TrimSaveMode.split);
    });

    test('saveable when splits and gain change happen together', () {
      final decision = const TrimEditDecision(
        splitPoints: [0.3, 0.7],
        excludedSegments: {},
        gainDb: -4.0,
        totalDuration: oneMinute,
      );

      expect(decision.canSave, isTrue);
      expect(decision.mode, TrimSaveMode.split);
    });

    test('not saveable when every split segment was excluded', () {
      final decision = const TrimEditDecision(
        splitPoints: [0.5],
        excludedSegments: {0, 1},
        gainDb: 0.0,
        totalDuration: oneMinute,
      );

      expect(decision.canSave, isFalse);
    });

    test('keptCount reflects the number of surviving segments', () {
      final decision = const TrimEditDecision(
        splitPoints: [0.25, 0.5, 0.75],
        excludedSegments: {1},
        gainDb: 0.0,
        totalDuration: oneMinute,
      );

      expect(decision.keptCount, 3);
      expect(decision.canSave, isTrue);
    });

    test(
      'boost-only mode produces a single virtual segment covering full audio',
      () {
        final decision = const TrimEditDecision(
          splitPoints: [],
          excludedSegments: {},
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
      final decision = const TrimEditDecision(
        splitPoints: [0.5],
        excludedSegments: {},
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
      final decision = const TrimEditDecision(
        splitPoints: [0.25, 0.75],
        excludedSegments: {1},
        gainDb: 0.0,
        totalDuration: oneMinute,
      );

      final segments = decision.segments;

      expect(segments, hasLength(2));
      expect(segments[0].endSeconds, closeTo(15.0, 0.001));
      expect(segments[1].startSeconds, closeTo(45.0, 0.001));
    });

    test('negative gain inside the deadzone is treated as unchanged', () {
      final decision = const TrimEditDecision(
        splitPoints: [],
        excludedSegments: {},
        gainDb: -0.005,
        totalDuration: oneMinute,
      );

      expect(decision.canSave, isFalse);
    });

    test(
      'gain exactly equal to the deadzone threshold is treated as no change',
      () {
        final decision = const TrimEditDecision(
          splitPoints: [],
          excludedSegments: {},
          gainDb: 0.01,
          totalDuration: oneMinute,
        );

        expect(decision.canSave, isFalse);
      },
    );

    test('audio exactly at minimum duration is still too short', () {
      final decision = const TrimEditDecision(
        splitPoints: [],
        excludedSegments: {},
        gainDb: 6.0,
        totalDuration: Duration(milliseconds: 200),
      );

      expect(decision.canSave, isFalse);
    });

    test('unsorted split points still produce sliced segments in order', () {
      final decision = const TrimEditDecision(
        splitPoints: [0.75, 0.25],
        excludedSegments: {},
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
