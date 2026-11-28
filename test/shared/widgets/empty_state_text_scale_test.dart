// ENG-178: shared EmptyState must survive large system fonts (MediaQuery
// textScaler) without overflowing. Rendered on a realistic phone viewport so a
// long description at large scale actually has to fit the screen.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:oral_collector/shared/widgets/empty_state.dart';

import '../../support/text_scale.dart';

const _title = 'No recordings in this project yet';
const _description =
    'Once you record or import audio it will appear here. Recordings you '
    'capture on this device are stored locally and uploaded to the project '
    'archive when a connection is available. Pull to refresh if you expect to '
    'see items that have not appeared yet.';

Future<void> _pump(WidgetTester tester, double scale) async {
  await pumpAtTextScale(
    tester,
    scale: scale,
    child: EmptyState(
      icon: LucideIcons.listMusic,
      title: _title,
      description: _description,
      action: FilledButton(onPressed: () {}, child: const Text('Add')),
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

  testWidgets('title and description stay in the tree at 2.0x', (tester) async {
    await _pump(tester, 2.0);
    expect(find.text(_title), findsOneWidget);
    expect(find.text(_description), findsOneWidget);
  });
}
