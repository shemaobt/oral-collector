// ENG-374: main.dart caps the system text scale at 2.0x, so 2.0x is a state
// the pill has to survive. It is measured through CompleteFichaOverlay — the
// real parent that positions it on the recording detail screen — because the
// bug is in how the overlay constrains the pill, not inside the pill itself.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/recording/presentation/widgets/complete_ficha_overlay.dart';
import 'package:oral_collector/features/recording/presentation/widgets/complete_ficha_pill.dart';

import '../../../../support/text_scale.dart';

/// Sub-pixel slack: layout arithmetic lands a hair off round numbers.
const _epsilon = 0.01;

void _expectInside(Rect inner, Rect outer, String what) {
  expect(
    inner.left,
    greaterThanOrEqualTo(outer.left - _epsilon),
    reason: '$what runs off the left edge',
  );
  expect(
    inner.right,
    lessThanOrEqualTo(outer.right + _epsilon),
    reason: '$what runs off the right edge',
  );
  expect(
    inner.top,
    greaterThanOrEqualTo(outer.top - _epsilon),
    reason: '$what runs off the top edge',
  );
  expect(
    inner.bottom,
    lessThanOrEqualTo(outer.bottom + _epsilon),
    reason: '$what runs off the bottom edge',
  );
}

Future<void> _pumpOverlay(
  WidgetTester tester, {
  required double scale,
  required Locale locale,
  int pendencyCount = 3,
}) async {
  await pumpAtTextScale(
    tester,
    scale: scale,
    locale: locale,
    child: SizedBox.expand(
      child: Stack(
        children: [
          CompleteFichaOverlay(pendencyCount: pendencyCount, onTap: () {}),
        ],
      ),
    ),
  );
}

void main() {
  final screen = Offset.zero & kPhoneSize;

  // fr is the worst case: "Compléter la fiche" is the longest label.
  for (final locale in const [Locale('en'), Locale('fr'), Locale('pt')]) {
    final lang = locale.languageCode;

    for (final scale in const [1.0, 1.5, 2.0]) {
      testWidgets('the pill fits the screen at ${scale}x ($lang)', (
        tester,
      ) async {
        await _pumpOverlay(tester, scale: scale, locale: locale);

        _expectInside(
          tester.getRect(find.byType(CompleteFichaPill)),
          screen,
          'the pill',
        );
        expectNoOverflow(tester);
      });

      testWidgets('the count badge is never clipped at ${scale}x ($lang)', (
        tester,
      ) async {
        await _pumpOverlay(tester, scale: scale, locale: locale);

        // The badge is the information the pill exists to carry; the label is
        // fixed text a user can recover without reading it. If something has to
        // be cut, it is never the count.
        _expectInside(
          tester.getRect(find.text('3')),
          screen,
          'the count badge',
        );
      });
    }
  }
}
