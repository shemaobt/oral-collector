import 'package:flutter/widgets.dart';

import 'brush_sign.dart';
import 'brush_signs.dart';
import 'outline_halo.dart';

final Path _outline = parseOutline(soundStrokesOutline);

class SoundStrokes extends StatelessWidget {
  const SoundStrokes({
    super.key,
    required this.diameter,
    required this.color,
    required this.sounding,
    required this.child,
  });

  final double diameter;
  final Color color;
  final bool sounding;
  final Widget child;

  @override
  Widget build(BuildContext context) => OutlineHalo(
    diameter: diameter,
    color: color,
    outline: _outline,
    shown: sounding,
    child: child,
  );
}
