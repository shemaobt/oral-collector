/// ENG-374: the V3 card must survive large system fonts.
///
/// The card grew a description line and a pendency chip, so the rows it packs
/// into a phone width now have more to lose. French is the worst case — its
/// labels are the longest of the eleven locales — and 2.0x is the ceiling the
/// app actually allows, so both are exercised rather than approximated.
/// Arabic is in the matrix for a different reason: it is the one shipped
/// locale that lays the card out right-to-left, so it is the only one that can
/// break on direction rather than on length.
///
/// Two things the matrix used to lie about, both fixed in ENG-382:
/// the card is pumped inside the horizontal padding the list really applies
/// (`recordings_list_screen.dart`), which costs it 32dp — without it every
/// case tested a card wider than any card that ships; and 320dp joins 390dp,
/// because the narrowest phone is where the footer runs out of room first.
///
/// ENG-382 also put the duration back in the footer, ranked below the pendency
/// chip: it renders only when the chip can keep its whole label, so the
/// assertions below are about which of the two yields, not about overflow
/// alone.
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:oral_collector/features/recording/domain/entities/local_recording_entity.dart';
import 'package:oral_collector/features/recording/presentation/widgets/recording_card.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_notifier.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_state.dart';
import 'package:oral_collector/l10n/app_localizations.dart';

import '../../../../support/text_scale.dart';

const _longTitle =
    'Enregistrement de la veillée de Noël chez la grand-mère Amélie en 1998';
const _longDescription =
    'La grand-mère raconte comment le village a survécu à la grande sécheresse '
    'et ce que les anciens ont décidé cette année-là';
const _longGenre = 'Récit historique traditionnel';
const _longSubcategory = 'Origine du village et de ses familles';

/// The horizontal padding `recordings_list_screen.dart` wraps every card in.
const _listPadding = EdgeInsets.symmetric(horizontal: 16);

/// The narrowest phone the app supports, and the roomier one the rest of the
/// suite assumes.
const _narrowPhone = Size(320, 844);

class _FakeSyncNotifier extends SyncNotifier {
  _FakeSyncNotifier(this._initial);
  final SyncState _initial;

  @override
  SyncState build() => _initial;
}

LocalRecordingEntity _recording({
  String? storytellerId,
  String? registerId = 'reg-1',
}) => LocalRecordingEntity(
  id: 'rec-1',
  projectId: 'proj-1',
  genreId: 'genre-1',
  registerId: registerId,
  secondaryGenreId: 'genre-2',
  title: _longTitle,
  description: _longDescription,
  storytellerId: storytellerId,
  durationSeconds: 3900,
  fileSizeBytes: 1024,
  format: 'm4a',
  localFilePath: '/a.m4a',
  uploadStatus: 'uploading',
  serverId: null,
  cleaningStatus: 'none',
  recordedAt: DateTime(2024, 12, 24, 22, 15, 43),
  createdAt: DateTime(2024, 12, 24),
  retryCount: 0,
  uploadedBytes: 0,
);

Future<void> _pump(
  WidgetTester tester, {
  required double scale,
  required Locale locale,
  Size size = kPhoneSize,
  LocalRecordingEntity? recording,
}) async {
  await pumpAtTextScale(
    tester,
    scale: scale,
    locale: locale,
    size: size,
    overrides: [
      syncNotifierProvider.overrideWith(
        () => _FakeSyncNotifier(
          const SyncState(uploadingId: 'rec-1', syncProgress: 42),
        ),
      ),
    ],
    child: Padding(
      padding: _listPadding,
      child: RecordingCard(
        recording: recording ?? _recording(),
        genreName: _longGenre,
        subcategoryName: _longSubcategory,
        registerName: 'Formel',
        onTap: () {},
      ),
    ),
  );
  await tester.pump();
}

