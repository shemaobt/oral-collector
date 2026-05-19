import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_notifier.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_state.dart';
import 'package:oral_collector/l10n/app_localizations.dart';
import 'package:oral_collector/shared/widgets/sync_status_indicator.dart';

class _FakeSyncNotifier extends SyncNotifier {
  _FakeSyncNotifier(this._initial);
  final SyncState _initial;

  @override
  SyncState build() => _initial;
}

Widget _harness(SyncState state) {
  return ProviderScope(
    overrides: [
      syncNotifierProvider.overrideWith(() => _FakeSyncNotifier(state)),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: SyncStatusIndicator()),
    ),
  );
}

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
}
