import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';

class TrimWaveform extends StatefulWidget {
  const TrimWaveform({
    super.key,
    required this.bars,
    required this.splitPoints,
    required this.onSplitPointsChanged,
    this.playingSegment,
    this.excludedSegments = const {},
  });

  final List<double> bars;
  final List<double> splitPoints;
  final ValueChanged<List<double>> onSplitPointsChanged;
  final int? playingSegment;
  final Set<int> excludedSegments;

  @override
  State<TrimWaveform> createState() => _TrimWaveformState();
}

class _TrimWaveformState extends State<TrimWaveform> {
  static const double _waveformHeight = 160.0;
  static const double _handleRadius = 12.0;
  static const double _handleHitSlop = 24.0;
  static const double _minSplitGap = 0.03;

  int? _draggingIndex;

  List<double> get _sorted => [...widget.splitPoints]..sort();

  int? _hitTestMarker(double x, double totalWidth) {
    final sorted = _sorted;
    for (var i = 0; i < sorted.length; i++) {
      final markerX = sorted[i] * totalWidth;
      if ((x - markerX).abs() <= _handleRadius + _handleHitSlop) return i;
    }
    return null;
  }

  void _addSplitAt(double fraction) {
    if (fraction <= _minSplitGap || fraction >= 1.0 - _minSplitGap) return;
    for (final p in widget.splitPoints) {
      if ((fraction - p).abs() < _minSplitGap) return;
    }
    HapticFeedback.lightImpact();
    widget.onSplitPointsChanged([...widget.splitPoints, fraction]);
  }

  void _moveSplit(int sortedIndex, double newFraction) {
    final sorted = _sorted;
    final oldValue = sorted[sortedIndex];

    final minVal = sortedIndex == 0
        ? _minSplitGap
        : sorted[sortedIndex - 1] + _minSplitGap;
    final maxVal = sortedIndex == sorted.length - 1
        ? 1.0 - _minSplitGap
        : sorted[sortedIndex + 1] - _minSplitGap;
    final clamped = newFraction.clamp(minVal, maxVal);

    final updated = [...widget.splitPoints];
    final idx = updated.indexOf(oldValue);
    if (idx >= 0) updated[idx] = clamped;
    widget.onSplitPointsChanged(updated);
  }

