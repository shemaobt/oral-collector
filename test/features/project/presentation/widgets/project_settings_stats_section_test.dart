// ENG-374: the project screen keeps audio facts and team facts in separate
// rows, and the "needs details" counter is the server's distinct-recording
// count. Summing reviewFlagCounts would over-report by a plausible amount —
// one recording with three open fields lands in three codes but is one
// recording — which is the failure mode these tests exist to catch.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/project/domain/entities/project.dart';
import 'package:oral_collector/features/project/domain/entities/project_stats.dart';
import 'package:oral_collector/features/project/presentation/widgets/project_settings_header.dart';
import 'package:oral_collector/features/project/presentation/widgets/project_stat_chip.dart';

import '../../../../support/text_scale.dart';

// Counts chosen so no two rendered numbers collide: 12 recordings, 10m of
// audio, 7 members, 5 storytellers. Nothing here reads as 3, 4 or 6.
const _project = Project(
  id: 'p1',
  name: 'P',
  languageId: 'l1',
  recordingCount: 12,
  totalDurationSeconds: 600,
);

Future<void> _pump(WidgetTester tester, {ProjectStats? stats}) async {
  await pumpAtTextScale(
    tester,
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: ProjectSettingsStatsSection(
        project: _project,
        memberCount: 7,
        storytellerCount: 5,
        stats: stats,
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('counts recordings that need attention, not open fields', (
    tester,
  ) async {
    await _pump(
      tester,
      stats: const ProjectStats(
        reviewFlagCounts: {
          'missing_classification': 3,
          'insufficient_description': 1,
        },
        recordingsWithReviewFlags: 3,
      ),
    );

    expect(find.text('3'), findsOneWidget);
    expect(find.text('4'), findsNothing);
  });

  testWidgets('keeps an unknown code out of the labels but inside the total', (
    tester,
  ) async {
    await _pump(
      tester,
      stats: const ProjectStats(
        reviewFlagCounts: {
          'missing_classification': 2,
          'awaiting_linguist_review': 5,
        },
        recordingsWithReviewFlags: 6,
      ),
    );

    expect(find.text('6'), findsOneWidget);
    expect(find.textContaining('awaiting_linguist_review'), findsNothing);
    // The number matters as much as the label: a breakdown fed the distinct
    // count instead of the per-code count would still say "No classification".
    expect(find.text('No classification: 2'), findsOneWidget);
  });

  testWidgets('hangs the breakdown under the counter it explains', (
    tester,
  ) async {
    // The labels overlap — a recording missing two fields is counted twice —
    // so they must not read as a full-width partition of the headline number.
    await _pump(
      tester,
      stats: const ProjectStats(
        reviewFlagCounts: {
          'missing_classification': 3,
          'missing_storyteller': 3,
        },
        recordingsWithReviewFlags: 3,
      ),
    );

    final chipRight = tester
        .getBottomRight(
          find.ancestor(
            of: find.text('Needs details'),
            matching: find.byType(ProjectSettingsStatChip),
          ),
        )
        .dx;

    expect(
      tester.getBottomRight(find.text('No storyteller: 3')).dx,
      closeTo(chipRight, 1),
    );
    expect(
      tester.getTopLeft(find.text('No classification: 3')).dx,
      greaterThan(tester.getTopLeft(find.text('Recordings')).dx),
    );
  });

  testWidgets('says nothing per code when there is no counter to explain', (
    tester,
  ) async {
    // A server sending the map without the distinct count would otherwise put
    // labelled numbers on screen with no headline above them.
    await _pump(
      tester,
      stats: const ProjectStats(
        reviewFlagCounts: {'missing_classification': 2},
      ),
    );

    expect(find.text('Needs details'), findsNothing);
    expect(find.textContaining('No classification'), findsNothing);
  });

  testWidgets('drops the counter when the stats fetch failed', (tester) async {
    await _pump(tester);

    expect(find.text('Needs details'), findsNothing);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
  });

  testWidgets('separates audio facts from team facts', (tester) async {
    await _pump(
      tester,
      stats: const ProjectStats(recordingsWithReviewFlags: 3),
    );

    double bottomOf(String label) => tester.getBottomLeft(find.text(label)).dy;
    double topOf(String label) => tester.getTopLeft(find.text(label)).dy;

    final audioBottom = [
      bottomOf('Recordings'),
      bottomOf('Duration'),
      bottomOf('Needs details'),
    ].reduce((a, b) => a > b ? a : b);

    expect(topOf('Members'), greaterThan(audioBottom));
    expect(topOf('Storytellers'), greaterThan(audioBottom));
  });
}
