import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/recording/presentation/widgets/recording_upload_progress_section.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_notifier.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_state.dart';
import 'package:oral_collector/l10n/app_localizations.dart';

class _FakeSyncNotifier extends SyncNotifier {
  _FakeSyncNotifier(this._initial);
  final SyncState _initial;

  @override
  SyncState build() => _initial;
}

Widget _harness({required SyncState state, required String recordingId}) {
  return ProviderScope(
    overrides: [
      syncNotifierProvider.overrideWith(() => _FakeSyncNotifier(state)),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: RecordingUploadProgressSection(recordingId: recordingId),
      ),
    ),
  );
}

void main() {
  testWidgets('hidden when uploadingId is null', (tester) async {
    await tester.pumpWidget(
      _harness(state: const SyncState(), recordingId: 'r1'),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.textContaining('%'), findsNothing);
  });

  testWidgets('hidden when uploadingId differs from recordingId', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        state: const SyncState(uploadingId: 'other', syncProgress: 50),
        recordingId: 'r1',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets(
    'renders progress bar, bytes, speed, and ETA when uploadingId matches',
    (tester) async {
      const oneMb = 1024 * 1024;
      await tester.pumpWidget(
        _harness(
          state: const SyncState(
            uploadingId: 'r1',
            syncProgress: 42,
            totalUploadedBytes: 8 * oneMb,
            totalQueueSizeBytes: 100 * oneMb,
            uploadSpeedBps: 2.0 * oneMb,
          ),
          recordingId: 'r1',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('42%'), findsOneWidget);
      expect(find.text('8.0 MB / 100.0 MB'), findsOneWidget);
      expect(find.text('2.0 MB/s'), findsOneWidget);
      // ETA = (100 - 8) MB / 2 MB/s = 46 s
      expect(find.text('~46s remaining'), findsOneWidget);
    },
  );

  testWidgets('omits speed and ETA when uploadSpeedBps is zero', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        state: const SyncState(
          uploadingId: 'r1',
          syncProgress: 10,
          totalUploadedBytes: 1024 * 1024,
          totalQueueSizeBytes: 10 * 1024 * 1024,
        ),
        recordingId: 'r1',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.textContaining('/s'), findsNothing);
    expect(find.textContaining('remaining'), findsNothing);
  });
}
