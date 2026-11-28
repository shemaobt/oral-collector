import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class FieldBorder extends OutlineInputBorder {
  const FieldBorder({super.borderSide = BorderSide.none, this.edge = const []})
    : super(borderRadius: const BorderRadius.all(Radius.circular(radius)));

  static const double radius = 14;
  static const double _edgeReach = 64;

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
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) =>
      a is FieldBorder ? _lerp(a, this, t) : super.lerpFrom(a, t);

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) =>
      b is FieldBorder ? _lerp(this, b, t) : super.lerpTo(b, t);

  static FieldBorder _lerp(FieldBorder a, FieldBorder b, double t) =>
      FieldBorder(
        borderSide: BorderSide.lerp(a.borderSide, b.borderSide, t),
        edge: BoxShadow.lerpList(a.edge, b.edge, t) ?? const [],
      );

  @override
  bool operator ==(Object other) =>
      other is FieldBorder &&
      other.borderSide == borderSide &&
      listEquals(other.edge, edge);

  @override
  int get hashCode => Object.hash(borderSide, Object.hashAll(edge));

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
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(rect.inflate(_edgeReach))
        ..addRRect(box),
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
