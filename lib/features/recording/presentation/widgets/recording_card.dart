import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/format.dart';
import '../../domain/entities/classification.dart';

class RecordingCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final statusColor = _statusAccentColor(colors);
    final isUnclassified = recording.isUnclassified;
    final breadcrumbParts = <String>[];
    if (genreName != null) breadcrumbParts.add(genreName!);
    if (subcategoryName != null) breadcrumbParts.add(subcategoryName!);
    final breadcrumb = isUnclassified
        ? l10n.recording_unclassified
        : breadcrumbParts.isNotEmpty
        ? breadcrumbParts.join(' > ')
        : 'Unknown genre';

    final locale = Localizations.localeOf(context).languageCode;
    final recordedDate = formatRecordingDate(recording.recordedAt, locale);

    return Material(
      color: colors.card,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 4,
              height: 88,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            breadcrumb,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isUnclassified
                                  ? Colors.amber.shade700
                                  : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          recordedDate,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.secondary.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.clock,
                                size: 11,
                                color: colors.primary,
                              ),
                              const SizedBox(width: 4),
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
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_statusIcon(), size: 11, color: statusColor),
                              const SizedBox(width: 4),
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
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade700.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.tag,
                                  size: 11,
                                  color: Colors.amber.shade700,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  l10n.recording_unclassified,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.amber.shade700,
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
