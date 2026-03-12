import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_colors.dart';

class RecordingInfoGrid extends StatelessWidget {
  const RecordingInfoGrid({
    super.key,
    required this.recording,
    required this.colors,
    required this.theme,
    required this.formattedDuration,
    required this.formattedDate,
    required this.formattedSize,
  });

  final LocalRecording recording;
  final AppColorSet colors;
  final ThemeData theme;
  final String formattedDuration;
  final String formattedDate;
  final String formattedSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InfoTile(
            icon: LucideIcons.clock,
            label: 'Duration',
            value: formattedDuration,
            colors: colors,
            theme: theme,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: InfoTile(
            icon: LucideIcons.hardDrive,
            label: 'Size',
            value: formattedSize,
            colors: colors,
            theme: theme,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: InfoTile(
            icon: LucideIcons.fileAudio,
            label: 'Format',
            value: recording.format.toUpperCase(),
            colors: colors,
            theme: theme,
          ),
        ),
      ],
    );
  }
}

class InfoTile extends StatelessWidget {
  const InfoTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.colors,
    required this.theme,
  });

  final IconData icon;
  final String label;
  final String value;
  final AppColorSet colors;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceAlt.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: colors.secondary),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
