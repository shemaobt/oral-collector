/// ENG-405: the detail screen's status card has to account for the metadata
/// outbox, not only for the audio upload.
///
/// The screen itself is not mountable in a widget test (the hero player blows
/// past 99k px under the test font), so the section is exercised on its own —
/// the same seam `upload_status_actions.dart` and `PendingWebUploadCard` use.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/theme/app_colors.dart';
import 'package:oral_collector/features/recording/domain/entities/local_recording_entity.dart';
import 'package:oral_collector/features/recording/domain/entities/pending_metadata_field.dart';
import 'package:oral_collector/features/recording/presentation/widgets/recording_status_section.dart';
import 'package:oral_collector/l10n/app_localizations.dart';

import '../../../../support/text_scale.dart';

const _waiting = 'Change waiting to be sent';
const _forbidden = 'Change refused — you cannot edit this recording';
const _conflict = 'Change refused — another recording has this title';
const _exhausted = 'Change not sent — attempts used up';

const _everyMark = [_waiting, _forbidden, _conflict, _exhausted];

LocalRecordingEntity _recording({
  String uploadStatus = 'uploaded',
  String metadataSyncStatus = MetadataSyncStatus.synced,
  Set<PendingMetadataField> pendingMetadataFields = const {},
}) => LocalRecordingEntity(
  id: 'rec-1',
  projectId: 'proj-1',
  genreId: 'genre-1',
  title: 'Story',
  durationSeconds: 60,
  fileSizeBytes: 1024,
  format: 'm4a',
  localFilePath: '/tmp/rec-1.m4a',
  uploadStatus: uploadStatus,
  serverId: 'srv-1',
  cleaningStatus: 'none',
  recordedAt: DateTime(2026, 1, 1),
  createdAt: DateTime(2026, 1, 1),
  retryCount: 0,
  uploadedBytes: 0,
  metadataSyncStatus: metadataSyncStatus,
  pendingMetadataFields: pendingMetadataFields,
);

Future<void> _pump(
  WidgetTester tester,
  LocalRecordingEntity recording, {
  double scale = 1.0,
}) async {
  await pumpAtTextScale(
    tester,
    scale: scale,
    child: SingleChildScrollView(
      child: Builder(
        builder: (context) => RecordingStatusSection(
          recording: recording,
          colors: AppColors.of(context),
          theme: Theme.of(context),
          onToggleCleaning: () {},
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('an edit waiting for the connection is accounted for', (
    tester,
  ) async {
    await _pump(
      tester,
      _recording(
        metadataSyncStatus: MetadataSyncStatus.pending,
        pendingMetadataFields: const {PendingMetadataField.title},
      ),
    );

    expect(find.text(_waiting), findsOneWidget);
  });

  testWidgets('a recording owing nothing gets no line about edits', (
    tester,
  ) async {
    await _pump(tester, _recording());

    for (final mark in _everyMark) {
      expect(find.text(mark), findsNothing, reason: 'unexpected line: $mark');
    }
  });

  testWidgets('a refused edit says which refusal it was', (tester) async {
    await _pump(
      tester,
      _recording(
        metadataSyncStatus: MetadataSyncStatus.failedConflict,
        pendingMetadataFields: const {PendingMetadataField.title},
      ),
    );

    expect(find.text(_conflict), findsOneWidget);
    // A title clash is fixed by renaming; a permission refusal cannot be
    // fixed by the person holding the phone. Same line for both would send
    // one of them the wrong way.
    expect(find.text(_forbidden), findsNothing);
    expect(find.text(_exhausted), findsNothing);
  });

  testWidgets('the upload line keeps its own answer', (tester) async {
    await _pump(
      tester,
      _recording(
        uploadStatus: 'verified',
        metadataSyncStatus: MetadataSyncStatus.failedForbidden,
        pendingMetadataFields: const {PendingMetadataField.title},
      ),
    );

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    // The audio is on the server. Only the edit is stuck, and the two lines
    // must not be read as one verdict.
    expect(find.text(l10n.detail_uploaded), findsOneWidget);
    expect(find.text(_forbidden), findsOneWidget);
  });

  for (final scale in const [1.5, 2.0]) {
    testWidgets('the refusal line survives ${scale}x', (tester) async {
      await _pump(
        tester,
        _recording(
          metadataSyncStatus: MetadataSyncStatus.failedConflict,
          pendingMetadataFields: const {PendingMetadataField.title},
        ),
        scale: scale,
      );

      expect(find.text(_conflict), findsOneWidget);
      expectNoOverflow(tester);
    });
  }
}
