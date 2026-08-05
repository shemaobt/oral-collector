/// The pill and the sheet that walk a user through what a recording still owes
/// (ENG-374).
///
/// Both are tested standalone rather than through RecordingDetailScreen: that
/// screen cannot be pumped in its loaded state, because the hero player takes
/// near-unbounded constraints under the test font.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:oral_collector/features/recording/domain/entities/review_pendency.dart';
import 'package:oral_collector/features/recording/presentation/widgets/complete_ficha_pill.dart';
import 'package:oral_collector/features/recording/presentation/widgets/complete_ficha_sheet.dart';
import 'package:oral_collector/l10n/app_localizations.dart';
import 'package:oral_collector/l10n/app_localizations_en.dart';

Widget host(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  group('the pill', () {
    testWidgets('a complete ficha gets no pill at all', (tester) async {
      await tester.pumpWidget(
        host(CompleteFichaPill(pendencyCount: 0, onTap: () {})),
      );

      // Not "an all good badge" — nothing. A finished ficha should stop
      // occupying the screen.
      expect(find.byType(CompleteFichaPill), findsOneWidget);
      expect(find.byIcon(LucideIcons.clipboardCheck), findsNothing);
    });

    testWidgets('shows how many fields are still open', (tester) async {
      await tester.pumpWidget(
        host(CompleteFichaPill(pendencyCount: 3, onTap: () {})),
      );

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('tapping it asks to open the guided flow', (tester) async {
      var opened = 0;
      await tester.pumpWidget(
        host(CompleteFichaPill(pendencyCount: 2, onTap: () => opened++)),
      );

      await tester.tap(find.byType(CompleteFichaPill));
      await tester.pump();

      expect(opened, 1);
    });
  });

  group('the sheet', () {
    testWidgets('lists one step per open field', (tester) async {
      await tester.pumpWidget(
        host(
          CompleteFichaSheet(
            steps: const [
              PendencyKind.classification,
              PendencyKind.description,
              PendencyKind.storyteller,
            ],
            resolved: const {},
            onStep: (_) {},
          ),
        ),
      );

      expect(find.byType(CompleteFichaStepTile), findsNWidgets(3));
    });

    testWidgets('a field the user already filled in reads as done', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          CompleteFichaSheet(
            steps: const [
              PendencyKind.classification,
              PendencyKind.storyteller,
            ],
            resolved: const {PendencyKind.classification},
            onStep: (_) {},
          ),
        ),
      );

      // The first step is ticked off, so its number gives way to a check mark;
      // the second still shows its position in the queue.
      expect(find.byIcon(LucideIcons.check), findsOneWidget);
      expect(find.text('1'), findsNothing);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('the subtitle counts what is still open, not the whole '
        'list', (tester) async {
      await tester.pumpWidget(
        host(
          CompleteFichaSheet(
            steps: const [
              PendencyKind.classification,
              PendencyKind.description,
              PendencyKind.storyteller,
            ],
            resolved: const {
              PendencyKind.classification,
              PendencyKind.description,
            },
            onStep: (_) {},
          ),
        ),
      );

      final en = AppLocalizationsEn();
      expect(
        find.text(en.recording_completeFichaSubtitle(1)),
        findsOneWidget,
        reason: 'two of the three steps are done, so one is still open',
      );
      expect(find.text(en.recording_completeFichaSubtitle(3)), findsNothing);
    });

    testWidgets('nothing left open means no count to report', (tester) async {
      await tester.pumpWidget(
        host(
          CompleteFichaSheet(
            steps: const [PendencyKind.classification],
            resolved: const {PendencyKind.classification},
            onStep: (_) {},
          ),
        ),
      );

      // Neither "0 fields are still open" nor a stale count of the whole list:
      // there is nothing left to report, so the line goes away.
      final en = AppLocalizationsEn();
      expect(find.text(en.recording_completeFichaSubtitle(0)), findsNothing);
      expect(find.text(en.recording_completeFichaSubtitle(1)), findsNothing);
      expect(find.text(en.recording_completeFichaTitle), findsOneWidget);
    });

    testWidgets('a step stays listed after it is done, so progress is '
        'visible', (tester) async {
      await tester.pumpWidget(
        host(
          CompleteFichaSheet(
            steps: const [PendencyKind.classification],
            resolved: const {PendencyKind.classification},
            onStep: (_) {},
          ),
        ),
      );

      // The step is not removed when it resolves — a row vanishing under the
      // user's finger is how you lose your place in a list.
      expect(find.byType(CompleteFichaStepTile), findsOneWidget);
    });

    testWidgets('tapping a step opens that field, not another', (tester) async {
      final opened = <PendencyKind>[];
      await tester.pumpWidget(
        host(
          CompleteFichaSheet(
            steps: const [
              PendencyKind.classification,
              PendencyKind.storyteller,
            ],
            resolved: const {},
            onStep: opened.add,
          ),
        ),
      );

      await tester.tap(
        find.byWidgetPredicate(
          (w) =>
              w is CompleteFichaStepTile && w.kind == PendencyKind.storyteller,
        ),
      );
      await tester.pump();

      expect(opened, [PendencyKind.storyteller]);
    });

    testWidgets('the primary action goes to the first unfinished step', (
      tester,
    ) async {
      final opened = <PendencyKind>[];
      await tester.pumpWidget(
        host(
          CompleteFichaSheet(
            steps: const [
              PendencyKind.classification,
              PendencyKind.description,
              PendencyKind.storyteller,
            ],
            resolved: const {PendencyKind.classification},
            onStep: opened.add,
          ),
        ),
      );

      await tester.tap(find.byKey(CompleteFichaSheet.ctaKey));
      await tester.pump();

      expect(opened, [PendencyKind.description]);
    });
  });
}
