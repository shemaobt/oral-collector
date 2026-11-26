import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'brush_signs.dart';

export 'brush_signs.dart' show Sign;

const double _box = 116;
const double _air = 8;

class BrushSign extends StatelessWidget {
  const BrushSign(
    this.sign, {
    super.key,
    this.size,
    this.color,
    this.label,
    this.turns = 0,
  });

  final Sign sign;
  final double? size;
  final Color? color;
  final String? label;
  final double turns;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final side = size ?? theme.size!;
    final flip =
        sign.mirrorsInRtl && Directionality.of(context) == TextDirection.rtl;
    final drawing = SizedBox.square(
      dimension: side,
      child: CustomPaint(
        painter: _SignPainter(sign, color ?? theme.color!, flip, turns),
      ),
    );
    if (label == null) return ExcludeSemantics(child: drawing);
    return Semantics(
      label: label,
      image: true,
      excludeSemantics: true,
      child: drawing,
    );
  }
}

final _paths = <Sign, Path>{};

Path _outline(Sign sign) =>
    _paths.putIfAbsent(sign, () => parseOutline(sign.outline));

final _command = RegExp(r'([MLQZ])([^MLQZ]*)');

Path parseOutline(String d) {
  final path = Path();
  for (final match in _command.allMatches(d)) {
    final n = [
      for (final t in match[2]!.split(' '))
        if (t.isNotEmpty) double.parse(t),
    ];
    switch (match[1]) {
      case 'M':
        path.moveTo(n[0], n[1]);
      case 'L':
        path.lineTo(n[0], n[1]);
      case 'Q':
        path.quadraticBezierTo(n[0], n[1], n[2], n[3]);
      case 'Z':
        path.close();
    }
  }
  return path;
}

class _SignPainter extends CustomPainter {
  const _SignPainter(this.sign, this.color, this.flip, this.turns);

  final Sign sign;
  final Color color;
  final bool flip;
  final double turns;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / _box;
    canvas.translate(size.width / 2, size.height / 2);
    if (flip) canvas.scale(-1, 1);
    canvas.rotate(turns * 2 * math.pi);
    canvas.scale(scale);
    canvas.translate(-_box / 2 + _air, -_box / 2 + _air);
    canvas.drawPath(_outline(sign), Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SignPainter old) =>
      old.sign != sign ||
      old.color != color ||
      old.flip != flip ||
      old.turns != turns;
}
