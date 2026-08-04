/// What the list card says a recording still owes (ENG-374, card V3).
///
/// The list answers "which recordings need me?" — so the card names the gap
/// without accusing, shows at most one chip, and never leans on colour alone.
///
/// Every fixture here is a recording the server already knows about, so the
/// chip follows its review flags rather than the local columns (ENG-379); the
/// columns are set to match only so the rest of the card stays coherent.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/recording/domain/entities/local_recording_entity.dart';
import 'package:oral_collector/features/recording/domain/entities/review_flag.dart';
import 'package:oral_collector/features/recording/presentation/widgets/recording_card.dart';
import 'package:oral_collector/l10n/app_localizations.dart';

void main() {
  LocalRecordingEntity recording({
    String genreId = 'genre-1',
    String? registerId = 'reg-1',
    String? description = 'Uma descrição longa o bastante para o piso da regra',
    String? storytellerId = 'st-1',
    String? title = 'Uma gravação',
    String uploadStatus = 'uploaded',
    List<ReviewFlag> reviewFlags = const [],
  }) => LocalRecordingEntity(
    id: 'rec-1',
    projectId: 'proj-1',
    genreId: genreId,
    registerId: registerId,
    title: title,
    description: description,
    storytellerId: storytellerId,
    durationSeconds: 60,
    fileSizeBytes: 1024,
    format: 'm4a',
    localFilePath: '/a.m4a',
    uploadStatus: uploadStatus,
    serverId: 'srv-1',
    cleaningStatus: 'none',
    recordedAt: DateTime(2026, 3, 10, 16, 20, 8),
    createdAt: DateTime(2026, 3, 10),
    retryCount: 0,
    uploadedBytes: 0,
    reviewFlags: reviewFlags,
  );

  Future<void> pumpCard(WidgetTester tester, LocalRecordingEntity r) =>
      tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: RecordingCard(
                recording: r,
                genreName: 'Conto',
                subcategoryName: 'Origem',
                registerName: 'Formal',
                onTap: () {},
              ),
            ),
          ),
        ),
      );

  group('the pendency chip', () {
    testWidgets('a complete recording gets no chip', (tester) async {
      await pumpCard(tester, recording());

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text(l10n.recording_pendencyClassification), findsNothing);
      expect(find.text(l10n.recording_pendencyDescription), findsNothing);
      expect(find.text(l10n.recording_pendencyStoryteller), findsNothing);
    });

    testWidgets('one open field is named, not counted', (tester) async {
      await pumpCard(
        tester,
        recording(
          storytellerId: null,
          reviewFlags: const [
            ReviewFlag(code: 'missing_storyteller', origin: 'system'),
          ],
        ),
      );

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      // "Sem narrador" tells the user what to do. "1 pendência" does not.
      expect(find.text(l10n.recording_pendencyStoryteller), findsOneWidget);
    });

    testWidgets('two open fields collapse into a count', (tester) async {
      await pumpCard(
        tester,
        recording(
          storytellerId: null,
          description: 'curta',
          reviewFlags: const [
            ReviewFlag(code: 'missing_storyteller', origin: 'system'),
            ReviewFlag(code: 'insufficient_description', origin: 'system'),
          ],
        ),
      );

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text(l10n.recording_pendencyCount(2)), findsOneWidget);
      // At most one chip per card — naming both would crowd the row the
      // description just moved into.
      expect(find.text(l10n.recording_pendencyStoryteller), findsNothing);
      expect(find.text(l10n.recording_pendencyDescription), findsNothing);
    });

    testWidgets('three open fields still show a single chip', (tester) async {
      await pumpCard(
        tester,
        recording(
          genreId: 'unclassified',
          registerId: null,
          description: '',
          storytellerId: null,
          reviewFlags: const [
            ReviewFlag(code: 'missing_classification', origin: 'system'),
            ReviewFlag(code: 'insufficient_description', origin: 'system'),
            ReviewFlag(code: 'missing_storyteller', origin: 'system'),
          ],
        ),
      );

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text(l10n.recording_pendencyCount(3)), findsOneWidget);
    });
  });

  group('the description line', () {
    testWidgets('a recording with no description does not show the line', (
      tester,
    ) async {
      await pumpCard(tester, recording(description: null));

      expect(find.byType(RecordingDescriptionLine), findsNothing);
    });

    testWidgets('a description of nothing but spaces does not show the line', (
      tester,
    ) async {
      await pumpCard(tester, recording(description: '   '));

      // The card used to disagree with the description rule about whitespace
      // and drew quotation marks around three spaces.
      expect(find.byType(RecordingDescriptionLine), findsNothing);
    });

    testWidgets('a description that meets the rule is shown plainly', (
      tester,
    ) async {
      await pumpCard(tester, recording());

      expect(
        find.text('Uma descrição longa o bastante para o piso da regra'),
        findsOneWidget,
      );
    });

    testWidgets('a description too short to count is quoted', (tester) async {
      await pumpCard(tester, recording(description: 'curta'));

      // Quotes mark it as the user's own words falling short, rather than the
      // app silently treating it as absent.
      expect(find.text('\u201Ccurta\u201D'), findsOneWidget);
    });

    testWidgets('the card quotes stay legible around a quoted description', (
      tester,
    ) async {
      await pumpCard(tester, recording(description: '"oi"'));

      // Straight ASCII quotes on both sides rendered as ""oi"", which reads as
      // one confused string rather than as the app quoting the user.
      expect(find.text('""oi""'), findsNothing);
      expect(find.text('\u201C"oi"\u201D'), findsOneWidget);
    });

    testWidgets('a short description says so to a screen reader', (
      tester,
    ) async {
      await pumpCard(tester, recording(description: 'curta'));

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      final text = tester.widget<Text>(
        find.descendant(
          of: find.byType(RecordingDescriptionLine),
          matching: find.byType(Text),
        ),
      );
      // Quotation marks are not announced at default verbosity, and with two
      // or more open fields the chip only carries a count, so nothing else on
      // the card says this line is the deficient one.
      expect(
        text.semanticsLabel,
        '${l10n.recording_pendencyDescription}: curta',
      );
    });

    testWidgets('a sufficient description is announced as written', (
      tester,
    ) async {
      await pumpCard(tester, recording());

      final text = tester.widget<Text>(
        find.descendant(
          of: find.byType(RecordingDescriptionLine),
          matching: find.byType(Text),
        ),
      );
      expect(text.semanticsLabel, isNull);
    });
  });
}
