import 'dart:async';

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
  final List<double> _amplitudes = [];
  StreamSubscription<double>? _subscription;

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
              barColor: widget.barColor ?? Colors.black,
              cursorColor: widget.cursorColor ?? const Color(0xFFD45200),
            ),
          );
        },
      ),
    );
  }
}

class _ScrollingWaveformPainter extends CustomPainter {
  _ScrollingWaveformPainter({
    required this.amplitudes,
    required this.barColor,
    required this.cursorColor,
  });

  final List<double> amplitudes;
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
    final visible = amplitudes.sublist(startIdx);
    final fadeZone = size.width * 0.12;

    for (var i = 0; i < visible.length; i++) {
      final amp = visible[i];
      final x = centerX - (visible.length - i) * slotWidth;
      if (x < -barWidth) continue;

      final recency = visible.length > 1 ? i / (visible.length - 1) : 1.0;
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
    return old.amplitudes.length != amplitudes.length ||
        old.barColor != barColor ||
        old.cursorColor != cursorColor;
  }
}
