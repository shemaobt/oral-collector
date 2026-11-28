import 'package:flutter/widgets.dart';

import 'brush_sign.dart';
import 'brush_signs.dart';

const double _viewBox = 116;
const double _disc = 84;
const double _origin = -16;

class SoundStrokes extends StatelessWidget {
  const SoundStrokes({
    super.key,
    required this.diameter,
    required this.color,
    required this.child,
  });

  final double diameter;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final box = diameter * _viewBox / _disc;
    return SizedBox.square(
      dimension: diameter,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          ExcludeSemantics(
            child: IgnorePointer(
              child: OverflowBox(
                minWidth: box,
                maxWidth: box,
                minHeight: box,
                maxHeight: box,
                child: CustomPaint(
                  size: Size.square(box),
                  painter: _StrokesPainter(color),
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

final Path _outline = parseOutline(soundStrokesOutline);

class _StrokesPainter extends CustomPainter {
  const _StrokesPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / _viewBox);
    canvas.translate(-_origin, -_origin);
    canvas.drawPath(_outline, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_StrokesPainter old) => old.color != color;
}
