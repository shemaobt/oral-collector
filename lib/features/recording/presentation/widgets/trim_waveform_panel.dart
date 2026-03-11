import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import 'trim_waveform.dart';

class TrimWaveformPanel extends StatelessWidget {
  const TrimWaveformPanel({
    super.key,
    required this.waveformBars,
    required this.splitPoints,
    required this.onSplitPointsChanged,
    required this.playingSegment,
    required this.excludedSegments,
    required this.hasSplits,
    required this.keptCount,
    required this.segmentCount,
    required this.totalDurationLabel,
    required this.totalDurationShortLabel,
    required this.onClearAll,
  });

  final List<double> waveformBars;
  final List<double> splitPoints;
  final ValueChanged<List<double>> onSplitPointsChanged;
  final int? playingSegment;
  final Set<int> excludedSegments;
  final bool hasSplits;
  final int keptCount;
  final int segmentCount;
  final String totalDurationLabel;
  final String totalDurationShortLabel;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? colors.surfaceAlt.withValues(alpha: 0.5)
            : colors.surfaceAlt.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.scissors, size: 14, color: colors.accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  hasSplits
                      ? 'Tap to add splits. Long-press marker to remove.'
                      : 'Tap on the waveform to add a split point',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.foreground.withValues(alpha: 0.5),
                  ),
                ),
              ),
              if (hasSplits)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onClearAll();
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      'Clear all',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.accent,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          TrimWaveform(
            bars: waveformBars,
            splitPoints: splitPoints,
            onSplitPointsChanged: onSplitPointsChanged,
            playingSegment: playingSegment,
            excludedSegments: excludedSegments,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '00:00.00',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.foreground.withValues(alpha: 0.4),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  hasSplits
                      ? '$keptCount of $segmentCount kept'
                      : totalDurationShortLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                totalDurationLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.foreground.withValues(alpha: 0.4),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
