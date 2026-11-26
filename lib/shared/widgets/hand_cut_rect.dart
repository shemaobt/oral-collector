import 'dart:math';

import 'package:flutter/widgets.dart';

Path handCutRectOutline(Size size, double radius) {
  final w = size.width;
  final h = size.height;
  final r = min(radius, min(w / 2, h / 2));
  final seed = (w + h).toInt() % 9 + 1;
  final amp = min(1.1, max(0.35, min(w, h) * 0.012));
  final points = <Offset>[];

  void side(double x0, double y0, double x1, double y1) {
    final length = sqrt((x1 - x0) * (x1 - x0) + (y1 - y0) * (y1 - y0));
    final count = max(1, (length / 34).round());
    for (var i = 0; i < count; i++) {
      final t = i / count;
      points.add(Offset(x0 + (x1 - x0) * t, y0 + (y1 - y0) * t));
    }
  }

  void corner(double cx, double cy, double from) {
    for (var k = 0; k < 4; k++) {
      final angle = (from + k * 22.5) * pi / 180;
      points.add(Offset(cx + r * cos(angle), cy + r * sin(angle)));
    }
  }

  side(r, 0, w - r, 0);
  corner(w - r, r, -90);
  side(w, r, w, h - r);
  corner(w - r, h - r, 0);
  side(w - r, h, r, h);
  corner(r, h - r, 90);
  side(0, h - r, 0, r);
  corner(r, r, 180);

  return _closedCurve([
    for (var i = 0; i < points.length; i++)
      Offset(
        points[i].dx + amp * sin(i * 1.7 + seed),
        points[i].dy + amp * cos(i * 2.3 + seed * 1.3),
      ),
  ]);
}

Path _closedCurve(List<Offset> points) {
  final count = points.length;
  Offset middle(Offset a, Offset b) =>
      Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
  final first = middle(points[count - 1], points[0]);
  final path = Path()..moveTo(first.dx, first.dy);
  for (var i = 0; i < count; i++) {
    final point = points[i];
    final next = middle(point, points[(i + 1) % count]);
    path.quadraticBezierTo(point.dx, point.dy, next.dx, next.dy);
  }
  return path..close();
}

class HandCutRectPainter extends CustomPainter {
  const HandCutRectPainter({
    required this.fill,
    required this.radius,
    this.shadow,
    this.shadowOffset = const Offset(3, 4),
  });

  final Color fill;
  final double radius;
  final Color? shadow;
  final Offset shadowOffset;

  @override
  void paint(Canvas canvas, Size size) {
    final outline = handCutRectOutline(size, radius);
    final shadowColor = shadow;
    if (shadowColor != null) {
      canvas.drawPath(
        outline.shift(shadowOffset),
        Paint()..color = shadowColor,
      );
    }
    canvas.drawPath(outline, Paint()..color = fill);
  }

  @override
  bool shouldRepaint(HandCutRectPainter old) =>
      old.fill != fill ||
      old.radius != radius ||
      old.shadow != shadow ||
      old.shadowOffset != shadowOffset;
}
