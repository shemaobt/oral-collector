import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/tokens.dart';
import '../../features/sync/presentation/notifiers/sync_notifier.dart';
import '../../l10n/app_localizations.dart';
import '../utils/sync_now.dart';

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

    return Padding(
      padding: const EdgeInsets.only(right: SpacingScale.s8),
      child: ActionChip(
        avatar: Icon(LucideIcons.uploadCloud, size: 16, color: colors.accent),
        label: Text(
          l10n.sync_pending(syncState.pendingCount),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: colors.foreground,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: colors.accent.withValues(alpha: 0.1),
        side: BorderSide(color: colors.accent.withValues(alpha: 0.2)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusScale.r20),
        ),
        onPressed: () => syncNowWithFeedback(context, ref),
      ),
    );
  }
}
