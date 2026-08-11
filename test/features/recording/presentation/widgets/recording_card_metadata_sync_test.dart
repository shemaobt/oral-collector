/// ENG-405: an edit the server has not taken has to be visible on the card.
///
/// Two states, not one. A recording merely waiting for the connection to come
/// back needs nothing from the user, so its mark must not alarm; one the server
/// refused for good will never go up on its own, so its mark must. A single
/// mark for both would either frighten people about a routine wait or hide the
/// edit that is actually stranded.
///
/// The upload of the audio and the sync of the metadata are independent axes,
/// so the new mark is also checked against a recording whose audio is safely on
/// the server: it must not make that recording read as un-uploaded.
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/theme/app_colors.dart';
import 'package:oral_collector/features/recording/domain/entities/local_recording_entity.dart';
import 'package:oral_collector/features/recording/domain/entities/pending_metadata_field.dart';
import 'package:oral_collector/features/recording/presentation/widgets/metadata_sync_mark.dart';
import 'package:oral_collector/features/recording/presentation/widgets/recording_card.dart';
import 'package:oral_collector/l10n/app_localizations.dart';

import '../../../../support/text_scale.dart';

/// Written out rather than read off `AppLocalizations`, so the assertions fail
/// when the card stops saying these things — not merely when a key is renamed.
const _waiting = 'Edit waiting to be sent';
const _forbidden = 'Edit refused: you cannot change this recording';
const _conflict = 'Edit refused: another recording has this title';
const _exhausted = 'Edit not sent — edit again to retry';

const _everyMark = [_waiting, _forbidden, _conflict, _exhausted];

/// The horizontal padding `recordings_list_screen.dart` wraps every card in.
const _listPadding = EdgeInsets.symmetric(horizontal: 16);

/// The narrowest phone the app supports.
const _narrowPhone = Size(320, 844);

LocalRecordingEntity _recording({
  String metadataSyncStatus = MetadataSyncStatus.synced,
  Set<PendingMetadataField> pendingMetadataFields = const {},
  String uploadStatus = 'uploaded',
}) => LocalRecordingEntity(
  id: 'rec-1',
  projectId: 'proj-1',
  genreId: 'genre-1',
  registerId: 'reg-1',
  title: 'Uma gravação',
  description: 'Uma descrição longa o bastante para o piso da regra',
  storytellerId: 'st-1',
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
  metadataSyncStatus: metadataSyncStatus,
  pendingMetadataFields: pendingMetadataFields,
);

Future<void> _pumpCard(
  WidgetTester tester,
  LocalRecordingEntity recording, {
  double scale = 1.0,
  Size size = kPhoneSize,
}) async {
  await pumpAtTextScale(
    tester,
    scale: scale,
    size: size,
    child: Padding(
      padding: _listPadding,
      child: RecordingCard(
        recording: recording,
        genreName: 'Conto',
        subcategoryName: 'Origem',
        registerName: 'Formal',
        onTap: () {},
      ),
    ),
  );
  await tester.pump();
}

/// The glyph the card draws for the mark.
///
/// Addressed through the mark's own type rather than by walking up to some
/// enclosing `Row`: that walk happened to land on the right one only because
/// of the order finders return ancestors in, and would silently start reading
/// a different icon the day the mark gains a wrapper.
Icon _markIcon(WidgetTester tester) => tester.widget<Icon>(
  find.descendant(
    of: find.byType(RecordingMetadataSyncMark),
    matching: find.byType(Icon),
  ),
);

/// The mark's text as the card actually lays it out.
RenderParagraph _markParagraph(WidgetTester tester) =>
    tester.renderObject<RenderParagraph>(
      find.descendant(
        of: find.byType(RecordingMetadataSyncMark),
        matching: find.byType(Text),
      ),
    );

Color _errorToken(WidgetTester tester) =>
    AppColors.of(tester.element(find.byType(RecordingCard))).error;

