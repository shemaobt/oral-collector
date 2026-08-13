import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_notifier.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_state.dart';
import 'package:oral_collector/l10n/app_localizations.dart';
import 'package:oral_collector/l10n/app_localizations_en.dart';
import 'package:oral_collector/shared/widgets/sync_status_indicator.dart';

class _FakeSyncNotifier extends SyncNotifier {
  _FakeSyncNotifier(this._initial);
  final SyncState _initial;

  @override
  SyncState build() => _initial;
}

/// A queue the Wi-Fi-only policy refuses to run (ENG-355).
class _BlockedSyncNotifier extends SyncNotifier {
  @override
  SyncState build() => const SyncState(isOnline: true, pendingCount: 2);

  @override
  Future<void> syncAll() async {
    state = state.copyWith(blockReason: SyncBlockReason.wifiOnly);
  }
}

class _RunningSyncNotifier extends SyncNotifier {
  @override
  SyncState build() => const SyncState(isOnline: true, pendingCount: 2);

  @override
  Future<void> syncAll() async {
    state = state.copyWith(lastSyncAt: DateTime(2026), pendingCount: 0);
  }
}

Widget _harnessWith(Override override) {
  return ProviderScope(
    overrides: [override],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SyncStatusIndicator()),
    ),
  );
}

Widget _harness(SyncState state) => _harnessWith(
  syncNotifierProvider.overrideWith(() => _FakeSyncNotifier(state)),
);

void main() {
  testWidgets('hidden when nothing is pending or uploading', (tester) async {
    await tester.pumpWidget(_harness(const SyncState()));
    await tester.pumpAndSettle();

    expect(find.byType(ActionChip), findsNothing);
  });

  testWidgets('hidden when actively uploading (cards take over)', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(const SyncState(uploadingId: 'r1', pendingCount: 3)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ActionChip), findsNothing);
  });

  testWidgets('visible with pending count when offline queue is non-empty', (
    tester,
  ) async {
    await tester.pumpWidget(_harness(const SyncState(pendingCount: 4)));
    await tester.pumpAndSettle();

    expect(find.byType(ActionChip), findsOneWidget);
    expect(find.textContaining('4'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  // Tapping the chip used to be a dead button whenever the Wi-Fi-only policy
  // held the queue back: it blinked and came back with the same number.
  group('the tap reports back (ENG-355)', () {
    final AppLocalizations l10n = AppLocalizationsEn();

    Future<void> tapChip(WidgetTester tester) async {
      await tester.tap(find.byType(ActionChip));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    testWidgets('a queue held back by Wi-Fi-only says so', (tester) async {
      await tester.pumpWidget(
        _harnessWith(
          syncNotifierProvider.overrideWith(_BlockedSyncNotifier.new),
        ),
      );
      await tester.pumpAndSettle();

      await tapChip(tester);

      expect(find.text(l10n.sync_waitingForWifi), findsOneWidget);
    });

    testWidgets('a queue that runs says nothing', (tester) async {
      await tester.pumpWidget(
        _harnessWith(
          syncNotifierProvider.overrideWith(_RunningSyncNotifier.new),
        ),
      );
      await tester.pumpAndSettle();

      await tapChip(tester);

      expect(find.text(l10n.sync_waitingForWifi), findsNothing);
    });
  });
}
