// ENG-180: ProjectSettingsStatChip (a row of Expanded chips) must stay within
// bounds under large system fonts — each chip is width-partitioned by Expanded
// and the values/labels are short, so the row does not overflow.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/project/domain/entities/project.dart';
import 'package:oral_collector/features/project/presentation/widgets/project_settings_header.dart';

import '../../../../support/text_scale.dart';

const _project = Project(
  id: 'p1',
  name: 'P',
  languageId: 'l1',
  recordingCount: 999999,
  totalDurationSeconds: 359999,
);

Future<void> _pump(WidgetTester tester, double scale) async {
  await pumpAtTextScale(
    tester,
    scale: scale,
    child: const Padding(
      padding: EdgeInsets.all(8),
      child: ProjectSettingsStatsRow(
        project: _project,
        memberCount: 888888,
        storytellerCount: 777777,
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
}
