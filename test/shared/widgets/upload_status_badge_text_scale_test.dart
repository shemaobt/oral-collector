// ENG-178: the shared UploadStatusBadge must keep its label readable under large
// system fonts. Under severe width pressure it must ellipsize rather than
// overflow; the failed+retry variant must also render fully at scale.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/theme/app_colors.dart';
import 'package:oral_collector/core/theme/app_theme.dart';
import 'package:oral_collector/shared/widgets/app_disc.dart';
import 'package:oral_collector/shared/widgets/brush_sign.dart';
import 'package:oral_collector/shared/widgets/upload_status_badge.dart';

import '../../support/text_scale.dart';

Future<void> _pump(
  WidgetTester tester, {
  required String status,
  int? percent,
  bool compact = true,
  double scale = 1.0,
  double? width,
  ThemeData? theme,
  Locale locale = const Locale('en'),
}) async {
  final badge = UploadStatusBadge(
    status: status,
    percent: percent,
    compact: compact,
  );
  await pumpAtTextScale(
    tester,
    scale: scale,
    theme: theme,
    locale: locale,
    child: Center(
      child: width == null ? badge : SizedBox(width: width, child: badge),
    ),
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

  for (final (status, percent, word, color) in [
    ('uploading', 42, 'Sending 42%', AppColors.light.deep),
    ('web_uploading', null, 'Sending', AppColors.light.deep),
    ('local', null, 'On the device', AppColors.light.secondary),
    ('something_new', 42, 'On the device', AppColors.light.secondary),
  ]) {
    testWidgets('$status is the word "$word" at 13/600, no sign', (
      tester,
    ) async {
      await _pump(tester, status: status, percent: percent);
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

  for (final (name, theme, color) in [
    ('light', AppTheme.lightTheme, const Color(0xFF872F00)),
    ('dark', AppTheme.darkTheme, const Color(0xFF872F00)),
  ]) {
    testWidgets('the needs-you sign is dark orange on its disc in $name', (
      tester,
    ) async {
      await _pump(tester, status: 'failed', theme: theme);
      expect(tester.widget<BrushSign>(find.byType(BrushSign)).color, color);
    });
  }

  testWidgets('in dark the sent sign and the sending word take dark tones', (
    tester,
  ) async {
    await _pump(tester, status: 'uploaded', theme: AppTheme.darkTheme);
    expect(
      tester.widget<BrushSign>(find.byType(BrushSign)).color,
      AppColors.dark.info,
    );
    await _pump(
      tester,
      status: 'uploading',
      percent: 42,
      theme: AppTheme.darkTheme,
    );
    expect(
      tester.widget<Text>(find.text('Sending 42%')).style?.color,
      AppColors.dark.deep,
    );
  });

  group('page form', () {
    for (final (status, word, sign) in [
      ('uploaded', 'Sent', Sign.check),
      ('uploading', 'Sending 42%', Sign.up),
      ('local', 'On the device', Sign.device),
    ]) {
      testWidgets('$status is its sign then "$word" at 15/600', (tester) async {
        await _pump(tester, status: status, percent: 42, compact: false);
        final mark = tester.widget<BrushSign>(find.byType(BrushSign));
        final text = tester.widget<Text>(find.text(word));
        expect(mark.sign, sign);
        expect(mark.size, 18);
        expect(text.style?.fontSize, 15);
        expect(text.style?.fontWeight, FontWeight.w600);
        expect(text.style?.color, mark.color);
        expect(
          tester.getTopLeft(find.byType(BrushSign)).dx,
          lessThan(tester.getTopLeft(find.text(word)).dx),
        );
      });
    }

    testWidgets('needs you is the disc then the word at 15', (tester) async {
      await _pump(tester, status: 'failed_exhausted', compact: false);
      expect(find.byType(AppDisc), findsOneWidget);
      final text = tester.widget<Text>(find.text('Needs you'));
      expect(text.style?.fontSize, 15);
      expect(text.style?.color, AppColors.light.error);
    });
  });

  group('under width pressure at 2.0x in 80 wide', () {
    for (final compact in [true, false]) {
      for (final locale in const [Locale('en'), Locale('ar')]) {
        for (final status in ['uploading', 'local', 'failed']) {
          testWidgets('$status, compact $compact, $locale', (tester) async {
            await _pump(
              tester,
              status: status,
              percent: 42,
              compact: compact,
              scale: 2.0,
              width: 80,
              locale: locale,
            );
            expectNoOverflow(tester);
            if (status != 'failed') {
              final text = tester.widget<Text>(find.byType(Text));
              expect(text.overflow, TextOverflow.ellipsis);
              expect(text.maxLines, 1);
            }
          });
        }
      }
    }

    for (final status in ['uploaded', 'failed']) {
      testWidgets('$status row sign keeps its size', (tester) async {
        await _pump(tester, status: status, scale: 2.0, width: 80);
        final finder = status == 'failed'
            ? find.byType(AppDisc)
            : find.byType(BrushSign);
        expect(tester.getSize(finder).width, status == 'failed' ? 32 : 18);
      });
    }
  });
}
