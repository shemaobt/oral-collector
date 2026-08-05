// ENG-181: the expandable record FAB pins its mini-action labels inside a
// fixed-width corner stack. Under large system fonts the label + button row
// must still fit instead of overflowing.
// ENG-185: at the 2.0x ceiling the labels must be fully visible (not clipped by
// a fixed-size box). This is asserted via geometry, because clipping inside a
// Stack throws no overflow exception and find.text still finds a clipped label.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/theme/app_colors.dart';
import 'package:oral_collector/features/home/presentation/widgets/expandable_record_fab.dart';
import 'package:oral_collector/l10n/app_localizations_en.dart';
import 'package:oral_collector/l10n/app_localizations_fr.dart';

import '../../../../support/text_scale.dart';

Future<void> _pump(
  WidgetTester tester,
  double scale, {
  Locale locale = const Locale('en'),
}) async {
  await pumpAtTextScale(
    tester,
    scale: scale,
    locale: locale,
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

Future<void> _pumpExpanded(
  WidgetTester tester,
  double scale, {
  Locale locale = const Locale('en'),
}) async {
  await _pump(tester, scale, locale: locale);
  await tester.tap(find.byType(InkWell));
  await tester.pumpAndSettle();
}

/// Fails if [label]'s rendered rect is not fully inside the FAB's own rendered
/// rect — i.e. the label is clipped by the FAB box. Design-agnostic: it only
/// looks at on-screen geometry, not how the reflow is implemented.
///
/// Assumes the label wraps and is never ellipsized/truncated: a truncated label
/// would fit the box geometrically while hiding text, which this check cannot
/// see.
void _expectLabelWithinFab(WidgetTester tester, String label) {
  final fabRect = tester.getRect(find.byType(ExpandableRecordFab));
  final labelRect = tester.getRect(find.text(label));
  expect(
    labelRect.left,
    greaterThanOrEqualTo(fabRect.left - 0.5),
    reason: '"$label" is clipped on the left by the FAB box',
  );
  expect(
    labelRect.right,
    lessThanOrEqualTo(fabRect.right + 0.5),
    reason: '"$label" is clipped on the right by the FAB box',
  );
  expect(
    labelRect.top,
    greaterThanOrEqualTo(fabRect.top - 0.5),
    reason: '"$label" is clipped at the top by the FAB box',
  );
  expect(
    labelRect.bottom,
    lessThanOrEqualTo(fabRect.bottom + 0.5),
    reason: '"$label" is clipped at the bottom by the FAB box',
  );
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
    await _pumpExpanded(tester, 2.0);
    expectNoOverflow(tester);
    final l10n = AppLocalizationsEn();
    expect(find.text(l10n.fab_quickRecord), findsOneWidget);
    expect(find.text(l10n.fab_normalRecord), findsOneWidget);
  });

  // ENG-185: the long French label "Enregistrer" overruns the old fixed 160px
  // corner box at 2.0x, so it is the faithful failing case.
  testWidgets('expanded label is not clipped by the FAB at 2.0x (fr)', (
    tester,
  ) async {
    await _pumpExpanded(tester, 2.0, locale: const Locale('fr'));
    _expectLabelWithinFab(tester, AppLocalizationsFr().fab_normalRecord);
  });

  testWidgets('expanded label is not clipped by the FAB at 2.0x (en)', (
    tester,
  ) async {
    await _pumpExpanded(tester, 2.0);
    _expectLabelWithinFab(tester, AppLocalizationsEn().fab_normalRecord);
  });
}
