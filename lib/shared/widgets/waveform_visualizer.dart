import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class WaveformVisualizer extends StatefulWidget {
  const WaveformVisualizer({
    super.key,
    this.amplitudeStream,
    this.amplitudes,
    this.barColor,
    this.barWidth = 4.0,
    this.barSpacing = 2.0,
    this.height = 80.0,
    this.barCount = 30,
    this.fillWidth = false,
  });

  final Stream<double>? amplitudeStream;
  final List<double>? amplitudes;
  final Color? barColor;
  final double barWidth;
  final double barSpacing;
  final double height;
  final int barCount;
  final bool fillWidth;

  @override
  State<WaveformVisualizer> createState() => _WaveformVisualizerState();
}

class _WaveformVisualizerState extends State<WaveformVisualizer>
    with SingleTickerProviderStateMixin {
  late List<double> _bars;
  StreamSubscription<double>? _subscription;
  late final AnimationController _animController;

  bool get _isLive => widget.amplitudeStream != null;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _bars = _isLive
        ? List.filled(widget.barCount, 0.0, growable: true)
        : List<double>.from(widget.amplitudes ?? []);
    _listenToStream();
  }

  @override
  void didUpdateWidget(covariant WaveformVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.amplitudeStream != oldWidget.amplitudeStream) {
      _subscription?.cancel();
      if (_isLive) {
        _bars = List.filled(widget.barCount, 0.0, growable: true);
      }
      _listenToStream();
    }

    if (!_isLive && widget.amplitudes != oldWidget.amplitudes) {
      setState(() {
        _bars = List<double>.from(widget.amplitudes ?? []);
      });
    }

    if (_isLive && widget.barCount != oldWidget.barCount) {
      _resizeBars(widget.barCount);
    }
  }

  void _listenToStream() {
    if (!_isLive) return;
    try {
      _subscription = widget.amplitudeStream!.listen((amplitude) {
        final clamped = amplitude.clamp(0.0, 1.0);
        setState(() {
          _bars = [..._bars.skip(1), clamped];
        });
        _animController.forward(from: 0.0);
      });
    } catch (_) {}
  }

  void _resizeBars(int newCount) {
    setState(() {
      if (newCount > _bars.length) {
        _bars =
            List.filled(newCount - _bars.length, 0.0, growable: true) + _bars;
      } else {
        _bars = _bars.sublist(_bars.length - newCount);
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.barColor ?? AppColors.primary;
    final bars = _isLive ? _bars : (widget.amplitudes ?? []);

    if (widget.fillWidth) {
      return SizedBox(
        height: widget.height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final totalWidth = constraints.maxWidth;
            final count = bars.length;
            final slotWidth = count > 0 ? totalWidth / count : 0.0;
            final barW = slotWidth * 0.7;
            final barS = slotWidth * 0.3;

            return AnimatedBuilder(
              animation: _animController,
              builder: (context, _) {
                return CustomPaint(
                  size: Size(totalWidth, widget.height),
                  painter: _WaveformPainter(
                    bars: bars,
                    color: color,
                    barWidth: barW,
                    barSpacing: barS,
                  ),
                );
              },
            );
          },
        ),
      );
    }

    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, _) {
          return CustomPaint(
            size: Size(
              bars.length * (widget.barWidth + widget.barSpacing),
              widget.height,
            ),
            painter: _WaveformPainter(
              bars: bars,
              color: color,
              barWidth: widget.barWidth,
              barSpacing: widget.barSpacing,
            ),
          );
        },
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  _WaveformPainter({
    required this.bars,
    required this.color,
    required this.barWidth,
    required this.barSpacing,
  });

  final List<double> bars;
  final Color color;
  final double barWidth;
  final double barSpacing;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final minBarHeight = 2.0;
    final centerY = size.height / 2;

    for (var i = 0; i < bars.length; i++) {
      final amplitude = bars[i].clamp(0.0, 1.0);
      final barHeight = minBarHeight + amplitude * (size.height - minBarHeight);
      final x = i * (barWidth + barSpacing);
      final top = centerY - barHeight / 2;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, top, barWidth, barHeight),
        Radius.circular(barWidth / 2),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.bars != bars ||
        oldDelegate.color != color ||
        oldDelegate.barWidth != barWidth ||
        oldDelegate.barSpacing != barSpacing;
  }
}
