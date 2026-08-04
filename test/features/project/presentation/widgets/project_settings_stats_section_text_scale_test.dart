// ENG-180: ProjectSettingsStatsSection (two rows of Expanded chips) must stay
// within bounds under large system fonts — each chip is width-partitioned by
// Expanded and the values/labels are short, so the rows do not overflow.
// ENG-374: the audio row now carries a pendency counter plus a per-kind
// breakdown, which is the longest text on this screen and the part with room
// to grow. French is this app's worst case for length, so it gets the top
// scale as well.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/project/domain/entities/project.dart';
import 'package:oral_collector/features/project/domain/entities/project_stats.dart';
import 'package:oral_collector/features/project/presentation/widgets/project_settings_header.dart';

import '../../../../support/text_scale.dart';

const _project = Project(
  id: 'p1',
  name: 'P',
  languageId: 'l1',
  recordingCount: 999999,
  totalDurationSeconds: 359999,
);

const _stats = ProjectStats(
  reviewFlagCounts: {
    'missing_classification': 666666,
    'insufficient_description': 555555,
    'missing_storyteller': 444444,
  },
  recordingsWithReviewFlags: 666666,
);

Future<void> _pump(
  WidgetTester tester,
  double scale, {
  Locale locale = const Locale('en'),
}) async {
  await pumpAtTextScale(
    tester,
    scale: scale,
    locale: locale,
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: ProjectSettingsStatsSection(
        project: _project,
        memberCount: 888888,
        storytellerCount: 777777,
        stats: _stats,
        onPendencyTap: (_) {},
      ),
    ),
  );
  await tester.pump();
}

void main() {
  for (final scale in const [1.0, 1.3, 2.0]) {
    testWidgets('does not overflow at ${scale}x', (tester) async {
      await _pump(tester, scale);
      expectNoOverflow(tester);
    });
  }

  testWidgets('does not overflow at 2.0x in French', (tester) async {
    // "Pas de classification" against "No classification": the breakdown is
    // where this screen's text has grown, and the longest locale is where it
    // gives way first.
    await _pump(tester, 2.0, locale: const Locale('fr'));
    expect(find.textContaining('Pas de classification'), findsOneWidget);
    expectNoOverflow(tester);
  });
}
