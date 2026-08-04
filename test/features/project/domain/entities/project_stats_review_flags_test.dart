/// The project-level review counters (ENG-374).
///
/// The server sends two numbers that look interchangeable and are not: a count
/// per flag code, and a count of distinct recordings carrying any flag. A
/// recording with three open fields adds one to each of three codes but only
/// one to the distinct count, so summing the map to answer "how many
/// recordings need me?" over-reports — quietly, and by a plausible amount.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/project/domain/entities/project_stats.dart';

void main() {
  Map<String, dynamic> statsJson({Object? counts, Object? distinct}) => {
    'project_id': 'proj-1',
    'total_recordings': 10,
    'total_duration_seconds': 3600.0,
    'total_file_size_bytes': 1024,
    'total_storytellers': 4,
    'review_flag_counts': ?counts,
    'recordings_with_review_flags': ?distinct,
  };

  test('the per-code counts arrive as sent', () {
    final stats = ProjectStats.fromJson(
      statsJson(
        counts: {'missing_classification': 3, 'missing_storyteller': 1},
        distinct: 3,
      ),
    );

    expect(stats.reviewFlagCounts, {
      'missing_classification': 3,
      'missing_storyteller': 1,
    });
  });

  test('the distinct count is carried separately, not derived', () {
    // Four flags spread over three recordings. Summing the map gives 4; the
    // honest answer to "how many recordings need attention" is 3.
    final stats = ProjectStats.fromJson(
      statsJson(
        counts: {'missing_classification': 3, 'insufficient_description': 1},
        distinct: 3,
      ),
    );

    expect(stats.recordingsWithReviewFlags, 3);
    expect(
      stats.reviewFlagCounts.values.reduce((a, b) => a + b),
      isNot(stats.recordingsWithReviewFlags),
    );
  });

  test('a project with nothing to review reads as empty, not as absent', () {
    final stats = ProjectStats.fromJson(
      statsJson(counts: <String, dynamic>{}, distinct: 0),
    );

    expect(stats.reviewFlagCounts, isEmpty);
    expect(stats.recordingsWithReviewFlags, 0);
  });

  test('a server that does not send the counters yet is not a failure', () {
    final stats = ProjectStats.fromJson(statsJson());

    // The counters shipped after the rest of this endpoint, so a client may
    // meet a server that predates them.
    expect(stats.reviewFlagCounts, isEmpty);
    expect(stats.recordingsWithReviewFlags, isNull);
    expect(stats.totalRecordings, 10);
  });

  test('a code this build has never heard of is still counted', () {
    final stats = ProjectStats.fromJson(
      statsJson(counts: {'awaiting_transcription': 2}, distinct: 2),
    );

    // The entity carries what the server sent. Deciding what can be shown is
    // the screen's job, and it still needs the number to say how many
    // recordings need attention overall.
    expect(stats.reviewFlagCounts['awaiting_transcription'], 2);
  });

  test('a malformed counter does not cost the whole stats payload', () {
    final stats = ProjectStats.fromJson(
      statsJson(counts: {'missing_storyteller': 'three'}, distinct: 1),
    );

    // Losing a counter is a worse screen; losing the payload is a broken one.
    expect(stats.totalRecordings, 10);
    expect(stats.reviewFlagCounts.containsKey('missing_storyteller'), isFalse);
  });

  test('a malformed distinct count follows the same rule as the map', () {
    // The two counters answer the same question and must fail the same way.
    // Tolerating a bad map entry while throwing on a bad distinct count would
    // lose the payload anyway, just depending on which field the server got
    // wrong.
    final stats = ProjectStats.fromJson(
      statsJson(counts: {'missing_storyteller': 1}, distinct: 'three'),
    );

    expect(stats.recordingsWithReviewFlags, isNull);
    expect(stats.totalRecordings, 10);
    expect(stats.reviewFlagCounts, {'missing_storyteller': 1});
  });
}
