// ENG-178: the shared UploadStatusBadge must keep its label readable under large
// system fonts. Under severe width pressure it must ellipsize rather than
// overflow; the failed+retry variant must also render fully at scale.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/theme/app_colors.dart';
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

  testWidgets('failed state shows label and retry without overflow at 2.0x', (
    tester,
  ) async {
    await pumpAtTextScale(
      tester,
      scale: 2.0,
      child: Center(
        child: UploadStatusBadge(status: 'failed', onRetry: () {}),
      ),
    );
    await tester.pump();
    expect(find.text('Needs you'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expectNoOverflow(tester);
  });

  group('four send states', () {
    final cases = <String, (String, Color Function(AppColorSet))>{
      'local': ('On the device', (c) => c.secondary),
      'uploading': ('Sending', (c) => c.accent),
      'uploaded': ('Sent', (c) => c.infoText),
      'failed': ('Needs you', (c) => c.error),
    };
    for (final entry in cases.entries) {
      testWidgets('${entry.key} reads ${entry.value.$1} in its colour', (
        tester,
      ) async {
        await pumpAtTextScale(
          tester,
          child: Center(child: UploadStatusBadge(status: entry.key)),
        );
        final colors = AppColors.of(
          tester.element(find.byType(UploadStatusBadge)),
        );
        final text = tester.widget<Text>(find.text(entry.value.$1));
        expect(text.style?.color, entry.value.$2(colors));
      });
    }
  });
}
