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
import 'package:oral_collector/features/recording/domain/entities/review_pendency.dart';

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

Future<void> _pump(
  WidgetTester tester, {
  ProjectStats? stats,
  void Function(PendencyKind kind)? onPendencyTap,
  Locale locale = const Locale('en'),
}) async {
  await pumpAtTextScale(
    tester,
    locale: locale,
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: ProjectSettingsStatsSection(
        project: _project,
        memberCount: 7,
        storytellerCount: 5,
        stats: stats,
        onPendencyTap: onPendencyTap ?? (_) {},
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

    // The row, not the text: the line is a tap target since ENG-381, so its
    // trailing chevron is what sits on the right edge.
    expect(
      tester
          .getBottomRight(
            find.ancestor(
              of: find.text('No storyteller: 3'),
              matching: find.byType(InkWell),
            ),
          )
          .dx,
      closeTo(chipRight, 1),
    );
    expect(
      tester.getTopLeft(find.text('No classification: 3')).dx,
      greaterThan(tester.getTopLeft(find.text('Recordings')).dx),
    );
  });

  testWidgets('a project with nothing pending gets no breakdown at all', (
    tester,
  ) async {
    // The server seeds every known code at zero, so a clean project arrives as
    // a full map rather than an empty one. Rendering it as written would put
    // three lines saying zero on screen — and since ENG-381 each line is a tap
    // target, all three would lead somewhere with nothing in it.
    await _pump(
      tester,
      stats: const ProjectStats(
        reviewFlagCounts: {
          'missing_classification': 0,
          'insufficient_description': 0,
          'missing_storyteller': 0,
        },
        // Zero, not absent: a null distinct count short-circuits the breakdown
        // before the per-code map is ever read, which would leave this passing
        // without exercising the filtering at all.
        recordingsWithReviewFlags: 0,
      ),
    );

    expect(find.textContaining(': 0'), findsNothing);
  });

  testWidgets('a code nobody carries stays out while its siblings show', (
    tester,
  ) async {
    await _pump(
      tester,
      stats: const ProjectStats(
        reviewFlagCounts: {
          'missing_classification': 2,
          'insufficient_description': 0,
          'missing_storyteller': 0,
        },
        recordingsWithReviewFlags: 2,
      ),
    );

    expect(find.text('No classification: 2'), findsOneWidget);
    expect(find.textContaining(': 0'), findsNothing);
  });

  testWidgets('the breakdown follows the reading direction, not the screen', (
    tester,
  ) async {
    // The counter chip it sits under lives in a Row, so in Arabic that chip
    // moves to the left. A physically right-aligned breakdown stays behind on
    // the other side of the screen, explaining a number nowhere near it.
    await _pump(
      tester,
      locale: const Locale('ar'),
      stats: const ProjectStats(
        reviewFlagCounts: {'missing_classification': 3},
        recordingsWithReviewFlags: 3,
      ),
    );

    final section = tester.getRect(find.byType(ProjectSettingsStatsSection));
    final line = tester.getRect(find.byType(InkWell));

    expect(line.left - section.left, lessThan(section.right - line.right));
  });

  testWidgets('the whole breakdown line is a tap target, not just its text', (
    tester,
  ) async {
    final taps = <PendencyKind>[];
    await _pump(
      tester,
      stats: const ProjectStats(
        reviewFlagCounts: {'missing_classification': 3},
        recordingsWithReviewFlags: 3,
      ),
      onPendencyTap: taps.add,
    );

    final target = find.ancestor(
      of: find.text('No classification: 3'),
      matching: find.byType(InkWell),
    );
    final box = tester.getRect(target);

    // 48dp is the floor for a thumb; a line of labelSmall is a third of that.
    expect(box.height, greaterThanOrEqualTo(48.0));
    // And it has to be at least as wide as what it looks like it covers —
    // a target narrower than its own label leaves part of the line dead.
    expect(
      box.width,
      greaterThanOrEqualTo(
        tester.getRect(find.text('No classification: 3')).width,
      ),
    );

    // The corners, not the centre: the centre sits on the text and would pass
    // even if everything around it were inert.
    await tester.tapAt(box.topLeft + const Offset(1, 1));
    await tester.tapAt(box.bottomRight - const Offset(1, 1));
    await tester.pump();

    expect(taps, [PendencyKind.classification, PendencyKind.classification]);
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
