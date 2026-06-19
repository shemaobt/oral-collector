import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:oral_collector/features/recording/domain/entities/local_recording_entity.dart';
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

LocalRecordingEntity _makeRecording({
  String id = 'rec-1',
  String uploadStatus = 'uploading',
  String? secondaryGenreId,
}) => LocalRecordingEntity(
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
  secondaryGenreId: secondaryGenreId,
  cleaningStatus: 'none',
  recordedAt: DateTime(2024, 1, 1),
  createdAt: DateTime(2024, 1, 1),
  retryCount: 0,
  resumableSessionUri: null,
  uploadedBytes: 0,
);

Widget _harness({
  required LocalRecordingEntity recording,
  required SyncState state,
}) {
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

  testWidgets(
    'shows the also-classified icon when the recording has a secondary '
    'classification',
    (tester) async {
      await tester.pumpWidget(
        _harness(
          recording: _makeRecording(secondaryGenreId: 'genre-2'),
          state: const SyncState(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(LucideIcons.layers), findsOneWidget);
    },
  );

  testWidgets(
    'hides the also-classified icon when there is no secondary classification',
    (tester) async {
      await tester.pumpWidget(
        _harness(recording: _makeRecording(), state: const SyncState()),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(LucideIcons.layers), findsNothing);
    },
  );
}
