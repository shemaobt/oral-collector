import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/tokens.dart';

/// Static "captured" waveform with a sweep highlight crossing left → right.
///
/// During audio finalization the live amplitude stream has been closed; this
/// widget renders a decorative frozen waveform with an indeterminate sweep so
/// the user perceives continuity from the recording screen.
class FinalizingWaveform extends StatefulWidget {
  const FinalizingWaveform({
    super.key,
    this.barCount = 48,
    this.barWidth = 3,
    this.gap = 2.5,
    this.height = 78,
    this.sweepDuration = const Duration(milliseconds: 2500),
  });

  final int barCount;
  final double barWidth;
  final double gap;
  final double height;
  final Duration sweepDuration;

  @override
  State<FinalizingWaveform> createState() => _FinalizingWaveformState();
}

class _FinalizingWaveformState extends State<FinalizingWaveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<double> _bars;

  @override
  void initState() {
    super.initState();
    _bars = List<double>.generate(widget.barCount, (i) {
      final base = 8.0;
      final sin = (math.sin(i * 0.55) * 26).abs();
      final cos = (math.cos(i * 1.1) * 12).abs();
      return base + sin + cos;
    });
    _controller = AnimationController(
      vsync: this,
      duration: widget.sweepDuration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final sweep = _controller.value * widget.barCount;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (var i = 0; i < widget.barCount; i++)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: widget.gap / 2),
                  child: _Bar(
                    width: widget.barWidth,
                    height: _bars[i],
                    color: _colorFor(i, sweep, colors),
                    opacity: _opacityFor(i, sweep),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Color _colorFor(int index, double sweep, AppColorSet colors) {
    final dist = (index - sweep).abs();
    if (dist < 2.5) return colors.accent;
    if (index < sweep) return colors.foreground.withValues(alpha: 0.85);
    return colors.border;
  }

  double _opacityFor(int index, double sweep) {
    final dist = (index - sweep).abs();
    if (dist < 2.5) return 1.0;
    if (index < sweep) return 0.85;
    return 0.55;
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.width,
    required this.height,
    required this.color,
    required this.opacity,
  });

  final double width;
  final double height;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: DurationScale.ms120,
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
