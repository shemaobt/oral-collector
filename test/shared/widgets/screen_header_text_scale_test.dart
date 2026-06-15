// ENG-178: the shared ScreenHeader / ScreenHeaderSliver must keep the title and
// subtitle inside the fixed 96px toolbar under large system fonts without
// overflowing. Rendered on a realistic phone viewport via pumpAtTextScale.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:oral_collector/shared/widgets/screen_header.dart';

import '../../support/text_scale.dart';

const _title = 'Recordings Library Overview';
const _subtitle = 'All of your captured stories in one place';

void main() {
  group('ScreenHeader (AppBar)', () {
    Future<void> pump(WidgetTester tester, double scale) async {
      await pumpAtTextScale(
        tester,
        scale: scale,
        child: const Scaffold(
          appBar: ScreenHeader(
            title: _title,
            subtitle: _subtitle,
            icon: LucideIcons.listMusic,
          ),
          body: SizedBox.expand(),
        ),
      );
      await tester.pump();
    }

    for (final scale in const [1.0, 1.3, 2.0]) {
      testWidgets('does not overflow at ${scale}x', (tester) async {
        await pump(tester, scale);
        expectNoOverflow(tester);
      });
    }

    testWidgets('title stays in the tree at 2.0x', (tester) async {
      await pump(tester, 2.0);
      expect(find.text(_title), findsOneWidget);
    });
  });

  group('ScreenHeaderSliver', () {
    Future<void> pump(WidgetTester tester, double scale) async {
      await pumpAtTextScale(
        tester,
        scale: scale,
        child: const CustomScrollView(
          slivers: [
            ScreenHeaderSliver(
              title: _title,
              subtitle: _subtitle,
              icon: LucideIcons.listMusic,
            ),
            SliverFillRemaining(child: SizedBox()),
          ],
        ),
      );
      await tester.pump();
    }

    for (final scale in const [1.0, 1.3, 2.0]) {
      testWidgets('does not overflow at ${scale}x', (tester) async {
        await pump(tester, scale);
        expectNoOverflow(tester);
      });
    }

    testWidgets('title stays in the tree at 2.0x', (tester) async {
      await pump(tester, 2.0);
      expect(find.text(_title), findsOneWidget);
    });
  });
}
