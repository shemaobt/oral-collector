// ENG-178: the shared UploadStatusBadge must keep its label readable under large
// system fonts. Under severe width pressure it must ellipsize rather than
// overflow; the failed+retry variant must also render fully at scale.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/theme/app_colors.dart';
import 'package:oral_collector/shared/widgets/app_disc.dart';
import 'package:oral_collector/shared/widgets/brush_sign.dart';
import 'package:oral_collector/shared/widgets/upload_status_badge.dart';

import '../../support/text_scale.dart';

Future<void> _pump(WidgetTester tester, {required String status}) async {
  await pumpAtTextScale(
    tester,
    child: Center(child: UploadStatusBadge(status: status)),
  );
  await tester.pump();
}

void main() {
  for (final status in ['uploaded', 'verified']) {
    testWidgets('$status is the check sign alone, read as Sent', (
      tester,
    ) async {
      await _pump(tester, status: status);
      final sign = tester.widget<BrushSign>(find.byType(BrushSign));
      expect(sign.sign, Sign.check);
      expect(sign.color, AppColors.light.info);
      expect(find.bySemanticsLabel('Sent'), findsOneWidget);
    });
  }

  for (final (status, word, color) in [
    ('uploading', 'Sending', AppColors.light.deep),
    ('web_uploading', 'Sending', AppColors.light.deep),
    ('local', 'On the device', AppColors.light.secondary),
    ('something_new', 'On the device', AppColors.light.secondary),
  ]) {
    testWidgets('$status is the word "$word" at 13/600, no sign', (
      tester,
    ) async {
      await _pump(tester, status: status);
      final text = tester.widget<Text>(find.text(word));
      expect(text.style?.fontSize, 13);
      expect(text.style?.fontWeight, FontWeight.w600);
      expect(text.style?.color, color);
      expect(find.byType(BrushSign), findsNothing);
      expect(tester.binding.transientCallbackCount, 0);
    });
  }

  for (final status in [
    'failed',
    'failed_conflict',
    'failed_description',
    'failed_missing_file',
    'failed_refused_object',
  ]) {
    testWidgets('$status is the info sign on a 32 disc, read as Needs you', (
      tester,
    ) async {
      await _pump(tester, status: status);
      final disc = tester.widget<AppDisc>(find.byType(AppDisc));
      expect(disc.tone, DiscTone.failed);
      expect(disc.size, DiscSize.small);
      expect(tester.widget<BrushSign>(find.byType(BrushSign)).sign, Sign.info);
      expect(find.bySemanticsLabel('Needs you'), findsOneWidget);
    });
  }
}
