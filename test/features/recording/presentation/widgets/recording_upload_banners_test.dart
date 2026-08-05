/// The banners that explain why a recording is not on the server.
///
/// Each one names a reason and offers the single action that clears it, so what
/// matters here is which banner a status produces and which action it offers.
/// Only two can ever be on screen at once — a recording has one uploadStatus,
/// so the status banners are mutually exclusive, and the secondary-collision
/// warning is the only one that stacks with them.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/recording/domain/entities/local_recording_entity.dart';
import 'package:oral_collector/features/recording/presentation/widgets/recording_action_banner.dart';
import 'package:oral_collector/features/recording/presentation/widgets/recording_upload_banners.dart';
import 'package:oral_collector/l10n/app_localizations.dart';

LocalRecordingEntity _makeRecording({
  String uploadStatus = 'local',
  String? secondaryGenreId,
}) => LocalRecordingEntity(
  id: 'rec-1',
  projectId: 'proj-1',
  genreId: 'genre-1',
  subcategoryId: null,
  title: 'Test recording',
  durationSeconds: 60.0,
  fileSizeBytes: 1024,
  format: 'm4a',
  localFilePath: '/tmp/test.m4a',
  uploadStatus: uploadStatus,
  serverId: null,
  gcsUrl: null,
  registerId: null,
  secondaryGenreId: secondaryGenreId,
  cleaningStatus: 'none',
  recordedAt: DateTime(2024, 1, 1),
  createdAt: DateTime(2024, 1, 1),
  retryCount: 0,
  resumableSessionUri: null,
  uploadedBytes: 0,
);

Widget _harness(
  LocalRecordingEntity recording, {
  bool canEdit = true,
  VoidCallback? onRetryUpload,
  VoidCallback? onDelete,
}) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: RecordingUploadBanners(
      recording: recording,
      canEdit: canEdit,
      onEditDetails: () {},
      onRetryUpload: onRetryUpload ?? () {},
      onDelete: onDelete ?? () {},
      onClearSecondary: () {},
    ),
  ),
);

/// The action label of every banner on screen, top to bottom.
List<String> _actionLabels(WidgetTester tester) => tester
    .widgetList<RecordingActionBanner>(find.byType(RecordingActionBanner))
    .map((b) => b.actionLabel)
    .toList();

void main() {
  testWidgets('a recording with nothing wrong shows no banner', (tester) async {
    await tester.pumpWidget(_harness(_makeRecording()));

    expect(find.byType(RecordingActionBanner), findsNothing);
  });

  testWidgets('an exhausted upload is offered a retry', (tester) async {
    await tester.pumpWidget(
      _harness(_makeRecording(uploadStatus: 'failed_exhausted')),
    );

    expect(
      find.text(
        'The upload stopped after several attempts. You can try again.',
      ),
      findsOneWidget,
    );
    expect(_actionLabels(tester), ['Retry']);
  });

  testWidgets('tapping retry on an exhausted upload requeues it', (
    tester,
  ) async {
    var retries = 0;
    await tester.pumpWidget(
      _harness(
        _makeRecording(uploadStatus: 'failed_exhausted'),
        onRetryUpload: () => retries++,
      ),
    );

    await tester.tap(find.text('Retry'));
    await tester.pump();

    expect(retries, 1);
  });

  testWidgets('a missing audio file is offered a delete, never a retry', (
    tester,
  ) async {
    var deletes = 0;
    await tester.pumpWidget(
      _harness(
        _makeRecording(uploadStatus: 'failed_missing_file'),
        onDelete: () => deletes++,
      ),
    );

    // Retrying cannot conjure the audio back: the engine already looked in all
    // three places the app puts a recording, and deletion is a hard delete.
    // Offering it would be a button that fails the same way every time.
    expect(_actionLabels(tester), ['Delete']);

    await tester.tap(find.text('Delete'));
    await tester.pump();

    expect(deletes, 1);
  });

  testWidgets('a viewer who cannot edit still gets the explanation', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        _makeRecording(uploadStatus: 'failed_missing_file'),
        canEdit: false,
      ),
    );

    expect(find.byType(RecordingActionBanner), findsOneWidget);
    final banner = tester.widget<RecordingActionBanner>(
      find.byType(RecordingActionBanner),
    );
    expect(banner.onAction, isNull);
  });

  testWidgets('the exhausted retry is offered regardless of edit rights', (
    tester,
  ) async {
    // Requeueing an upload the device already owns is not an edit of the
    // recording, so it is not gated like one.
    await tester.pumpWidget(
      _harness(
        _makeRecording(uploadStatus: 'failed_exhausted'),
        canEdit: false,
      ),
    );

    final banner = tester.widget<RecordingActionBanner>(
      find.byType(RecordingActionBanner),
    );
    expect(banner.onAction, isNotNull);
  });

  testWidgets('the upload banner always precedes the classification warning', (
    tester,
  ) async {
    // Only two banners can ever be on screen at once: a recording has one
    // uploadStatus, so the four status banners are mutually exclusive, and the
    // secondary-collision warning is the only one that stacks with them. That
    // pair is the whole of the order — and it runs this way because the
    // collision is a classification nit, not the reason the upload is stuck.
    const statuses = {
      'failed_conflict': 'Edit details',
      'failed_description': 'Edit details',
      'failed_exhausted': 'Retry',
      'failed_missing_file': 'Delete',
    };

    for (final entry in statuses.entries) {
      await tester.pumpWidget(
        _harness(
          _makeRecording(uploadStatus: entry.key, secondaryGenreId: 'genre-1'),
        ),
      );

      expect(_actionLabels(tester), [entry.value, 'Clear secondary']);
    }
  });
}
