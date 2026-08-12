/// Pure-logic tests for TrimEditorState (ENG-193): the derivations the trim
/// editor screen used to compute inline (boundaries, segment timing, effective
/// taxonomy, the save decision) plus the taxonomy remap used when split points
/// change. These pin behaviour the notifier and widget both read through
/// `state.x`, so they characterize the maths once, independently of the UI.
library;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/features/recording/data/local_recording_to_entity.dart';
import 'package:oral_collector/features/recording/data/repositories/local_recording_repository.dart';
import 'package:oral_collector/features/recording/domain/entities/local_recording_entity.dart';
import 'package:oral_collector/features/recording/presentation/notifiers/trim_editor_state.dart';
import 'package:oral_collector/features/recording/presentation/trim_edit_decision.dart';

void main() {
  group('boundaries and segments', () {
    test('no splits is a single full-width segment', () {
      const state = TrimEditorState();
      expect(state.boundaries, [0.0, 1.0]);
      expect(state.segmentCount, 1);
      expect(state.keptCount, 1);
      expect(state.keptSegmentIndices, [0]);
    });

    test('split points are sorted before forming boundaries', () {
      const state = TrimEditorState(splitPoints: [0.7, 0.3]);
      expect(state.boundaries, [0.0, 0.3, 0.7, 1.0]);
      expect(state.segmentCount, 3);
    });

    test('excluded segments reduce kept count and are dropped from kept '
        'indices', () {
      const state = TrimEditorState(
        splitPoints: [0.3, 0.7],
        excludedSegments: {1},
      );
      expect(state.segmentCount, 3);
      expect(state.keptCount, 2);
      expect(state.keptSegmentIndices, [0, 2]);
    });
  });

  group('segment timing', () {
    test('maps boundary fractions to durations against the total', () {
      const state = TrimEditorState(
        splitPoints: [0.5],
        totalDuration: Duration(seconds: 10),
      );
      expect(state.segmentStart(0), Duration.zero);
      expect(state.segmentEnd(0), const Duration(seconds: 5));
      expect(state.segmentDuration(0), const Duration(seconds: 5));
      expect(state.segmentStart(1), const Duration(seconds: 5));
      expect(state.segmentEnd(1), const Duration(seconds: 10));
    });

    test('segment signature is the midpoint to six decimals', () {
      const state = TrimEditorState();
      expect(state.sigForSegment(0), '0.500000');
      const split = TrimEditorState(splitPoints: [0.4]);
      expect(split.sigForSegment(0), '0.200000');
      expect(split.sigForSegment(1), '0.700000');
    });

    test('neighbouring minimum-length segments do not share a signature', () {
      // ENG-66 dropped the floor to 250 ms, so on a long recording two
      // adjacent segments can be far closer than the old 3% apart. Three
      // decimals collided here and one segment's taxonomy override leaked
      // onto its neighbour.
      const total = Duration(minutes: 30);
      final gap = 0.25 / total.inSeconds;
      final state = TrimEditorState(
        totalDuration: total,
        splitPoints: [0.5, 0.5 + gap, 0.5 + gap * 2],
      );

      final sigs = {
        state.sigForSegment(1),
        state.sigForSegment(2),
        state.sigForSegment(3),
      };

      expect(sigs, hasLength(3));
    });
  });

  group('decision', () {
    test('a split with kept segments and a long-enough clip can be saved', () {
      const state = TrimEditorState(
        splitPoints: [0.5],
        totalDuration: Duration(seconds: 10),
      );
      expect(state.decision.mode, TrimSaveMode.split);
      expect(state.decision.canSave, isTrue);
    });

    test('no edits cannot be saved and reads as boost-only mode', () {
      const state = TrimEditorState(totalDuration: Duration(seconds: 10));
      expect(state.decision.mode, TrimSaveMode.boostOnly);
      expect(state.decision.canSave, isFalse);
    });
  });

  group('effective taxonomy', () {
    late AppDatabase db;
    late LocalRecordingRepository repo;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repo = LocalRecordingRepository(db);
    });
    tearDown(() => db.close());

    Future<LocalRecordingEntity> seedParent() async {
      await repo.insertRecording(
        LocalRecordingsCompanion(
          id: const Value('p1'),
          projectId: const Value('proj'),
          genreId: const Value('g0'),
          subcategoryId: const Value('sub0'),
          registerId: const Value('reg0'),
          title: const Value('Parent'),
          durationSeconds: const Value(30.0),
          fileSizeBytes: const Value(1000),
          format: const Value('m4a'),
          localFilePath: const Value('/p.m4a'),
          uploadStatus: const Value('local'),
          cleaningStatus: const Value('cleaned'),
          recordedAt: Value(DateTime.utc(2026, 5, 1)),
        ),
      );
      return localRecordingToEntity((await repo.getRecordingById('p1'))!);
    }

    test('falls back to the parent taxonomy when no per-segment override is '
        'set', () async {
      final recording = await seedParent();
      final state = TrimEditorState(recording: recording);
      expect(state.effectiveGenre(0), 'g0');
      expect(state.effectiveSubcategory(0), 'sub0');
      expect(state.effectiveRegister(0), 'reg0');
    });

    test('uses a per-segment override when present', () async {
      final recording = await seedParent();
      final state = TrimEditorState(
        recording: recording,
        segGenreBySig: const {'0.500000': 'gX'},
        segSubcatBySig: const {'0.500000': 'subX'},
        segRegisterBySig: const {'0.500000': 'regX'},
      );
      expect(state.effectiveGenre(0), 'gX');
      expect(state.effectiveSubcategory(0), 'subX');
      expect(state.effectiveRegister(0), 'regX');
    });

    test('a null subcategory/register override clears it, but a null genre '
        'override falls back to the parent genre', () async {
      final recording = await seedParent();
      final state = TrimEditorState(
        recording: recording,
        segGenreBySig: const {'0.500000': null},
        segSubcatBySig: const {'0.500000': null},
        segRegisterBySig: const {'0.500000': null},
      );
      expect(state.effectiveGenre(0), 'g0');
      expect(state.effectiveSubcategory(0), isNull);
      expect(state.effectiveRegister(0), isNull);
    });
  });

  group('remapTaxonomyBySig', () {
    test('keeps an override whose segment midpoint barely moves', () {
      final result = remapTaxonomyBySig(
        const {'0.200000': 'gA'},
        const [0.0, 0.4, 1.0],
        const [0.0, 0.41, 1.0],
      );
      // New segment 0 midpoint 0.205 is within 0.02 of old 0.200.
      expect(result, {'0.205000': 'gA'});
    });

    test('drops an override whose nearest segment midpoint moves beyond the '
        'threshold', () {
      final result = remapTaxonomyBySig(
        const {'0.500000': 'gA'},
        const [0.0, 1.0],
        const [0.0, 0.5, 1.0],
      );
      // Splitting moves both new midpoints (0.25, 0.75) > 0.02 from old 0.5.
      expect(result, isEmpty);
    });

    test('a re-split does not carry an override past its own segment', () {
      // ENG-66: minimum-length segments on a 3-minute recording are 0.00139
      // wide. Shifting the segmentation by five of those moves every midpoint
      // well under the flat 0.02, which used to carry the override five
      // segments away from where the user set it.
      const gap = 0.25 / 180;
      final result = remapTaxonomyBySig(
        {(0.5 + gap / 2).toStringAsFixed(6): 'gA'},
        const [0.0, 0.5, 0.5 + gap, 1.0],
        const [0.0, 0.5 + gap * 5, 0.5 + gap * 6, 1.0],
      );

      expect(result, isEmpty);
    });

    test('an override on an unchanged segmentation survives', () {
      final result = remapTaxonomyBySig(
        const {'0.500000': 'gA'},
        const [0.0, 1.0],
        const [0.0, 1.0],
      );
      expect(result, {'0.500000': 'gA'});
    });
  });
}
