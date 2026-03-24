import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../features/sync/presentation/notifiers/sync_notifier.dart';
import '../../features/recording/data/providers.dart';
import '../utils/format.dart';

void showUploadQueueSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, controller) =>
          _UploadQueueContent(scrollController: controller),
    ),
  );
}

class _UploadQueueContent extends ConsumerWidget {
  const _UploadQueueContent({required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncNotifierProvider);
    final colors = AppColors.of(context);
    final theme = Theme.of(context);

    final overallProgress = syncState.totalQueueSizeBytes > 0
        ? syncState.totalUploadedBytes / syncState.totalQueueSizeBytes
        : 0.0;

    final eta = syncState.estimatedTimeRemaining;

    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: colors.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.upload, size: 20, color: colors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Upload Queue',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${syncState.pendingCount} pending',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.foreground.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: overallProgress.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: colors.border.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation(colors.primary),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${formatFileSize(syncState.totalUploadedBytes)} / ${formatFileSize(syncState.totalQueueSizeBytes)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.foreground.withValues(alpha: 0.6),
                    ),
                  ),
                  if (eta != null)
                    Text(
                      '~${_formatEta(eta)} remaining',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.foreground.withValues(alpha: 0.6),
                      ),
                    ),
                  if (syncState.uploadSpeedBps > 0)
                    Text(
                      '${formatFileSize(syncState.uploadSpeedBps.round())}/s',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.foreground.withValues(alpha: 0.6),
                      ),
                    ),
                ],
              ),
              if (syncState.currentFileName != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        value: syncState.syncProgress / 100,
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        syncState.currentFileName!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${syncState.syncProgress}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: _PendingFilesList(scrollController: scrollController)),
      ],
    );
  }

  String _formatEta(Duration d) {
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    if (d.inMinutes > 0) return '${d.inMinutes}m';
    return '${d.inSeconds}s';
  }
}

class _PendingFilesList extends ConsumerWidget {
  const _PendingFilesList({required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(localRecordingRepositoryProvider);
    final syncState = ref.watch(syncNotifierProvider);
    final colors = AppColors.of(context);
    final theme = Theme.of(context);

    return FutureBuilder(
      future: repo.getPendingUploads(),
      builder: (context, snapshot) {
        final recordings = snapshot.data ?? [];

        if (recordings.isEmpty) {
          return Center(
            child: Text(
              'No pending uploads',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.foreground.withValues(alpha: 0.5),
              ),
            ),
          );
        }

        return ListView.separated(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: recordings.length,
          separatorBuilder: (context, index) => const SizedBox(height: 4),
          itemBuilder: (context, index) {
            final rec = recordings[index];
            final isUploading = rec.id == syncState.uploadingId;
            final isFailed = rec.uploadStatus == 'failed';

            return ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              leading: Icon(
                isUploading
                    ? LucideIcons.uploadCloud
                    : isFailed
                    ? LucideIcons.alertCircle
                    : LucideIcons.fileAudio,
                size: 20,
                color: isUploading
                    ? colors.primary
                    : isFailed
                    ? colors.error
                    : colors.foreground.withValues(alpha: 0.5),
              ),
              title: Text(
                rec.title ?? rec.id,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: isUploading ? FontWeight.w600 : FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${rec.format.toUpperCase()} \u2022 ${formatFileSize(rec.fileSizeBytes)}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.foreground.withValues(alpha: 0.5),
                ),
              ),
              trailing: isUploading
                  ? SizedBox(
                      width: 40,
                      child: Text(
                        '${syncState.syncProgress}%',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    )
                  : isFailed
                  ? Icon(LucideIcons.refreshCw, size: 16, color: colors.error)
                  : null,
            );
          },
        );
      },
    );
  }
}
