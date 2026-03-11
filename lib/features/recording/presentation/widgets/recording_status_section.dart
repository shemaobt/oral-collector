import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
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
            'Status',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          StatusRow(
            icon: _uploadIcon(),
            iconColor: _uploadColor(),
            label: 'Upload',
            value: _uploadLabel(),
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
                      'Retry',
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
            label: 'Cleaning',
            value: _cleaningLabel(),
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
            label: 'Recorded',
            value: _formatShortDate(recording.recordedAt),
            valueColor: colors.foreground,
            colors: colors,
            theme: theme,
          ),
        ],
      ),
    );
  }

  String _formatShortDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  IconData _uploadIcon() {
    switch (recording.uploadStatus) {
      case 'uploaded':
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
        return colors.success;
      case 'uploading':
        return colors.accent;
      case 'failed':
        return colors.error;
      default:
        return colors.secondary;
    }
  }

  String _uploadLabel() {
    switch (recording.uploadStatus) {
      case 'uploaded':
        return 'Uploaded';
      case 'uploading':
        if (recording.retryCount >= 5) return 'Stuck \u2014 tap Retry';
        return 'Uploading...';
      case 'failed':
        if (recording.retryCount >= 5) return 'Max retries \u2014 tap Retry';
        return 'Upload Failed';
      default:
        if (recording.retryCount > 0) return 'Pending (retried)';
        return 'Not synced';
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

  String _cleaningLabel() {
    switch (recording.cleaningStatus) {
      case 'cleaned':
        return 'Cleaned';
      case 'cleaning':
        return 'Cleaning...';
      case 'needs_cleaning':
        return 'Needs Cleaning';
      case 'failed':
        return 'Cleaning Failed';
      default:
        return 'Not flagged';
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
