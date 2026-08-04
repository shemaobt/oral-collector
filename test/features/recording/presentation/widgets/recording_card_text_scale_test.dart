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
/// ENG-382 put the duration back in the footer, so the worst case now also
/// carries an hour-long `1:05:00` next to a two-pendency chip. Overflow alone
/// would not catch a regression that silently drops the duration to buy room,
/// so the fullest footer asserts the string is still on screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/recording/domain/entities/local_recording_entity.dart';
import 'package:oral_collector/features/recording/presentation/widgets/recording_card.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_notifier.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_state.dart';

import '../../../../support/text_scale.dart';

const _longTitle =
    'Enregistrement de la veillée de Noël chez la grand-mère Amélie en 1998';
const _longDescription =
    'La grand-mère raconte comment le village a survécu à la grande sécheresse '
    'et ce que les anciens ont décidé cette année-là';
const _longGenre = 'Récit historique traditionnel';
const _longSubcategory = 'Origine du village et de ses familles';

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
  LocalRecordingEntity? recording,
}) async {
  await pumpAtTextScale(
    tester,
    scale: scale,
    locale: locale,
    overrides: [
      syncNotifierProvider.overrideWith(
        () => _FakeSyncNotifier(
          const SyncState(uploadingId: 'rec-1', syncProgress: 42),
        ),
      ),
    ],
    child: RecordingCard(
      recording: recording ?? _recording(),
      genreName: _longGenre,
      subcategoryName: _longSubcategory,
      registerName: 'Formel',
      onTap: () {},
    ),
  );
  await tester.pump();
}

void main() {
  for (final locale in const [Locale('en'), Locale('fr'), Locale('ar')]) {
    for (final scale in const [1.0, 1.5, 2.0]) {
      testWidgets('the fullest card does not overflow at ${scale}x in '
          '${locale.languageCode}', (tester) async {
        await _pump(tester, scale: scale, locale: locale);
        expectNoOverflow(tester);
      });

      testWidgets('the counted pendency chip does not overflow at ${scale}x in '
          '${locale.languageCode}', (tester) async {
        await _pump(
          tester,
          scale: scale,
          locale: locale,
          // Two open fields, so the chip carries the count string rather
          // than the shorter named one.
          recording: _recording(registerId: null),
        );
        expectNoOverflow(tester);
        expect(
          find.text('1:05:00'),
          findsOneWidget,
          reason:
              'the duration must survive the tightest footer, not be '
              'dropped to make the chip fit',
        );
      });
    }
  }

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
