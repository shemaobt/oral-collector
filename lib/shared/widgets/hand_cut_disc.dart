import 'package:flutter/widgets.dart';

import 'brush_sign.dart';

const double _units = 84;
const Offset _shadowUnits = Offset(3.1, 3.5);

const String _outline =
    'M82.5 35.6Q83.4 42.0 82.5 48.4Q81.5 54.8 78.6 60.6Q75.7 66.5 71.2 71.2Q66.7 76.0 60.9 79.2Q55.1 82.4 48.6 83.4Q42.0 84.4 35.5 83.2Q29.0 82.0 23.2 79.0Q17.3 75.9 12.6 71.4Q7.8 66.8 4.8 61.0Q1.7 55.1 0.9 48.5Q0.1 42.0 1.3 35.6Q2.5 29.2 5.4 23.4Q8.4 17.6 13.0 13.0Q17.6 8.4 23.3 5.4Q29.1 2.4 35.6 1.1Q42.0 -0.2 48.6 0.5Q55.3 1.2 61.2 4.2Q67.2 7.3 71.7 12.3Q76.1 17.2 78.8 23.2Q81.5 29.2 82.5 35.6Z';

final Path _disc = parseOutline(_outline);

class HandCutDiscPainter extends CustomPainter {
  const HandCutDiscPainter({required this.fill, this.shadow});

  final Color fill;
  final Color? shadow;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / _units);
    final shadowColor = shadow;
    if (shadowColor != null) {
      canvas.drawPath(_disc.shift(_shadowUnits), Paint()..color = shadowColor);
    }
    canvas.drawPath(_disc, Paint()..color = fill);
  }

  @override
  bool shouldRepaint(HandCutDiscPainter old) =>
      old.fill != fill || old.shadow != shadow;
}

class HandCutDiscClipper extends CustomClipper<Path> {
  const HandCutDiscClipper();

  @override
  Path getClip(Size size) => _disc.transform(
    Matrix4.diagonal3Values(
      size.width / _units,
      size.height / _units,
      1,
    ).storage,
  );

  @override
  bool shouldReclip(HandCutDiscClipper old) => false;
}
