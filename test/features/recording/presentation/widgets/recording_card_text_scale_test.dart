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
/// ENG-384 closed the last hole in that matrix. It used to run four widths
/// short of the phones that ship and, worse, it demanded a clean frame only at
/// 390dp: everywhere else a local helper read the render tree and failed only
/// when the overflowing node belonged to the footer, so an overflow of the
/// title line was found and swallowed on purpose. That exemption is gone —
/// every case now asserts `expectNoOverflow`, nothing swallows an overflow,
/// and 360dp and 375dp join the two widths that were already here.
///
/// Overflow is only half of what the title line can get wrong, so the matrix
/// also pins how the line is *divided*. The date is capped at a share of the
/// row and, past that share, moves to a line of its own instead of clipping —
/// which is what keeps the title from being rationed down to its ellipsis at
/// 2.0x. Two groups below assert the two ends of that: the title owns the
/// majority of its line at 2.0x, and at 1.0x the date is still beside it.
///
/// ENG-382 also put the duration back in the footer, ranked below the pendency
/// chip: it renders only when the chip can keep its whole label, so the
/// assertions below are about which of the two yields, not about overflow
/// alone. Card V3 then moved the classification into that same footer, which
/// outranks the duration too — on a phone the row now has no spare width, so
/// the duration is in practice gone. The ranking is still what decides it, and
/// the test at the bottom pins both ends of that.
///
/// One caveat the assertions are written around: no font is loaded in
/// `flutter_test`, so every glyph measures one em. That overstates real text
/// by roughly 1.7x, which makes the gate conservative rather than lax — but it
/// also means the date crosses its share far earlier here than on a device, so
/// nothing below asserts that the date is *present* at a given width. Where it
/// renders, it is asserted on; where it does not, the case says nothing.
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
import 'package:oral_collector/shared/utils/format.dart';

import '../../../../support/text_scale.dart';

const _longTitle =
    'Enregistrement de la veillée de Noël chez la grand-mère Amélie en 1998';
const _longArabicTitle =
    'تسجيل سهرة عيد الميلاد في بيت الجدة أميلي سنة ١٩٩٨ في القرية القديمة';
const _longDescription =
    'La grand-mère raconte comment le village a survécu à la grande sécheresse '
    'et ce que les anciens ont décidé cette année-là';
const _longGenre = 'Récit historique traditionnel';
const _longSubcategory = 'Origine du village et de ses familles';

/// The horizontal padding `recordings_list_screen.dart` wraps every card in.
const _listPadding = EdgeInsets.symmetric(horizontal: 16);

/// Every phone width the app has to hold, narrowest first: the floor it
/// supports, the two ordinary Android and iPhone widths, and `kPhoneSize`, the
/// roomier one the rest of the suite assumes.
const _phoneSizes = [
  Size(320, 844),
  Size(360, 844),
  Size(375, 844),
  kPhoneSize,
];

/// When the card was recorded — the instant `_recording` carries, and what the
/// date column is asked to render.
final _recordedAt = DateTime(2024, 12, 24, 22, 15, 43);

class _FakeSyncNotifier extends SyncNotifier {
  _FakeSyncNotifier(this._initial);
  final SyncState _initial;

  @override
  SyncState build() => _initial;
}

LocalRecordingEntity _recording({
  String? storytellerId,
  String? registerId = 'reg-1',
  String title = _longTitle,
}) => LocalRecordingEntity(
  id: 'rec-1',
  projectId: 'proj-1',
  genreId: 'genre-1',
  registerId: registerId,
  secondaryGenreId: 'genre-2',
  title: title,
  description: _longDescription,
  storytellerId: storytellerId,
  durationSeconds: 3900,
  fileSizeBytes: 1024,
  format: 'm4a',
  localFilePath: '/a.m4a',
  uploadStatus: 'uploading',
  serverId: null,
  cleaningStatus: 'none',
  recordedAt: _recordedAt,
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
  String? genreName = _longGenre,
  String? subcategoryName = _longSubcategory,
  String? registerName = 'Formel',
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
        genreName: genreName,
        subcategoryName: subcategoryName,
        registerName: registerName,
        onTap: () {},
      ),
    ),
  );
  await tester.pump();
}

