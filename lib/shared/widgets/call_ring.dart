import 'package:flutter/widgets.dart';

import 'brush_sign.dart';
import 'brush_signs.dart';
import 'outline_halo.dart';

final Path _outline = parseOutline(callRingOutline);

class CallRing extends StatelessWidget {
  const CallRing({
    super.key,
    required this.diameter,
    required this.color,
    required this.calling,
    required this.child,
  });

  final double diameter;
  final Color color;
  final bool calling;
  final Widget child;

  @override
  Widget build(BuildContext context) => OutlineHalo(
    diameter: diameter,
    color: color,
    outline: _outline,
    shown: calling,
    child: child,
  );
}
