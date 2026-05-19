import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/features/recording/presentation/widgets/recording_card.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_notifier.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_state.dart';
import 'package:oral_collector/l10n/app_localizations.dart';

class _FakeSyncNotifier extends SyncNotifier {
  _FakeSyncNotifier(this._initial);
  final SyncState _initial;

  @override
  SyncState build() => _initial;
}

LocalRecording _makeRecording({
  String id = 'rec-1',
  String uploadStatus = 'uploading',
}) => LocalRecording(
  id: id,
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
  cleaningStatus: 'none',
  recordedAt: DateTime(2024, 1, 1),
  createdAt: DateTime(2024, 1, 1),
  retryCount: 0,
  lastRetryAt: null,
  resumableSessionUri: null,
  uploadedBytes: 0,
  md5Hash: null,
);

Widget _harness({required LocalRecording recording, required SyncState state}) {
  return ProviderScope(
    overrides: [
      syncNotifierProvider.overrideWith(() => _FakeSyncNotifier(state)),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: RecordingCard(
          recording: recording,
          genreName: 'Folktale',
          formattedDuration: '01:00',
          onTap: () {},
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('no progress bar when nothing is uploading', (tester) async {
    await tester.pumpWidget(
      _harness(recording: _makeRecording(), state: const SyncState()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('no progress bar when a different recording is uploading', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        recording: _makeRecording(id: 'rec-1'),
        state: const SyncState(uploadingId: 'rec-2', syncProgress: 80),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets(
    'shows progress bar and percent when this recording is uploading',
    (tester) async {
      await tester.pumpWidget(
        _harness(
          recording: _makeRecording(id: 'rec-1'),
          state: const SyncState(uploadingId: 'rec-1', syncProgress: 42),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('42%'), findsOneWidget);
    },
  );
}
