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
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/theme/app_colors.dart';
import 'package:oral_collector/features/recording/domain/entities/local_recording_entity.dart';
import 'package:oral_collector/features/recording/domain/entities/pending_metadata_field.dart';
import 'package:oral_collector/features/recording/presentation/widgets/recording_card.dart';
import 'package:oral_collector/l10n/app_localizations.dart';

import '../../../../support/text_scale.dart';

/// Written out rather than read off `AppLocalizations`, so the assertions fail
/// when the card stops saying these things — not merely when a key is renamed.
const _waiting = 'Change waiting to be sent';
const _forbidden = 'Change refused — you cannot edit this recording';
const _conflict = 'Change refused — another recording has this title';
const _exhausted = 'Change not sent — attempts used up';

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

/// The glyph the card draws beside [label], read off the innermost row that
/// carries the text.
Icon _markIcon(WidgetTester tester, String label) => tester.widget<Icon>(
  find
      .descendant(
        of: find.ancestor(of: find.text(label), matching: find.byType(Row)),
        matching: find.byType(Icon),
      )
      .first,
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

        expect(_markIcon(tester, entry.value).color, _errorToken(tester));
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
        _markIcon(tester, _waiting).color,
        isNot(_errorToken(tester)),
        reason: 'a routine wait must not be painted as a failure',
      );
    });

    testWidgets('a wait and a refusal do not share a glyph', (tester) async {
      await _pumpCard(
        tester,
        _recording(
          metadataSyncStatus: MetadataSyncStatus.pending,
          pendingMetadataFields: const {PendingMetadataField.title},
        ),
      );
      final waiting = _markIcon(tester, _waiting).icon;

      await _pumpCard(
        tester,
        _recording(
          metadataSyncStatus: MetadataSyncStatus.failedForbidden,
          pendingMetadataFields: const {PendingMetadataField.title},
        ),
      );

      // Colour alone would say nothing under a colour-blind eye or a
      // grayscale filter.
      expect(_markIcon(tester, _forbidden).icon, isNot(waiting));
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

  group('large fonts', () {
    for (final size in const [kPhoneSize, _narrowPhone]) {
      for (final scale in const [1.5, 2.0]) {
        final where = '${scale}x on ${size.width.toInt()}dp';

        testWidgets('the waiting mark survives $where', (tester) async {
          await _pumpCard(
            tester,
            _recording(
              metadataSyncStatus: MetadataSyncStatus.pending,
              pendingMetadataFields: const {PendingMetadataField.title},
            ),
            scale: scale,
            size: size,
          );

          expect(find.text(_waiting), findsOneWidget);
          expectNoOverflow(tester);
        });

        testWidgets('the longest refusal survives $where', (tester) async {
          await _pumpCard(
            tester,
            _recording(
              metadataSyncStatus: MetadataSyncStatus.failedConflict,
              pendingMetadataFields: const {PendingMetadataField.title},
            ),
            scale: scale,
            size: size,
          );

          expect(find.text(_conflict), findsOneWidget);
          expectNoOverflow(tester);
        });
      }
    }
  });
}
