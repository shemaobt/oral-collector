// ENG-180: SyncSettingsCard must not overflow under large system fonts. Its
// list tiles wrap/grow inside a scroll view; this guards 1.0/1.3/2.0x.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/core/theme/app_colors.dart';
import 'package:oral_collector/features/profile/presentation/widgets/sync_settings_card.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_notifier.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_state.dart';

import '../../../../support/text_scale.dart';

class _FakeSyncNotifier extends SyncNotifier {
  // The card reads sync state from the `syncState` param; this notifier exists
  // only to satisfy the storage-snapshot provider, so its state is irrelevant.
  @override
  SyncState build() => const SyncState();

  @override
  Future<({int usedBytes, int freeBytes, int totalBytes})>
  getStorageSnapshot() async =>
      (usedBytes: 1024, freeBytes: 2048, totalBytes: 4096);
}

const _syncState = SyncState(isOnline: true, pendingCount: 3);

Future<void> _pump(WidgetTester tester, double scale) async {
  await pumpAtTextScale(
    tester,
    scale: scale,
    overrides: [syncNotifierProvider.overrideWith(_FakeSyncNotifier.new)],
    child: SingleChildScrollView(
      child: SyncSettingsCard(
        syncState: _syncState,
        theme: ThemeData.light(),
        colors: AppColors.light,
        onSyncNow: () {},
        onWifiOnlyChanged: (_) {},
        onAutoRemoveChanged: (_) {},
        onClearCache: () {},
      ),
    ),
  );
  await tester.pump();
}

void main() {
  for (final scale in const [1.0, 1.3, 2.0]) {
    testWidgets('does not overflow at ${scale}x', (tester) async {
      await _pump(tester, scale);
      expectNoOverflow(tester);
    });
  }
}
