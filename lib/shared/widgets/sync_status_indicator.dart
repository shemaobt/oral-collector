import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../features/sync/presentation/notifiers/sync_notifier.dart';

class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final syncState = ref.watch(syncNotifierProvider);

    if (syncState.pendingCount == 0 && syncState.uploadingId == null) {
      return const SizedBox.shrink();
    }

    final isUploading = syncState.uploadingId != null;
    final label = isUploading
        ? 'Uploading...'
        : '${syncState.pendingCount} pending';

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: isUploading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.accent,
                ),
              )
            : Icon(LucideIcons.uploadCloud, size: 16, color: colors.accent),
        label: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: colors.foreground,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: colors.accent.withValues(alpha: 0.1),
        side: BorderSide(color: colors.accent.withValues(alpha: 0.2)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onPressed: isUploading
            ? null
            : () => ref.read(syncNotifierProvider.notifier).syncAll(),
      ),
    );
  }
}
