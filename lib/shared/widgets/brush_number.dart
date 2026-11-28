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
      text.isNotEmpty && text.split('').every(_glyphs.containsKey),
      'BrushNumber draws a non-empty run of digits and colons: "$text"',
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
        child: ClipRect(
          child: CustomPaint(painter: _NumberPainter(glyphs, paint, h)),
        ),
      ),
    );
  }
}

double _pitch(Glyph g, double h) => (g.width / _box + _gap) * h;

double _width(List<Glyph> glyphs, double h) =>
    glyphs.fold<double>(0, (sum, g) => sum + _pitch(g, h)) - _gap * h;

double brushNumberWidth(String text, double scaledHeight) =>
    _width([for (final c in text.split('')) _glyphs[c]!], scaledHeight);

class _NumberPainter extends CustomPainter {
  const _NumberPainter(this.glyphs, this.color, this.height);

  final List<Glyph> glyphs;
  final Color color;
  final double height;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = height / _box;
    final paint = Paint()..color = color;
    var x = 0.0;
    for (final g in glyphs) {
      canvas.save();
      canvas.translate(x, _top * scale);
      canvas.scale(scale);
      canvas.translate(-g.left, 0);
      canvas.drawPath(_outline(g), paint);
      canvas.restore();
      x += _pitch(g, height);
    }
  }

  @override
  bool shouldRepaint(_NumberPainter old) =>
      old.color != color ||
      old.height != height ||
      !listEquals(old.glyphs, glyphs);
}
