import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/sync/presentation/notifiers/sync_notifier.dart';
import '../../features/sync/presentation/notifiers/sync_state.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/error_snack_bar.dart';

/// Drains the upload queue and reports back at the control the user pressed.
///
/// The queue can decline to run (Wi-Fi-only policy over cellular). Without this
/// the request looks like a dead button: the chip blinks and comes back with
/// the same number (ENG-355).
Future<void> syncNowWithFeedback(BuildContext context, WidgetRef ref) async {
  await ref.read(syncNotifierProvider.notifier).syncAll();
  if (!context.mounted) return;

  if (ref.read(syncNotifierProvider).blockReason == SyncBlockReason.wifiOnly) {
    showErrorSnackBar(
      context,
      '',
      template: (_) => AppLocalizations.of(context).sync_waitingForWifi,
    );
  }
}
