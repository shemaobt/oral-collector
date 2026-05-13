import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/utils/format.dart';
import '../../../sync/presentation/notifiers/sync_notifier.dart';

class RecordingUploadProgressSection extends ConsumerWidget {
  const RecordingUploadProgressSection({super.key, required this.recordingId});

  final String recordingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncNotifierProvider);
    if (syncState.uploadingId != recordingId) {
      return const SizedBox.shrink();
    }

    final colors = AppColors.of(context);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final eta = syncState.estimatedTimeRemaining;
    final progress = (syncState.syncProgress / 100).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.uploadCloud, size: 16, color: colors.accent),
              const SizedBox(width: 8),
              Text(
                l10n.recording_statusUploading,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.accent,
                ),
              ),
              const Spacer(),
              Text(
                '${syncState.syncProgress}%',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: colors.border.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation(colors.accent),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              Text(
                '${formatFileSize(syncState.totalUploadedBytes)} / ${formatFileSize(syncState.totalQueueSizeBytes)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.foreground.withValues(alpha: 0.7),
                ),
              ),
              if (syncState.uploadSpeedBps > 0)
                Text(
                  l10n.recording_uploadSpeed(
                    formatFileSize(syncState.uploadSpeedBps.round()),
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.foreground.withValues(alpha: 0.7),
                  ),
                ),
              if (eta != null)
                Text(
                  l10n.recording_uploadEtaRemaining(_formatEta(eta)),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.foreground.withValues(alpha: 0.7),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatEta(Duration d) {
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    if (d.inMinutes > 0) return '${d.inMinutes}m';
    return '${d.inSeconds}s';
  }
}
