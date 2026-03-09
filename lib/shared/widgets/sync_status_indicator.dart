import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../features/sync/data/providers/sync_provider.dart';

/// AppBar widget showing "X pending uploads" badge.
///
/// Shows nothing when there are no pending uploads.
/// Tapping triggers a manual sync when online.
class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  color: AppColors.primary,
                ),
              )
            : Icon(
                LucideIcons.cloudUpload,
                size: 16,
                color: AppColors.primary,
              ),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.foreground,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        onPressed: isUploading
            ? null
            : () => ref.read(syncNotifierProvider.notifier).syncAll(),
      ),
    );
  }
}
