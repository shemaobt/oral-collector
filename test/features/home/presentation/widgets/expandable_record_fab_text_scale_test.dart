// ENG-181: the expandable record FAB pins its mini-action labels inside a
// fixed-width corner stack. Under large system fonts the label + button row
// must still fit instead of overflowing.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/theme/app_colors.dart';
import 'package:oral_collector/features/home/presentation/widgets/expandable_record_fab.dart';
import 'package:oral_collector/l10n/app_localizations_en.dart';

import '../../../../support/text_scale.dart';

Future<void> _pump(WidgetTester tester, double scale) async {
  await pumpAtTextScale(
    tester,
    scale: scale,
    child: Align(
      alignment: Alignment.bottomRight,
      child: ExpandableRecordFab(
        onQuickRecord: () {},
        onNormalRecord: () {},
        colors: AppColors.light,
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

  testWidgets('mini-action labels stay in the tree when expanded at 2.0x', (
    tester,
  ) async {
    await _pump(tester, 2.0);
    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();
    expectNoOverflow(tester);
    final l10n = AppLocalizationsEn();
    expect(find.text(l10n.fab_quickRecord), findsOneWidget);
    expect(find.text(l10n.fab_normalRecord), findsOneWidget);
  });
}
