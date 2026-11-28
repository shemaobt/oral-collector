import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class ScrollingWaveform extends StatefulWidget {
  const ScrollingWaveform({
    super.key,
    this.amplitudeStream,
    this.height = 200,
    this.isPaused = false,
  });

  final Stream<double>? amplitudeStream;
  final double height;
  final bool isPaused;

  @override
  State<ScrollingWaveform> createState() => _ScrollingWaveformState();
}

class _ScrollingWaveformState extends State<ScrollingWaveform> {
  static const int _bufferCapacity = 6000;

  final _AmplitudeRingBuffer _amplitudes = _AmplitudeRingBuffer(
    _bufferCapacity,
  );
  StreamSubscription<double>? _subscription;
  int _revision = 0;

  @override
  void initState() {
    super.initState();
    _listenToStream();
  }

  @override
  void didUpdateWidget(covariant ScrollingWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.amplitudeStream != oldWidget.amplitudeStream) {
      _subscription?.cancel();
      if (widget.amplitudeStream != oldWidget.amplitudeStream &&
          oldWidget.amplitudeStream == null) {
        _amplitudes.clear();
      }
      _listenToStream();
    }
  }

  void _listenToStream() {
    if (widget.amplitudeStream == null) return;
    _subscription = widget.amplitudeStream!.listen((amp) {
      if (!mounted || widget.isPaused) return;
      setState(() {
        _amplitudes.add(amp.clamp(0.0, 1.0));
        _revision++;
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return CustomPaint(
            size: Size(constraints.maxWidth, widget.height),
            painter: _ScrollingWaveformPainter(
              amplitudes: _amplitudes,
              revision: _revision,
              barColor: AppColors.of(context).mic,
              isPaused: widget.isPaused,
            ),
          );
        },
      ),
    );
  }
}

class _AmplitudeRingBuffer {
  _AmplitudeRingBuffer(this.capacity) : _buf = Float64List(capacity);

  final int capacity;
  final Float64List _buf;
  int _head = 0;
  int _count = 0;

  void add(double v) {
    _buf[_head] = v;
    _head = (_head + 1) % capacity;
    if (_count < capacity) _count++;
  }

  void clear() {
    _head = 0;
    _count = 0;
  }

  int get length => _count;

  double operator [](int logicalIndex) {
    if (_count < capacity) return _buf[logicalIndex];
    return _buf[(_head + logicalIndex) % capacity];
  }
}

class _ScrollingWaveformPainter extends CustomPainter {
  _ScrollingWaveformPainter({
    required this.amplitudes,
    required this.revision,
    required this.barColor,
    required this.isPaused,
  });

  final _AmplitudeRingBuffer amplitudes;
  final int revision;
  final Color barColor;
  final bool isPaused;

  static const double barWidth = 4;
  static const double barGap = 3;
  static const double slotWidth = barWidth + barGap;

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;

    final maxBars = ((size.width + barGap) / slotWidth).floor();
    final startIdx = amplitudes.length > maxBars
        ? amplitudes.length - maxBars
        : 0;
    final visibleCount = amplitudes.length - startIdx;
    final paint = Paint()
      ..color = isPaused ? barColor.withValues(alpha: 0.35) : barColor;

    for (var i = 0; i < visibleCount; i++) {
      final amp = amplitudes[startIdx + i];
      final x = size.width - barWidth - (visibleCount - 1 - i) * slotWidth;

      final barHeight = (amp * size.height * 0.85).clamp(
        2.0,
        size.height * 0.85,
      );
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x + barWidth / 2, centerY),
          width: barWidth,
          height: barHeight,
        ),
        const Radius.circular(barWidth / 2),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScrollingWaveformPainter old) {
    return old.revision != revision ||
        old.barColor != barColor ||
        old.isPaused != isPaused;
  }
}
