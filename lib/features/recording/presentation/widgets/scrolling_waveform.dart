import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

class ScrollingWaveform extends StatefulWidget {
  const ScrollingWaveform({
    super.key,
    this.amplitudeStream,
    this.height = 200,
    this.barColor,
    this.cursorColor,
    this.isPaused = false,
  });

  final Stream<double>? amplitudeStream;
  final double height;
  final Color? barColor;
  final Color? cursorColor;
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
              barColor: widget.barColor ?? Colors.black,
              cursorColor: widget.cursorColor ?? const Color(0xFFD45200),
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
    required this.cursorColor,
  });

  final _AmplitudeRingBuffer amplitudes;
  final int revision;
  final Color barColor;
  final Color cursorColor;

  static const double barWidth = 2.5;
  static const double barGap = 1.5;
  static const double slotWidth = barWidth + barGap;

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width * 0.55;
    final centerY = size.height / 2;

    final guidePaint = Paint()
      ..color = barColor.withValues(alpha: 0.04)
      ..strokeWidth = 0.5;
    canvas.drawLine(
      Offset(0, size.height * 0.25),
      Offset(size.width, size.height * 0.25),
      guidePaint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.75),
      Offset(size.width, size.height * 0.75),
      guidePaint,
    );

    final baselinePaint = Paint()
      ..color = barColor.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, centerY),
      Offset(size.width, centerY),
      baselinePaint,
    );

    final maxBars = (centerX / slotWidth).floor();
    final startIdx = amplitudes.length > maxBars
        ? amplitudes.length - maxBars
        : 0;
    final visibleCount = amplitudes.length - startIdx;
    final fadeZone = size.width * 0.12;

    for (var i = 0; i < visibleCount; i++) {
      final amp = amplitudes[startIdx + i];
      final x = centerX - (visibleCount - i) * slotWidth;
      if (x < -barWidth) continue;

      final recency = visibleCount > 1 ? i / (visibleCount - 1) : 1.0;
      double fade = 1.0;
      if (x < fadeZone) fade = (x / fadeZone).clamp(0.0, 1.0);
      final alpha = ((0.35 + 0.65 * recency) * fade).clamp(0.0, 1.0);

      final barHeight = (amp * size.height * 0.85).clamp(
        2.0,
        size.height * 0.85,
      );
      final paint = Paint()
        ..color = barColor.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;

      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x + barWidth / 2, centerY),
          width: barWidth,
          height: barHeight,
        ),
        Radius.circular(barWidth / 2),
      );
      canvas.drawRRect(rect, paint);
    }

    final cursorGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        cursorColor.withValues(alpha: 0),
        cursorColor,
        cursorColor,
        cursorColor.withValues(alpha: 0),
      ],
      stops: const [0, 0.12, 0.88, 1.0],
    );
    final cursorRect = Rect.fromLTWH(centerX - 1, 0, 2, size.height);
    canvas.drawRect(
      cursorRect,
      Paint()..shader = cursorGradient.createShader(cursorRect),
    );

    final indicatorPath = Path()
      ..moveTo(centerX - 5, 0)
      ..lineTo(centerX + 5, 0)
      ..lineTo(centerX, 7)
      ..close();
    canvas.drawPath(indicatorPath, Paint()..color = cursorColor);

    canvas.drawCircle(
      Offset(centerX, 4),
      6,
      Paint()..color = cursorColor.withValues(alpha: 0.12),
    );
  }

  @override
  bool shouldRepaint(covariant _ScrollingWaveformPainter old) {
    return old.revision != revision ||
        old.barColor != barColor ||
        old.cursorColor != cursorColor;
  }
}
