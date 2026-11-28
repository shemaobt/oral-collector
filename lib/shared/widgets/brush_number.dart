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
    this.tabular = false,
  });

  final String text;
  final double height;
  final Color? color;
  final String? label;
  final bool tabular;

  @override
  Widget build(BuildContext context) {
    assert(
      text.isNotEmpty && text.split('').every(_glyphs.containsKey),
      'BrushNumber draws a non-empty run of digits and colons: "$text"',
    );
    final h = MediaQuery.textScalerOf(context).scale(height);
    final glyphs = [for (final c in text.split('')) _glyphs[c]!];
    final paint = color ?? DefaultTextStyle.of(context).style.color!;
    final slots = [for (final g in glyphs) _slot(g, tabular)];
    final width = _width(slots, h);
    return Semantics(
      label: label ?? text,
      excludeSemantics: true,
      child: SizedBox(
        width: width,
        height: h,
        child: ClipRect(
          child: CustomPaint(painter: _NumberPainter(glyphs, slots, paint, h)),
        ),
      ),
    );
  }
}

final _digitSlot = Glyph.values
    .where((g) => g.char != ':')
    .map((g) => g.width)
    .reduce((a, b) => a > b ? a : b);

double _slot(Glyph g, bool tabular) =>
    tabular && g.char != ':' ? _digitSlot : g.width;

double _pitch(double slot, double h) => (slot / _box + _gap) * h;

double _width(List<double> slots, double h) =>
    slots.fold<double>(0, (sum, s) => sum + _pitch(s, h)) - _gap * h;

double brushNumberWidth(String text, double scaledHeight) =>
    _width([for (final c in text.split('')) _glyphs[c]!], scaledHeight);

class _NumberPainter extends CustomPainter {
  const _NumberPainter(this.glyphs, this.slots, this.color, this.height);

  final List<Glyph> glyphs;
  final List<double> slots;
  final Color color;
  final double height;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = height / _box;
    final paint = Paint()..color = color;
    var x = 0.0;
    for (var i = 0; i < glyphs.length; i++) {
      final g = glyphs[i];
      canvas.save();
      canvas.translate(x + (slots[i] - g.width) / 2 * scale, _top * scale);
      canvas.scale(scale);
      canvas.translate(-g.left, 0);
      canvas.drawPath(_outline(g), paint);
      canvas.restore();
      x += _pitch(slots[i], height);
    }
  }

  @override
  bool shouldRepaint(_NumberPainter old) =>
      old.color != color ||
      old.height != height ||
      !listEquals(old.glyphs, glyphs) ||
      !listEquals(old.slots, slots);
}
