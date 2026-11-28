import 'package:flutter/material.dart';

class FieldBorder extends OutlineInputBorder {
  const FieldBorder({
    super.borderSide = BorderSide.none,
    this.edge = const [],
  }) : super(borderRadius: const BorderRadius.all(Radius.circular(radius)));

  static const double radius = 14;

  final List<BoxShadow> edge;

  @override
  FieldBorder copyWith({
    BorderSide? borderSide,
    BorderRadius? borderRadius,
    double? gapPadding,
  }) {
    return FieldBorder(borderSide: borderSide ?? this.borderSide, edge: edge);
  }

  @override
  FieldBorder scale(double t) =>
      FieldBorder(borderSide: borderSide.scale(t), edge: edge);

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double? gapStart,
    double gapExtent = 0.0,
    double gapPercentage = 0.0,
    TextDirection? textDirection,
  }) {
    final box = borderRadius.toRRect(rect);
    canvas.save();
    canvas.clipPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.largest),
        Path()..addRRect(box),
      ),
    );
    for (final shadow in edge) {
      canvas.drawRRect(
        box.shift(shadow.offset).inflate(shadow.spreadRadius),
        shadow.toPaint(),
      );
    }
    canvas.restore();
    super.paint(
      canvas,
      rect,
      gapStart: gapStart,
      gapExtent: gapExtent,
      gapPercentage: gapPercentage,
      textDirection: textDirection,
    );
  }
}