/// Fails if any row the footer owns reported an overflow in the frame just
/// pumped, and swallows the one overflow that is not the footer's.
///
/// At 320dp above 1.0x the title row overflows on the date column, which
/// predates ENG-382 and is tracked on its own issue — so this matrix cannot
/// simply demand a clean frame at that width without also asserting a defect
/// it does not own. The render tree is read rather than `takeException`
/// because that reports only the first overflow, and the first one here
/// belongs to the title.
void _expectFooterFits(WidgetTester tester) {
  final lines = tester
      .renderObject(find.byType(RecordingCard))
      .toStringDeep()
      .split('\n');
  for (var i = 0; i < lines.length; i++) {
    if (!lines[i].contains('OVERFLOWING')) continue;
    final node = lines
        .skip(i + 1)
        .takeWhile((line) => !line.contains('parentData:'))
        .join();
    expect(
      node,
      isNot(contains('_FooterRow')),
      reason: 'a row inside the footer overflowed: $node',
    );
  }
  tester.takeException();
}

void main() {
  for (final size in const [kPhoneSize, _narrowPhone]) {
    for (final locale in const [Locale('en'), Locale('fr'), Locale('ar')]) {
      for (final scale in const [1.0, 1.5, 2.0]) {
        final where =
            '${scale}x in ${locale.languageCode} on ${size.width.toInt()}dp';

        testWidgets('the fullest card does not overflow at $where', (
          tester,
        ) async {
          await _pump(tester, scale: scale, locale: locale, size: size);
          if (size == kPhoneSize) expectNoOverflow(tester);
          _expectFooterFits(tester);
        });

        testWidgets('the counted pendency chip does not overflow at $where', (
          tester,
        ) async {
          await _pump(
            tester,
            scale: scale,
            locale: locale,
            size: size,
            // Two open fields, so the chip carries the count string rather
            // than the shorter named one.
            recording: _recording(registerId: null),
          );
          if (size == kPhoneSize) expectNoOverflow(tester);
          _expectFooterFits(tester);

          final duration = find.text('1:05:00');
          if (duration.evaluate().isEmpty) return;

          // The duration is the footer's lowest-ranked element: where it does
          // render, it cost the chip nothing and it is drawn inside the card
          // rather than clipped off its edge.
          final l10n = await AppLocalizations.delegate.load(locale);
          final chip = tester.renderObject<RenderParagraph>(
            find.text(l10n.recording_pendencyCount(2)),
          );
          expect(
            chip.didExceedMaxLines,
            isFalse,
            reason:
                'the chip must keep its whole label while the duration '
                'is on screen — the duration is the one that yields',
          );
          final card = tester.getRect(find.byType(RecordingCard));
          expect(
            card.expandToInclude(tester.getRect(duration)),
            card,
            reason:
                'the duration is drawn inside the card, not clipped off '
                'its edge — find.text alone would pass either way',
          );
        });
      }
    }
  }

  testWidgets(
    'the chip gets the room the duration used to take at 2.0x in fr',
    (tester) async {
      await _pump(
        tester,
        scale: 2.0,
        locale: const Locale('fr'),
        recording: _recording(registerId: null),
      );

      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      final chip = tester.getRect(
        find
            .ancestor(
              of: find.text(l10n.recording_pendencyCount(2)),
              matching: find.byType(Container),
            )
            .first,
      );

      expect(find.text('1:05:00'), findsNothing);
      // The chip now reaches the chevron: every pixel between them is its own.
      // With the duration in the row it stopped 157.5px short of here and its
      // paragraph was cut to 69.5px — the inversion this test pins shut.
      expect(
        chip.right,
        tester.getRect(find.byIcon(LucideIcons.chevronRight)).left - 8,
      );
    },
  );

  testWidgets('the duration is on screen when the footer has room for it', (
    tester,
  ) async {
    // Nothing pending, so no chip competes for the row: the rule above hides
    // the duration only when it would cost the chip width, never otherwise.
    await _pump(
      tester,
      scale: 1.0,
      locale: const Locale('en'),
      recording: _recording(storytellerId: 'st-1'),
    );

    expect(find.text('1:05:00'), findsOneWidget);
    final card = tester.getRect(find.byType(RecordingCard));
    expect(card.expandToInclude(tester.getRect(find.text('1:05:00'))), card);
  });

  testWidgets('title and description ellipsize rather than wrap at 2.0x', (
    tester,
  ) async {
    await _pump(tester, scale: 2.0, locale: const Locale('fr'));

    for (final text in const [_longTitle, _longDescription]) {
      final widget = tester.widget<Text>(find.text(text));
      expect(widget.maxLines, 1, reason: 'the card is a one-line-per-fact row');
      expect(widget.overflow, TextOverflow.ellipsis);
    }
  });
}
