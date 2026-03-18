import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_colors.dart';

class RecordingStatusSection extends StatelessWidget {
  const RecordingStatusSection({
    super.key,
    required this.recording,
    required this.colors,
    required this.theme,
    required this.onToggleCleaning,
    this.onRetryUpload,
  });

  final LocalRecording recording;
  final AppColorSet colors;
  final ThemeData theme;
  final VoidCallback onToggleCleaning;
  final VoidCallback? onRetryUpload;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.detail_status,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          StatusRow(
            icon: _uploadIcon(),
            iconColor: _uploadColor(),
            label: l10n.detail_upload,
            value: _uploadLabel(l10n),
            valueColor: _uploadColor(),
            trailing: onRetryUpload != null
                ? TextButton(
                    onPressed: onRetryUpload,
                    style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      l10n.detail_retry,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                : null,
            colors: colors,
            theme: theme,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(
              height: 1,
              color: colors.border.withValues(alpha: 0.15),
            ),
          ),
          StatusRow(
            icon: _cleaningIcon(),
            iconColor: _cleaningColor(),
            label: l10n.detail_cleaning,
            value: _cleaningLabel(l10n),
            valueColor: _cleaningColor(),
            colors: colors,
            theme: theme,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(
              height: 1,
              color: colors.border.withValues(alpha: 0.15),
            ),
          ),
          StatusRow(
            icon: LucideIcons.calendar,
            iconColor: colors.secondary,
            label: l10n.detail_recorded,
            value: _formatShortDate(recording.recordedAt, locale),
            valueColor: colors.foreground,
            colors: colors,
            theme: theme,
          ),
        ],
      ),
    );
  }

  String _formatShortDate(DateTime date, String locale) {
    return intl.DateFormat.yMMMd(locale).format(date);
  }

  IconData _uploadIcon() {
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

  Color _uploadColor() {
    switch (recording.uploadStatus) {
      case 'uploaded':
      case 'verified':
        return colors.success;
      case 'uploading':
        return colors.accent;
      case 'failed':
        return colors.error;
      default:
        return colors.secondary;
    }
  }

  String _uploadLabel(AppLocalizations l10n) {
    switch (recording.uploadStatus) {
      case 'uploaded':
      case 'verified':
        return l10n.detail_uploaded;
      case 'uploading':
        if (recording.retryCount >= 5) return l10n.detail_uploadStuck;
        return l10n.detail_uploading;
      case 'failed':
        if (recording.retryCount >= 5) return l10n.detail_maxRetries;
        return l10n.detail_uploadFailed;
      default:
        if (recording.retryCount > 0) return l10n.detail_pendingRetried;
        return l10n.detail_notSynced;
    }
  }

  IconData _cleaningIcon() {
    switch (recording.cleaningStatus) {
      case 'cleaned':
        return LucideIcons.sparkles;
      case 'cleaning':
        return LucideIcons.loader;
      case 'needs_cleaning':
        return LucideIcons.alertCircle;
      case 'failed':
        return LucideIcons.alertTriangle;
      default:
        return LucideIcons.minus;
    }
  }

  Color _cleaningColor() {
    switch (recording.cleaningStatus) {
      case 'cleaned':
        return colors.success;
      case 'cleaning':
        return colors.info;
      case 'needs_cleaning':
        return Colors.amber.shade700;
      case 'failed':
        return colors.error;
      default:
        return colors.secondary;
    }
  }

  String _cleaningLabel(AppLocalizations l10n) {
    switch (recording.cleaningStatus) {
      case 'cleaned':
        return l10n.cleaning_cleaned;
      case 'cleaning':
        return l10n.cleaning_cleaning;
      case 'needs_cleaning':
        return l10n.cleaning_needsCleaning;
      case 'failed':
        return l10n.cleaning_cleanFailed;
      default:
        return l10n.detail_notFlagged;
    }
  }
}

class StatusRow extends StatelessWidget {
  const StatusRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.valueColor,
    required this.colors,
    required this.theme,
    this.trailing,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color valueColor;
  final AppColorSet colors;
  final ThemeData theme;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(child: Icon(icon, size: 16, color: iconColor)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.secondary,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: valueColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}
