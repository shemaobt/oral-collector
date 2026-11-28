import 'package:flutter/widgets.dart';

const double _viewBox = 116;
const double _disc = 84;
const double _origin = -16;

class OutlineHalo extends StatelessWidget {
  const OutlineHalo({
    super.key,
    required this.diameter,
    required this.color,
    required this.outline,
    required this.shown,
    required this.child,
  });

  final double diameter;
  final Color color;
  final Path outline;
  final bool shown;
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
                child: shown
                    ? CustomPaint(
                        size: Size.square(box),
                        painter: _HaloPainter(outline, color),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _HaloPainter extends CustomPainter {
  const _HaloPainter(this.outline, this.color);

  final Path outline;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / _viewBox);
    canvas.translate(-_origin, -_origin);
    canvas.drawPath(outline, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_HaloPainter old) =>
      old.outline != outline || old.color != color;
}
