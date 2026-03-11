import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/format.dart';

class FileInfoBanner extends StatelessWidget {
  const FileInfoBanner({
    super.key,
    required this.fileName,
    required this.format,
    required this.durationSeconds,
    required this.fileSizeBytes,
  });

  final String? fileName;
  final String format;
  final double durationSeconds;
  final int fileSizeBytes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.info.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.fileAudio, size: 20, color: colors.info),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName ?? 'Unknown file',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${format.toUpperCase()} \u2022 ${formatDurationHMS(durationSeconds)} \u2022 ${formatFileSize(fileSizeBytes)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.foreground.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