void main() {
  testWidgets('a recording with an unsent edit is marked on the card', (
    tester,
  ) async {
    await _pumpCard(
      tester,
      _recording(
        metadataSyncStatus: MetadataSyncStatus.pending,
        pendingMetadataFields: const {PendingMetadataField.title},
      ),
    );

    expect(find.text(_waiting), findsOneWidget);
  });

  testWidgets('a recording with nothing owed carries no mark', (tester) async {
    await _pumpCard(tester, _recording());

    for (final mark in _everyMark) {
      expect(find.text(mark), findsNothing, reason: 'unexpected mark: $mark');
    }
  });

  testWidgets('the mark goes once the edit reaches the server', (tester) async {
    await _pumpCard(
      tester,
      _recording(
        metadataSyncStatus: MetadataSyncStatus.pending,
        pendingMetadataFields: const {PendingMetadataField.description},
      ),
    );
    expect(find.text(_waiting), findsOneWidget);

    await _pumpCard(tester, _recording());

    expect(find.text(_waiting), findsNothing);
  });

  group('a refusal does not read like a wait', () {
    const cases = {
      MetadataSyncStatus.failedForbidden: _forbidden,
      MetadataSyncStatus.failedConflict: _conflict,
      MetadataSyncStatus.failedExhausted: _exhausted,
    };

    for (final entry in cases.entries) {
      testWidgets('${entry.key} names its own cause', (tester) async {
        await _pumpCard(
          tester,
          _recording(
            metadataSyncStatus: entry.key,
            pendingMetadataFields: const {PendingMetadataField.title},
          ),
        );

        expect(find.text(entry.value), findsOneWidget);
        // Each refusal has a different way out — a rename, a permission, a
        // retry — so one shared "could not send" line would strand the user.
        for (final other in _everyMark.where((m) => m != entry.value)) {
          expect(find.text(other), findsNothing);
        }
      });

      testWidgets('${entry.key} is drawn as trouble', (tester) async {
        await _pumpCard(
          tester,
          _recording(
            metadataSyncStatus: entry.key,
            pendingMetadataFields: const {PendingMetadataField.title},
          ),
        );

        expect(_markIcon(tester).color, _errorToken(tester));
      });
    }

    testWidgets('a wait is not', (tester) async {
      await _pumpCard(
        tester,
        _recording(
          metadataSyncStatus: MetadataSyncStatus.pending,
          pendingMetadataFields: const {PendingMetadataField.title},
        ),
      );

      // Reconnecting is all it takes, and the person cannot make that happen
      // any faster by being alarmed about it.
      expect(
        _markIcon(tester).color,
        isNot(_errorToken(tester)),
        reason: 'a routine wait must not be painted as a failure',
      );
    });

    testWidgets('no two states share a glyph', (tester) async {
      final glyphs = <String, IconData?>{};
      for (final status in const [
        MetadataSyncStatus.pending,
        MetadataSyncStatus.failedForbidden,
        MetadataSyncStatus.failedConflict,
        MetadataSyncStatus.failedExhausted,
      ]) {
        await _pumpCard(
          tester,
          _recording(
            metadataSyncStatus: status,
            pendingMetadataFields: const {PendingMetadataField.title},
          ),
        );
        glyphs[status] = _markIcon(tester).icon;
      }

      // Colour says nothing under a colour-blind eye or a grayscale filter,
      // and the three refusals all share the error token — so between *them*
      // the glyph is the only channel left. A wait against a refusal is the
      // easy half of this; refusal against refusal is the half that was not
      // pinned.
      expect(
        glyphs.values.toSet(),
        hasLength(glyphs.length),
        reason: 'two states drew the same glyph: $glyphs',
      );
    });
  });

  testWidgets('an unsent edit does not make an uploaded recording read as '
      'un-uploaded', (tester) async {
    await _pumpCard(
      tester,
      _recording(
        uploadStatus: 'verified',
        metadataSyncStatus: MetadataSyncStatus.failedConflict,
        pendingMetadataFields: const {PendingMetadataField.title},
      ),
    );

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(_conflict), findsOneWidget);
    // The audio is on the server; only the rename is stuck. The upload glyph
    // has to keep saying so.
    expect(
      find.byWidgetPredicate(
        (w) => w is Icon && w.semanticLabel == l10n.recording_statusUploaded,
      ),
      findsOneWidget,
    );
  });

  /// `find.text` matches the string the widget was *handed*, not the glyphs
  /// that reached the screen — so a mark whose second half was ellipsized still
  /// satisfies every assertion above. Only the laid-out paragraph knows, which
  /// is the lesson ENG-185 already paid for: assert geometry, not the absence
  /// of an exception.
  ///
  /// Measured before this group existed: the two long refusals were cut on a
  /// 320dp phone at 1.0x, and on 390dp from 1.5x. A cut warning is worse than
  /// a short one — the cause and the way out both live at the end of the
  /// sentence.
  group('the whole message reaches the screen', () {
    for (final size in const [kPhoneSize, _narrowPhone]) {
      for (final scale in const [1.0, 1.5, 2.0]) {
        for (final entry in const {
          MetadataSyncStatus.pending: _waiting,
          MetadataSyncStatus.failedForbidden: _forbidden,
          MetadataSyncStatus.failedConflict: _conflict,
          MetadataSyncStatus.failedExhausted: _exhausted,
        }.entries) {
          final where = '${entry.key} at ${scale}x on ${size.width.toInt()}dp';

          testWidgets('$where is not cut short', (tester) async {
            await _pumpCard(
              tester,
              _recording(
                metadataSyncStatus: entry.key,
                pendingMetadataFields: const {PendingMetadataField.title},
              ),
              scale: scale,
              size: size,
            );

            expect(find.text(entry.value), findsOneWidget);
            expect(
              _markParagraph(tester).didExceedMaxLines,
              isFalse,
              reason: 'the mark was ellipsized at $where',
            );
            expectNoOverflow(tester);
          });
        }
      }
    }
  });
}
