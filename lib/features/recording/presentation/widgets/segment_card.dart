import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';

class SegmentCard extends StatelessWidget {
  const SegmentCard({
    super.key,
    required this.index,
    required this.total,
    required this.start,
    required this.end,
    required this.duration,
    required this.isPlaying,
    required this.isExcluded,
    required this.onPlayPause,
    required this.onToggleExclude,
    required this.colors,
    required this.isDark,
  });

  final int index;
  final int total;
  final String start;
  final String end;
  final String duration;
  final bool isPlaying;
  final bool isExcluded;
  final VoidCallback onPlayPause;
  final VoidCallback onToggleExclude;
  final AppColorSet colors;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final fgAlpha = isExcluded ? 0.35 : 1.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isExcluded
            ? colors.error.withValues(alpha: isDark ? 0.08 : 0.04)
            : isPlaying
            ? colors.accent.withValues(alpha: isDark ? 0.14 : 0.08)
            : isDark
            ? colors.surfaceAlt.withValues(alpha: 0.4)
            : colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExcluded
              ? colors.error.withValues(alpha: 0.2)
              : isPlaying
              ? colors.accent.withValues(alpha: 0.3)
              : colors.border.withValues(alpha: isDark ? 0.15 : 0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isExcluded
                  ? colors.error.withValues(alpha: isDark ? 0.15 : 0.08)
                  : colors.accent.withValues(alpha: isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              '${index + 1}',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: isExcluded ? colors.error : colors.accent,
                decoration: isExcluded ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isExcluded
                      ? 'Segment ${index + 1} — removed'
                      : 'Segment ${index + 1} of $total',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.foreground.withValues(alpha: fgAlpha),
                    decoration: isExcluded ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$start – $end',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.foreground.withValues(
                      alpha: isExcluded ? 0.25 : 0.5,
                    ),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isExcluded
                  ? colors.error.withValues(alpha: 0.08)
                  : colors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              duration,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: isExcluded ? colors.error : colors.accent,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: 6),

          GestureDetector(
            onTap: onPlayPause,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isPlaying
                    ? colors.accent
                    : colors.accent.withValues(alpha: isDark ? 0.18 : 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(
                isPlaying ? LucideIcons.square : LucideIcons.play,
                size: 14,
                color: isPlaying
                    ? (isDark ? Colors.black : Colors.white)
                    : colors.accent,
              ),
            ),
          ),
          const SizedBox(width: 6),

          GestureDetector(
            onTap: onToggleExclude,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isExcluded
                    ? colors.accent.withValues(alpha: isDark ? 0.18 : 0.1)
                    : colors.error.withValues(alpha: isDark ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(
                isExcluded ? LucideIcons.rotateCcw : LucideIcons.trash2,
                size: 14,
                color: isExcluded ? colors.accent : colors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
