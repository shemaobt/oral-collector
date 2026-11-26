import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../features/sync/presentation/notifiers/sync_notifier.dart';
import '../../l10n/app_localizations.dart';
import '../utils/sync_now.dart';
import 'brush_sign.dart';

class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final syncState = ref.watch(syncNotifierProvider);

    if (syncState.uploadingId != null || syncState.pendingCount == 0) {
      return const SizedBox.shrink();
    }

    return InkWell(
      onTap: () => syncNowWithFeedback(context, ref),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              BrushSign(Sign.offline, size: 18, color: colors.secondary),
              const SizedBox(width: 10),
              Text(
                l10n.sync_pending(syncState.pendingCount),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: colors.secondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
