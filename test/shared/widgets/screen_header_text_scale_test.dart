import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/theme/app_theme.dart';
import 'package:oral_collector/shared/widgets/app_disc.dart';
import 'package:oral_collector/shared/widgets/screen_header.dart';

import '../../support/text_scale.dart';

const _title = 'Recordings Library Overview';

void main() {
  group('ScreenHeader (AppBar)', () {
    Future<void> pump(WidgetTester tester, double scale) async {
      await pumpAtTextScale(
        tester,
        scale: scale,
        theme: AppTheme.lightTheme,
        child: const Scaffold(
          appBar: ScreenHeader(title: _title),
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

    for (final (scale, height) in const [
      (1.0, 54.0),
      (1.3, 57.9),
      (2.0, 57.9),
    ]) {
      testWidgets('the row grows to ${height}px at ${scale}x', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await pump(tester, scale);
        expect(
          tester.getSize(find.byType(AppBar)).height,
          closeTo(height, 0.1),
        );
        expect(
          tester.getSize(find.text(_title)).height,
          closeTo(39.9 * (scale > 1.3 ? 1.3 : scale), 0.2),
        );
      });
    }

    testWidgets(
      'the back disc sits 20px from the edge and the title under it',
      (tester) async {
        await pumpAtTextScale(
          tester,
          child: Scaffold(
            appBar: ScreenHeader(title: _title, onBack: () {}),
            body: const SizedBox.expand(),
          ),
        );
        await tester.pump();
        expect(tester.getTopLeft(find.byType(AppDisc)).dx, 20);
        expect(tester.getTopLeft(find.text(_title)).dx, 20);
      },
    );

    testWidgets(
      'the back and each action are their own nodes, not the heading',
      (tester) async {
        final handle = tester.ensureSemantics();
        await pumpAtTextScale(
          tester,
          child: Scaffold(
            appBar: ScreenHeader(
              title: _title,
              onBack: () {},
              actions: [
                Semantics(
                  label: 'Filters',
                  button: true,
                  child: const SizedBox(width: 48, height: 48),
                ),
              ],
            ),
            body: const SizedBox.expand(),
          ),
        );
        await tester.pump();
        final back = MaterialLocalizations.of(
          tester.element(find.byType(ScreenHeader)),
        ).backButtonTooltip;
        expect(find.bySemanticsLabel(back), findsOneWidget);
        expect(find.bySemanticsLabel('Filters'), findsOneWidget);
        expect(
          tester.getSemantics(find.text(_title)),
          isSemantics(label: _title, isHeader: true, isButton: false),
        );
        expect(
          tester.getSemantics(find.bySemanticsLabel('Filters')),
          isSemantics(label: 'Filters', isButton: true, isHeader: false),
        );
        expect(
          tester.getSemantics(find.bySemanticsLabel(back)),
          isSemantics(label: back, isButton: true, isHeader: false),
        );
        handle.dispose();
      },
    );
  });

  group('ScreenHeaderSliver', () {
    Future<void> pump(WidgetTester tester, double scale) async {
      await pumpAtTextScale(
        tester,
        scale: scale,
        child: const CustomScrollView(
          slivers: [
            ScreenHeaderSliver(title: _title),
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
