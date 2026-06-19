/// Characterization gate for RecordingDetailScreen (ENG-194).
///
/// Pins the screen's player-free render wiring (initState → load → state →
/// build branch) so the extraction of RecordingDetailNotifier and the later
/// build() decomposition cannot change it.
///
/// Scope note: the loaded state can't be pumped in a widget test — the hero
/// player/waveform takes near-unbounded constraints under the flutter_test
/// font (~99k px RenderFlex overflow), which is why this screen was never
/// widget-tested. The loaded/classified/permission behaviour is characterized
/// at the notifier level instead (recording_detail_notifier_test.dart); the
/// section widgets get their own focused tests when extracted. This file pins
/// the not-found resolution, the one state that renders without the player.
library;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/database/app_database.dart';
import 'package:oral_collector/features/recording/data/providers.dart';
import 'package:oral_collector/features/recording/data/repositories/local_recording_repository.dart';
import 'package:oral_collector/features/recording/domain/entities/server_recording.dart';
import 'package:oral_collector/features/recording/domain/repositories/recording_api_repository.dart';
import 'package:oral_collector/features/recording/presentation/recording_detail_screen.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_notifier.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_state.dart';
import 'package:oral_collector/l10n/app_localizations.dart';

import '../../../support/text_scale.dart';

class _FakeApiRepo implements RecordingApiRepository {
  @override
  Future<ServerRecording> getRecording(String id) =>
      throw StateError('getRecording not expected offline');
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not expected');
}

class _OfflineSyncNotifier extends SyncNotifier {
  @override
  SyncState build() => const SyncState();
  @override
  Future<void> processQueue() async {}
}

void main() {
  const recordingId = 'rec-1';

  late AppDatabase db;
  late LocalRecordingRepository repo;
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = LocalRecordingRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await pumpAtTextScale(
      tester,
      overrides: [
        localRecordingRepositoryProvider.overrideWithValue(repo),
        // The real Drift watch stream leaves a pending Timer that flutter_test
        // flags on teardown; the screen reads the row directly during load, so
        // an empty stream is enough here.
        localRecordingStreamProvider(
          recordingId,
        ).overrideWith((ref) => const Stream<LocalRecording?>.empty()),
        recordingApiRepositoryProvider.overrideWithValue(_FakeApiRepo()),
        syncNotifierProvider.overrideWith(_OfflineSyncNotifier.new),
      ],
      child: const RecordingDetailScreen(recordingId: recordingId),
    );
  }

  testWidgets('an absent recording renders the not-found state', (
    tester,
  ) async {
    // Empty db + offline -> load resolves to null without hitting the API, and
    // the null branch renders before any player widget is built.
    await pumpScreen(tester);
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }

    expect(find.text(l10n.recording_notFound), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