/// The date string the card is asked to paint for [locale].
///
/// The formatter is the production one so the finder tracks whatever the card
/// renders; nothing here asserts on the shape of the string itself.
Future<String> _dateText(Locale locale) async => formatRecordingDate(
  _recordedAt,
  locale.languageCode,
  l10n: await AppLocalizations.delegate.load(locale),
);

/// The width the card's content column has, measured off the description line
/// — the one row that always spans the whole of it.
double _contentWidth(WidgetTester tester) =>
    tester.getSize(find.byType(RecordingDescriptionLine)).width;

void main() {
  for (final size in _phoneSizes) {
    for (final locale in const [Locale('en'), Locale('fr'), Locale('ar')]) {
      for (final scale in const [1.0, 1.5, 2.0]) {
        final where =
            '${scale}x in ${locale.languageCode} on ${size.width.toInt()}dp';

        testWidgets('the fullest card does not overflow at $where', (
          tester,
        ) async {
          await _pump(tester, scale: scale, locale: locale, size: size);
          expectNoOverflow(tester);
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
          expectNoOverflow(tester);

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

  for (final size in _phoneSizes) {
    final width = size.width.toInt();

    testWidgets('the title keeps the majority of its line at 2.0x in ar on '
        '${width}dp', (tester) async {
      await _pump(
        tester,
        scale: 2.0,
        locale: const Locale('ar'),
        size: size,
        recording: _recording(title: _longArabicTitle),
      );

      final title = tester.getSize(find.text(_longArabicTitle));
      expect(
        title.width,
        greaterThan(_contentWidth(tester) / 2),
        reason:
            'the title is what says which recording this is, so at the '
            'largest scale the app allows it owns most of the line it is on '
            '— a title rationed below that renders as its ellipsis and '
            'nothing else',
      );
    });

    testWidgets('nothing on the title line is lost at 1.0x in en on '
        '${width}dp', (tester) async {
      await _pump(tester, scale: 1.0, locale: const Locale('en'), size: size);

      final date = find.text(await _dateText(const Locale('en')));
      expect(
        tester.renderObject<RenderParagraph>(date).didExceedMaxLines,
        isFalse,
        reason:
            'a date cut mid-string names a day that is not the recording\'s '
            '— at the scale most users read at it keeps its whole label, '
            'wherever the line it ends up on is',
      );
      final card = tester.getRect(find.byType(RecordingCard));
      for (final rect in [
        tester.getRect(find.text(_longTitle)),
        tester.getRect(date),
      ]) {
        expect(card.expandToInclude(rect), card);
      }
    });
  }

  testWidgets('the date shares the title line at 1.0x on the reference phone', (
    tester,
  ) async {
    await _pump(tester, scale: 1.0, locale: const Locale('en'));

    expect(
      tester.getRect(find.text(await _dateText(const Locale('en')))).center.dy,
      moreOrLessEquals(
        tester.getRect(find.text(_longTitle)).center.dy,
        epsilon: 1,
      ),
      reason:
          'the title line is one line at the size most users read at — the '
          'reflow is what the date needs, not what the scale says',
    );
  });

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

  testWidgets('the duration yields to the classification on a phone, and '
      'comes back where the row is genuinely wide', (tester) async {
    // Nothing pending here, so no chip competes for the row — and the duration
    // is gone anyway. Card V3 moved the classification into this footer, and
    // that is what now outranks it: on a phone the row has no spare width,
    // which is the design package's "the duration does not come back", reached
    // through ENG-382's ranking rather than by deleting it.
    await _pump(
      tester,
      scale: 1.0,
      locale: const Locale('en'),
      recording: _recording(storytellerId: 'st-1'),
    );

    expect(find.text('1:05:00'), findsNothing);

    // The rule is about room, not about the duration being unwanted: shorten
    // the classification to what an ordinary one costs and it renders, inside
    // the card. Same width, same scale — only the competing text changed.
    await _pump(
      tester,
      scale: 1.0,
      locale: const Locale('en'),
      recording: _recording(storytellerId: 'st-1'),
      genreName: 'Conte',
      subcategoryName: null,
      registerName: null,
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
