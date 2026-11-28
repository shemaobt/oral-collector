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
  bool compact = false,
  double? width,
}) async {
  final badge = UploadStatusBadge(status: 'uploaded', compact: compact);
  await pumpAtTextScale(
    tester,
    scale: 2.0,
    child: Center(
      child: width == null ? badge : SizedBox(width: width, child: badge),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets(
    'ellipsizes instead of overflowing under width pressure at 2.0x',
    (tester) async {
      await _pump(tester, width: 80);
      expectNoOverflow(tester);
    },
  );

  testWidgets('compact ellipsizes under width pressure at 2.0x', (
    tester,
  ) async {
    await _pump(tester, compact: true, width: 80);
    expectNoOverflow(tester);
  });

  testWidgets('full label stays in the tree at 2.0x', (tester) async {
    await _pump(tester);
    expect(find.text('Sent'), findsOneWidget);
  });

  group('send state in a row', () {
    for (final status in ['uploaded', 'verified']) {
      testWidgets('$status is the check sign alone, read as Sent', (
        tester,
      ) async {
        await _pumpState(tester, status: status, compact: true);
        final sign = tester.widget<BrushSign>(find.byType(BrushSign));
        expect(sign.sign, Sign.check);
        expect(sign.size, 18);
        expect(sign.color, _colors(tester).info);
        expect(find.text('Sent'), findsNothing);
        expect(find.bySemanticsLabel('Sent'), findsOneWidget);
      });
    }

    for (final status in ['uploading', 'web_uploading']) {
      testWidgets('$status is the word Sending with its percent, no sign', (
        tester,
      ) async {
        await _pumpState(tester, status: status, compact: true, percent: 42);
        final word = tester.widget<Text>(find.text('Sending 42%'));
        expect(word.style?.fontSize, 13);
        expect(word.style?.fontWeight, FontWeight.w600);
        expect(word.style?.color, _colors(tester).deep);
        expect(find.byType(BrushSign), findsNothing);
      });
    }

    for (final status in ['local', 'something_new']) {
      testWidgets('$status is the muted word On the device, no sign', (
        tester,
      ) async {
        await _pumpState(tester, status: status, compact: true);
        final word = tester.widget<Text>(find.text('On the device'));
        expect(word.style?.fontSize, 13);
        expect(word.style?.fontWeight, FontWeight.w600);
        expect(word.style?.color, _colors(tester).secondary);
        expect(find.byType(BrushSign), findsNothing);
      });
    }

    for (final status in _needsYouStatuses) {
      testWidgets('$status is the info sign on a 32 disc, read as Needs you', (
        tester,
      ) async {
        await _pumpState(tester, status: status, compact: true);
        final disc = tester.widget<AppDisc>(find.byType(AppDisc));
        expect(disc.tone, DiscTone.failed);
        expect(disc.size, DiscSize.small);
        expect(disc.pressable, isFalse);
        final sign = tester.widget<BrushSign>(find.byType(BrushSign));
        expect(sign.sign, Sign.info);
        expect(sign.size, 18);
        expect(sign.color, _colors(tester).onSoft);
        expect(find.text('Needs you'), findsNothing);
        expect(find.bySemanticsLabel('Needs you'), findsOneWidget);
      });
    }

    testWidgets('in dark the sent sign and the sending word take dark tones', (
      tester,
    ) async {
      await _pumpState(
        tester,
        status: 'uploaded',
        compact: true,
        theme: AppTheme.darkTheme,
      );
      expect(
        tester.widget<BrushSign>(find.byType(BrushSign)).color,
        const Color(0xFFA3C0B9),
      );
      await _pumpState(
        tester,
        status: 'uploading',
        compact: true,
        percent: 42,
        theme: AppTheme.darkTheme,
      );
      expect(
        tester.widget<Text>(find.text('Sending 42%')).style?.color,
        const Color(0xFFEBA573),
      );
    });

    testWidgets(
      'sending without a percent says Sending, nothing moves, no retry',
      (tester) async {
        await _pumpState(tester, status: 'uploading', compact: true);
        expect(find.text('Sending'), findsOneWidget);
        expect(tester.binding.transientCallbackCount, 0);
        expect(
          find.descendant(
            of: find.byType(UploadStatusBadge),
            matching: find.byType(RotationTransition),
          ),
          findsNothing,
        );
        await _pumpState(tester, status: 'failed', compact: true);
        expect(find.byType(TextButton), findsNothing);
        expect(find.text('Retry'), findsNothing);
      },
    );
  });

  group('send state on the recording page', () {
    const signs = {
      'uploaded': ('Sent', Sign.check),
      'uploading': ('Sending 42%', Sign.up),
      'local': ('On the device', Sign.device),
    };
    for (final entry in signs.entries) {
      testWidgets('${entry.key} is its sign then ${entry.value.$1} at 15', (
        tester,
      ) async {
        await _pumpState(tester, status: entry.key, percent: 42);
        final sign = tester.widget<BrushSign>(find.byType(BrushSign));
        expect(sign.sign, entry.value.$2);
        expect(sign.size, 18);
        final word = tester.widget<Text>(find.text(entry.value.$1));
        expect(word.style?.fontSize, 15);
        expect(word.style?.fontWeight, FontWeight.w600);
        expect(word.style?.color, sign.color);
        final signAt = tester.getTopLeft(find.byType(BrushSign)).dx;
        expect(
          signAt,
          lessThan(tester.getTopLeft(find.text(entry.value.$1)).dx),
        );
      });
    }

    testWidgets('needs you is the disc then the word Needs you', (
      tester,
    ) async {
      await _pumpState(tester, status: 'failed_exhausted');
      expect(find.byType(AppDisc), findsOneWidget);
      expect(find.text('Needs you'), findsOneWidget);
      expect(tester.widget<Text>(find.text('Needs you')).style?.fontSize, 15);
    });
  });

  group('send state under pressure', () {
    for (final status in ['uploading', 'local', 'failed']) {
      testWidgets(
        '$status ellipsizes at 2.0x in 80 wide, both forms, ltr and rtl',
        (tester) async {
          for (final compact in [true, false]) {
            for (final locale in const [Locale('en'), Locale('ar')]) {
              await _pumpState(
                tester,
                status: status,
                compact: compact,
                percent: 42,
                scale: 2.0,
                width: 80,
                locale: locale,
              );
              expectNoOverflow(tester);
            }
          }
        },
      );
    }
  });
}

const _needsYouStatuses = [
  'failed',
  'failed_exhausted',
  'failed_conflict',
  'failed_description',
  'failed_missing_file',
  'failed_refused_object_missing',
  'failed_refused',
];

AppColorSet _colors(WidgetTester tester) =>
    AppColors.of(tester.element(find.byType(UploadStatusBadge)));

Future<void> _pumpState(
  WidgetTester tester, {
  required String status,
  bool compact = false,
  int? percent,
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
