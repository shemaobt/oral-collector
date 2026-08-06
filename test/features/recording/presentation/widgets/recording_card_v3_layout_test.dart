/// The card's three rows, against the design package's "Card V3".
///
/// The card had four: title, classification, description, footer. The package
/// puts the upload glyph up on the title line and folds the classification into
/// the footer, which is what buys the ~76px/~92px heights — the vertical budget
/// is the whole point of the redesign, so the assertions below are geometric.
/// Finding the right glyphs somewhere in the tree would pass with the old
/// four-row layout intact.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:oral_collector/core/theme/app_colors.dart';
import 'package:oral_collector/features/recording/domain/entities/local_recording_entity.dart';
import 'package:oral_collector/features/recording/presentation/widgets/recording_card.dart';
import 'package:oral_collector/l10n/app_localizations.dart';
import 'package:oral_collector/l10n/app_localizations_en.dart';

final _l10n = AppLocalizationsEn();

LocalRecordingEntity _recording({
  String? title = 'Uma gravação',
  String? description = 'Uma descrição longa o bastante para o piso da regra',
  String genreId = 'genre-1',
  String? registerId = 'reg-1',
  String? storytellerId = 'st-1',
  String uploadStatus = 'uploaded',
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
  serverId: null,
  cleaningStatus: 'none',
  recordedAt: DateTime(2026, 3, 10, 16, 20, 8),
  createdAt: DateTime(2026, 3, 10),
  retryCount: 0,
  uploadedBytes: 0,
);

Future<void> _pump(
  WidgetTester tester,
  LocalRecordingEntity recording, {
  String? genreName = 'Conto',
  String? subcategoryName = 'Origem',
  String? registerName = 'Formal',
}) => tester.pumpWidget(
  ProviderScope(
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: RecordingCard(
          recording: recording,
          genreName: genreName,
          subcategoryName: subcategoryName,
          registerName: registerName,
          onTap: () {},
        ),
      ),
    ),
  ),
);

/// How far apart two centres may sit and still count as the same line. Well
/// under a line height, so a row that slipped onto its own line fails.
const double _sameLineTolerance = 6;

void main() {
  group('the title line', () {
    testWidgets('carries the upload glyph, which no longer rides in the '
        'footer', (tester) async {
      await _pump(tester, _recording(uploadStatus: 'local'));

      final glyph = tester.getCenter(find.byIcon(LucideIcons.smartphone));
      final title = tester.getCenter(find.text('Uma gravação'));
      final chevron = tester.getCenter(find.byIcon(LucideIcons.chevronRight));

      expect((glyph.dy - title.dy).abs(), lessThan(_sameLineTolerance));
      expect(glyph.dy, lessThan(chevron.dy));
    });

    testWidgets('an uploaded recording gets the sent glyph on that same line', (
      tester,
    ) async {
      await _pump(tester, _recording());

      final glyph = tester.getCenter(find.byIcon(LucideIcons.checkCircle2));
      final title = tester.getCenter(find.text('Uma gravação'));

      expect((glyph.dy - title.dy).abs(), lessThan(_sameLineTolerance));
    });
  });

  group('the footer', () {
    testWidgets('carries the whole classification, register included', (
      tester,
    ) async {
      await _pump(tester, _recording());

      expect(find.text('Conto > Origem > Formal'), findsOneWidget);
    });

    testWidgets('sits the classification on the chevron line, not on one of '
        'its own', (tester) async {
      await _pump(tester, _recording());

      final classification = tester.getCenter(
        find.text('Conto > Origem > Formal'),
      );
      final chevron = tester.getCenter(find.byIcon(LucideIcons.chevronRight));

      expect(
        (classification.dy - chevron.dy).abs(),
        lessThan(_sameLineTolerance),
      );
    });

    testWidgets('marks the classification with a tag', (tester) async {
      await _pump(tester, _recording());

      final tag = tester.getCenter(find.byIcon(LucideIcons.tag));
      final chevron = tester.getCenter(find.byIcon(LucideIcons.chevronRight));

      expect((tag.dy - chevron.dy).abs(), lessThan(_sameLineTolerance));
    });
  });

  group('an unclassified recording', () {
    testWidgets('is named in italic rather than painted as a system warning', (
      tester,
    ) async {
      // Warning is reserved for system trouble — a corrupted file, a failed
      // upload. Spending it on an empty field tells the user something broke.
      await _pump(
        tester,
        _recording(genreId: '', registerId: null),
        genreName: null,
        subcategoryName: null,
        registerName: null,
      );

      final label = tester.widget<Text>(
        find.text(_l10n.recording_unclassified),
      );
      final colors = AppColors.of(
        tester.element(find.text(_l10n.recording_unclassified)),
      );

      expect(label.style?.fontStyle, FontStyle.italic);
      expect(label.style?.color, colors.secondary);
      expect(label.style?.color, isNot(colors.warning));
    });
  });

  group('the pendency chip', () {
    testWidgets('names the open field with its own glyph', (tester) async {
      await _pump(tester, _recording(storytellerId: null));

      expect(find.byIcon(LucideIcons.userMinus), findsOneWidget);
      expect(find.text(_l10n.recording_pendencyStoryteller), findsOneWidget);
    });

    testWidgets('a weak description gets the page glyph', (tester) async {
      await _pump(tester, _recording(description: 'oi'));

      expect(find.byIcon(LucideIcons.fileText), findsOneWidget);
    });

    testWidgets('a missing classification borrows the same tag the footer '
        'labels the classification with', (tester) async {
      await _pump(
        tester,
        _recording(genreId: '', registerId: null),
        genreName: null,
        subcategoryName: null,
        registerName: null,
      );

      // Two now: the footer's label and the chip's.
      expect(find.byIcon(LucideIcons.tag), findsNWidgets(2));
    });

    testWidgets('two or more open fields drop the per-kind glyph along with '
        'the per-kind name', (tester) async {
      await _pump(tester, _recording(description: 'oi', storytellerId: null));

      expect(find.text(_l10n.recording_pendencyCount(2)), findsOneWidget);
      expect(find.byIcon(LucideIcons.userMinus), findsNothing);
      expect(find.byIcon(LucideIcons.fileText), findsNothing);
    });
  });
}