  void _removeSplit(int sortedIndex) {
    final sorted = _sorted;
    if (sortedIndex < 0 || sortedIndex >= sorted.length) return;
    HapticFeedback.mediumImpact();
    final val = sorted[sortedIndex];
    final updated = [...widget.splitPoints];
    updated.remove(val);
    widget.onSplitPointsChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalHeight = _waveformHeight + _handleRadius * 2 + 4;

    return Semantics(
      label:
          'Split waveform. Tap to add split markers. Drag to reposition. Long-press to remove.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) {
              final x = details.localPosition.dx;
              if (_hitTestMarker(x, totalWidth) != null) return;
              _addSplitAt(x / totalWidth);
            },
            onHorizontalDragStart: (details) {
              final x = details.localPosition.dx;
              _draggingIndex = _hitTestMarker(x, totalWidth);
              if (_draggingIndex != null) HapticFeedback.selectionClick();
            },
            onHorizontalDragUpdate: (details) {
              if (_draggingIndex == null) return;
              final fraction =
                  details.localPosition.dx.clamp(0.0, totalWidth) / totalWidth;
              _moveSplit(_draggingIndex!, fraction);
            },
            onHorizontalDragEnd: (_) => _draggingIndex = null,
            onHorizontalDragCancel: () => _draggingIndex = null,
            onLongPressStart: (details) {
              final x = details.localPosition.dx;
              final hit = _hitTestMarker(x, totalWidth);
              if (hit != null) _removeSplit(hit);
            },
            child: SizedBox(
              height: totalHeight,
              width: totalWidth,
              child: CustomPaint(
                size: Size(totalWidth, totalHeight),
                painter: _SplitWaveformPainter(
                  bars: widget.bars,
                  splitPoints: _sorted,
                  playingSegment: widget.playingSegment,
                  excludedSegments: widget.excludedSegments,
                  accentColor: colors.accent,
                  barColor: isDark
                      ? colors.foreground.withValues(alpha: 0.18)
                      : colors.foreground.withValues(alpha: 0.12),
                  selectedBarColor: colors.accent,
                  errorColor: colors.error,
                  handleRadius: _handleRadius,
                  waveformHeight: _waveformHeight,
                  isDark: isDark,
                  foreground: colors.foreground,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SplitWaveformPainter extends CustomPainter {
  _SplitWaveformPainter({
    required this.bars,
    required this.splitPoints,
    required this.playingSegment,
    required this.excludedSegments,
    required this.accentColor,
    required this.barColor,
    required this.selectedBarColor,
    required this.errorColor,
    required this.handleRadius,
    required this.waveformHeight,
    required this.isDark,
    required this.foreground,
  });

  final List<double> bars;
  final List<double> splitPoints;
  final int? playingSegment;
  final Set<int> excludedSegments;
  final Color accentColor;
  final Color barColor;
  final Color selectedBarColor;
  final Color errorColor;
  final double handleRadius;
  final double waveformHeight;
  final bool isDark;
  final Color foreground;

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty) return;

    final handleDiameter = handleRadius * 2;
    final waveTop = handleDiameter + 4;
    final waveBottom = waveTop + waveformHeight;
    final boundaries = [0.0, ...splitPoints, 1.0];
    final segmentCount = boundaries.length - 1;

    final waveRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(0, waveTop, size.width, waveBottom),
      const Radius.circular(12),
    );
    canvas.save();
    canvas.clipRRect(waveRect);

    final bgPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTRB(0, waveTop, size.width, waveBottom), bgPaint);

    for (var i = 0; i < segmentCount; i++) {
      final left = boundaries[i] * size.width;
      final right = boundaries[i + 1] * size.width;

      final isExcluded = excludedSegments.contains(i);
      final isPlaying = playingSegment == i;
      final isEven = i.isEven;

      Color tint;
      if (isExcluded) {
        tint = errorColor.withValues(alpha: isDark ? 0.15 : 0.08);
      } else if (isPlaying) {
        tint = accentColor.withValues(alpha: isDark ? 0.22 : 0.14);
      } else if (isEven) {
        tint = accentColor.withValues(alpha: isDark ? 0.08 : 0.05);
      } else {
        tint = accentColor.withValues(alpha: isDark ? 0.14 : 0.09);
      }

      canvas.drawRect(
        Rect.fromLTRB(left, waveTop, right, waveBottom),
        Paint()..color = tint,
      );
    }

    _drawBars(canvas, size, waveTop, waveBottom, boundaries, segmentCount);

    canvas.restore();

    for (var i = 0; i < segmentCount; i++) {
      if (!excludedSegments.contains(i)) continue;
      final left = boundaries[i] * size.width;
      final right = boundaries[i + 1] * size.width;

      final crossPaint = Paint()
        ..color = errorColor.withValues(alpha: isDark ? 0.2 : 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      canvas.save();
      canvas.clipRect(Rect.fromLTRB(left, waveTop, right, waveBottom));
      const spacing = 10.0;
      final totalSpan = (right - left) + (waveBottom - waveTop);
      for (var d = 0.0; d < totalSpan; d += spacing) {
        canvas.drawLine(
          Offset(left + d, waveTop),
          Offset(left + d - (waveBottom - waveTop), waveBottom),
          crossPaint,
        );
      }
      canvas.restore();
    }

    for (var i = 0; i < splitPoints.length; i++) {
      final x = splitPoints[i] * size.width;
      _drawSplitMarker(canvas, x, waveTop, waveBottom);
    }

    if (splitPoints.isNotEmpty) {
      for (var i = 0; i < segmentCount; i++) {
        final left = boundaries[i] * size.width;
        final right = boundaries[i + 1] * size.width;
        final segWidth = right - left;
        if (segWidth < 28) continue;

        final isExcluded = excludedSegments.contains(i);

        final label = '${i + 1}';
        final tp = TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(
              color: isExcluded
                  ? errorColor.withValues(alpha: 0.5)
                  : accentColor.withValues(alpha: 0.6),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              decoration: isExcluded
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        tp.paint(
          canvas,
          Offset(left + (segWidth - tp.width) / 2, waveBottom - tp.height - 6),
        );
      }
    }
  }

  void _drawBars(
    Canvas canvas,
    Size size,
    double waveTop,
    double waveBottom,
    List<double> boundaries,
    int segmentCount,
  ) {
    final barCount = bars.length;
    final barWidth = size.width / barCount * 0.6;
    final stepWidth = size.width / barCount;
    final centerY = waveTop + waveformHeight / 2;
    const minBarHeight = 3.0;
    final maxBarHeight = waveformHeight - 12;

    for (var i = 0; i < barCount; i++) {
      final amplitude = bars[i].clamp(0.0, 1.0);
      final barHeight = minBarHeight + amplitude * maxBarHeight;
      final x = i * stepWidth + (stepWidth - barWidth) / 2;
      final top = centerY - barHeight / 2;

      final barCenter = (x + barWidth / 2) / size.width;

      int? segIndex;
      for (var s = 0; s < segmentCount; s++) {
        if (barCenter >= boundaries[s] && barCenter <= boundaries[s + 1]) {
          segIndex = s;
          break;
        }
      }

      final isExcluded =
          segIndex != null && excludedSegments.contains(segIndex);
      final isPlaying = segIndex != null && playingSegment == segIndex;

      Color barClr;
      if (isExcluded) {
        barClr = errorColor.withValues(alpha: isDark ? 0.25 : 0.2);
      } else if (isPlaying) {
        barClr = selectedBarColor;
      } else {
        barClr = barColor;
      }

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, top, barWidth, barHeight),
          Radius.circular(barWidth / 2),
        ),
        Paint()
          ..color = barClr
          ..style = PaintingStyle.fill,
      );
    }
  }

  void _drawSplitMarker(
    Canvas canvas,
    double x,
    double waveTop,
    double waveBottom,
  ) {
    final linePaint = Paint()
      ..color = (isDark ? Colors.white : foreground).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const dashHeight = 4.0;
    const gapHeight = 3.0;
    var y = waveTop;
    while (y < waveBottom) {
      final end = (y + dashHeight).clamp(y, waveBottom);
      canvas.drawLine(Offset(x, y), Offset(x, end), linePaint);
      y += dashHeight + gapHeight;
    }

    final handleCenter = Offset(x, handleRadius);
    canvas.drawCircle(handleCenter, handleRadius, Paint()..color = accentColor);

    final gripPaint = Paint()
      ..color = (isDark ? Colors.black : Colors.white).withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(x - 3, handleRadius - 4),
      Offset(x - 3, handleRadius + 4),
      gripPaint,
    );
    canvas.drawLine(
      Offset(x + 3, handleRadius - 4),
      Offset(x + 3, handleRadius + 4),
      gripPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SplitWaveformPainter oldDelegate) {
    return oldDelegate.bars != bars ||
        oldDelegate.splitPoints != splitPoints ||
        oldDelegate.playingSegment != playingSegment ||
        oldDelegate.excludedSegments != excludedSegments ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.isDark != isDark;
  }
}
