import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'brush_sign.dart';
import 'brush_signs.dart';

const double _box = 116;
const double _top = 8;
const double _gap = 0.04;

final _glyphs = {for (final g in Glyph.values) g.char: g};
final _paths = <Glyph, Path>{};

Path _outline(Glyph glyph) =>
    _paths.putIfAbsent(glyph, () => parseOutline(glyph.outline));

class BrushNumber extends StatelessWidget {
  const BrushNumber(
    this.text, {
    super.key,
    required this.height,
    this.color,
    this.label,
  });

  final String text;
  final double height;
  final Color? color;
  final String? label;

  @override
  Widget build(BuildContext context) {
    assert(
      text.split('').every(_glyphs.containsKey),
      'BrushNumber draws only digits and a colon: "$text"',
    );
    final h = MediaQuery.textScalerOf(context).scale(height);
    final glyphs = [for (final c in text.split('')) _glyphs[c]!];
    final paint = color ?? DefaultTextStyle.of(context).style.color!;
    final width = _width(glyphs, h);
    return Semantics(
      label: label ?? text,
      excludeSemantics: true,
      child: SizedBox(
        width: width,
        height: h,
        child: CustomPaint(painter: _NumberPainter(glyphs, paint)),
      ),
    );
  }
}

double _width(List<Glyph> glyphs, double h) {
  final advances = glyphs.fold<double>(0, (sum, g) => sum + g.width);
  return advances / _box * h + _gap * h * (glyphs.length - 1);
}

class _NumberPainter extends CustomPainter {
  const _NumberPainter(this.glyphs, this.color);

  final List<Glyph> glyphs;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.height / _box;
    final paint = Paint()..color = color;
    var x = 0.0;
    for (final g in glyphs) {
      canvas.save();
      canvas.translate(x, _top * scale);
      canvas.scale(scale);
      canvas.translate(-g.left, 0);
      canvas.drawPath(_outline(g), paint);
      canvas.restore();
      x += (g.width / _box + _gap) * size.height;
    }
  }

  @override
  bool shouldRepaint(_NumberPainter old) =>
      old.color != color || !listEquals(old.glyphs, glyphs);
}
