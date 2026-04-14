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
    this.playheadFraction,
    this.onPlayheadSeek,
    this.onSeekAndPlay,
    this.zoom = 1.0,
    this.panFraction = 0.0,
    this.onZoomPanChanged,
    this.onResetZoom,
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
  final double? playheadFraction;
  final ValueChanged<double>? onPlayheadSeek;
  final ValueChanged<double>? onSeekAndPlay;
  final double zoom;
  final double panFraction;
  final ValueChanged<({double zoom, double panFraction})>? onZoomPanChanged;
  final VoidCallback? onResetZoom;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isZoomed = zoom > 1.01;

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
                      ? 'Tap to jump. Long-press to add. Long-press marker to remove.'
                      : 'Tap to jump and listen. Long-press to add a split.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.foreground.withValues(alpha: 0.5),
                  ),
                ),
              ),
              if (isZoomed && onResetZoom != null)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onResetZoom!();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    margin: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      color: colors.accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.zoomOut,
                          size: 12,
                          color: colors.accent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${zoom.toStringAsFixed(1)}x',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
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
          const SizedBox(height: 8),
          if (isZoomed)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _Minimap(
                bars: waveformBars,
                panFraction: panFraction,
                zoom: zoom,
                colors: colors,
                isDark: isDark,
              ),
            ),
          TrimWaveform(
            bars: waveformBars,
            splitPoints: splitPoints,
            onSplitPointsChanged: onSplitPointsChanged,
            playingSegment: playingSegment,
            excludedSegments: excludedSegments,
            playheadFraction: playheadFraction,
            onPlayheadSeek: onPlayheadSeek,
            onSeekAndPlay: onSeekAndPlay,
            zoom: zoom,
            panFraction: panFraction,
            onZoomPanChanged: onZoomPanChanged,
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

class _Minimap extends StatelessWidget {
  const _Minimap({
    required this.bars,
    required this.panFraction,
    required this.zoom,
    required this.colors,
    required this.isDark,
  });

  final List<double> bars;
  final double panFraction;
  final double zoom;
  final AppColorSet colors;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: CustomPaint(
        painter: _MinimapPainter(
          bars: bars,
          panFraction: panFraction,
          zoom: zoom,
          barColor: colors.foreground.withValues(alpha: isDark ? 0.2 : 0.15),
          viewportColor: colors.accent.withValues(alpha: 0.18),
          viewportBorder: colors.accent.withValues(alpha: 0.6),
          bgColor: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.03),
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _MinimapPainter extends CustomPainter {
  _MinimapPainter({
    required this.bars,
    required this.panFraction,
    required this.zoom,
    required this.barColor,
    required this.viewportColor,
    required this.viewportBorder,
    required this.bgColor,
  });

  final List<double> bars;
  final double panFraction;
  final double zoom;
  final Color barColor;
  final Color viewportColor;
  final Color viewportBorder;
  final Color bgColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(6),
    );
    canvas.save();
    canvas.clipRRect(rect);
    canvas.drawRect(Offset.zero & size, Paint()..color = bgColor);

    if (bars.isNotEmpty) {
      final centerY = size.height / 2;
      final barStep = size.width / bars.length;
      final barWidth = (barStep * 0.6).clamp(1.0, 3.0);
      final maxHeight = size.height - 4;
      for (var i = 0; i < bars.length; i++) {
        final amp = bars[i].clamp(0.0, 1.0);
        final h = (amp * maxHeight).clamp(1.0, maxHeight);
        final x = i * barStep + (barStep - barWidth) / 2;
        canvas.drawRect(
          Rect.fromLTWH(x, centerY - h / 2, barWidth, h),
          Paint()..color = barColor,
        );
      }
    }

    final viewLeft = panFraction.clamp(0.0, 1.0) * size.width;
    final viewWidth = (size.width / zoom).clamp(4.0, size.width);
    final viewRect = Rect.fromLTWH(viewLeft, 0, viewWidth, size.height);
    canvas.drawRect(viewRect, Paint()..color = viewportColor);
    canvas.drawRect(
      viewRect,
      Paint()
        ..color = viewportBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MinimapPainter oldDelegate) {
    return oldDelegate.bars != bars ||
        oldDelegate.panFraction != panFraction ||
        oldDelegate.zoom != zoom ||
        oldDelegate.barColor != barColor ||
        oldDelegate.viewportColor != viewportColor;
  }
}
