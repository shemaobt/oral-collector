/// ENG-518: the leave dialog grew a third button and longer copy, so it is the
/// widest thing this flow asks a narrow screen to hold. 320dp is the narrowest
/// phone the project supports, and 2.0x is the text-scale ceiling (ENG-177).
///
/// The check is the dialog as the app really shows it — `showDialog` supplies
/// the insets and padding, so the harness opens it rather than rendering an
/// `AlertDialog` bare, which would measure a width nobody sees.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/recording/presentation/widgets/leave_recording_dialog.dart';

import '../../../../support/text_scale.dart';

const _narrowPhone = Size(320, 640);

Future<void> _openDialog(
  WidgetTester tester, {
  required bool canKeepForLater,
  required double scale,
}) async {
  await pumpAtTextScale(
    tester,
    scale: scale,
    size: _narrowPhone,
    child: Builder(
      builder: (context) => TextButton(
        onPressed: () =>
            showLeaveRecordingDialog(context, canKeepForLater: canKeepForLater),
        child: const Text('open'),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  for (final scale in const [1.0, 1.3, 2.0]) {
    testWidgets('leave dialog has no overflow at ${scale}x on 320dp', (
      tester,
    ) async {
      await _openDialog(tester, canKeepForLater: true, scale: scale);
      expectNoOverflow(tester);
      // Taking the exception is not enough on its own: an action bar that
      // silently clips reports no overflow. Every door has to be on screen.
      for (final label in const ['Cancel', 'Keep for later', 'Discard']) {
        final rect = tester.getRect(find.text(label));
        expect(rect.left, greaterThanOrEqualTo(0.0), reason: label);
        expect(
          rect.right,
          lessThanOrEqualTo(_narrowPhone.width),
          reason: label,
        );
      }
    });
  }

  testWidgets('the two-door dialog also survives 2.0x on 320dp', (
    tester,
  ) async {
    await _openDialog(tester, canKeepForLater: false, scale: 2.0);
    expect(find.text('Keep for later'), findsNothing);
    expectNoOverflow(tester);
  });
}
