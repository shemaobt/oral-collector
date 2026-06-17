import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/utils/format.dart';
import '../../../sync/presentation/notifiers/sync_notifier.dart';
import '../../data/local_recording_classification.dart';
import '../notifiers/recording_session_notifier.dart';

class RecordingCard extends ConsumerWidget {
  const RecordingCard({
    super.key,
    required this.recording,
    required this.genreName,
    required this.formattedDuration,
    required this.onTap,
    this.subcategoryName,
    this.registerName,
    this.onDelete,
  });

  final LocalRecording recording;
  final String? genreName;
  final String? subcategoryName;
  final String? registerName;
  final String formattedDuration;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  Color _statusAccentColor(AppColorSet colors) {
    switch (recording.uploadStatus) {
      case 'uploaded':
      case 'verified':
        return colors.success;
      case 'uploading':
        return colors.accent;
      case 'failed':
        return colors.error;
      default:
        return colors.border;
    }
  }

  IconData _statusIcon() {
    switch (recording.uploadStatus) {
      case 'uploaded':
      case 'verified':
        return LucideIcons.checkCircle2;
      case 'uploading':
        return LucideIcons.upload;
      case 'failed':
        return LucideIcons.cloudOff;
      default:
        return LucideIcons.smartphone;
    }
  }

  String _statusLabel(AppLocalizations l10n) {
    switch (recording.uploadStatus) {
      case 'uploaded':
      case 'verified':
        return l10n.recording_statusUploaded;
      case 'uploading':
        return l10n.recording_statusUploading;
      case 'failed':
        return l10n.recording_statusFailed;
      default:
        return l10n.recording_statusLocal;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final statusColor = _statusAccentColor(colors);
    final isUploadingThis = ref.watch(
      syncNotifierProvider.select((s) => s.uploadingId == recording.id),
    );
    final uploadProgress = ref.watch(
      syncNotifierProvider.select(
        (s) => s.uploadingId == recording.id ? s.syncProgress : 0,
      ),
    );
    final isRecordingActive = ref.watch(
      recordingSessionNotifierProvider.select((s) => s.isRecording),
    );
    final isPausedByRecording =
        isRecordingActive &&
        recording.uploadStatus == 'local' &&
        (recording.uploadedBytes > 0 || recording.resumableSessionUri != null);
    final isUnclassified = recording.isUnclassified;
    final breadcrumbParts = <String>[];
    if (genreName != null) breadcrumbParts.add(genreName!);
    if (subcategoryName != null) breadcrumbParts.add(subcategoryName!);
    final breadcrumb = isUnclassified
        ? l10n.recording_unclassified
        : breadcrumbParts.isNotEmpty
        ? breadcrumbParts.join(' > ')
        : l10n.recording_unknownGenre;
    final title = (recording.title != null && recording.title!.isNotEmpty)
        ? recording.title!
        : l10n.common_untitled;

    final locale = Localizations.localeOf(context).languageCode;
    final recordedDate = formatRecordingDate(
      recording.recordedAt,
      locale,
      l10n: l10n,
    );

    return Material(
      color: colors.card,
      borderRadius: BorderRadius.circular(RadiusScale.r16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(RadiusScale.r16),
                    bottomLeft: Radius.circular(RadiusScale.r16),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SpacingScale.s16,
                    vertical: SpacingScale.s12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: SpacingScale.s8),
                          Text(
                            recordedDate,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colors.secondary.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              breadcrumb,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isUnclassified
                                    ? colors.warning
                                    : colors.secondary,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (recording.hasSecondary) ...[
                            const SizedBox(width: SpacingScale.s8),
                            Tooltip(
                              message: l10n.recording_alsoClassifiedAsTooltip,
                              child: Icon(
                                LucideIcons.layers,
                                size: 12,
                                color: colors.secondary.withValues(alpha: 0.7),
                                semanticLabel:
                                    l10n.recording_alsoClassifiedAsTooltip,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: SpacingScale.s8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: SpacingScale.s8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(
                                RadiusScale.r8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.clock,
                                  size: 11,
                                  color: colors.primary,
                                ),
                                const SizedBox(width: SpacingScale.s4),
                                Text(
                                  formattedDuration,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colors.primary,
                                    fontWeight: FontWeight.w600,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: SpacingScale.s8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: SpacingScale.s8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                RadiusScale.r8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _statusIcon(),
                                  size: 11,
                                  color: statusColor,
                                ),
                                const SizedBox(width: SpacingScale.s4),
                                Text(
                                  _statusLabel(l10n),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: statusColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isUnclassified) ...[
                            const SizedBox(width: SpacingScale.s8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: SpacingScale.s8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: colors.warning.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(
                                  RadiusScale.r8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.tag,
                                    size: 11,
                                    color: colors.warning,
                                  ),
                                  const SizedBox(width: SpacingScale.s4),
                                  Text(
                                    l10n.recording_unclassified,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colors.warning,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const Spacer(),
                          Icon(
                            LucideIcons.chevronRight,
                            size: 16,
                            color: colors.border,
                          ),
                        ],
                      ),
                      if (isUploadingThis) ...[
                        const SizedBox(height: SpacingScale.s8),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: (uploadProgress / 100).clamp(0.0, 1.0),
                                  minHeight: 3,
                                  backgroundColor: colors.border.withValues(
                                    alpha: 0.3,
                                  ),
                                  valueColor: AlwaysStoppedAnimation(
                                    colors.accent,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: SpacingScale.s8),
                            Text(
                              '$uploadProgress%',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colors.accent,
                                fontWeight: FontWeight.w600,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (isPausedByRecording) ...[
                        const SizedBox(height: SpacingScale.s8),
                        Row(
                          children: [
                            Icon(
                              LucideIcons.pauseCircle,
                              size: 12,
                              color: colors.secondary.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: SpacingScale.s4),
                            Flexible(
                              child: Text(
                                l10n.upload_pausedWhileRecording,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colors.secondary.withValues(
                                    alpha: 0.85,
                                  ),
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
