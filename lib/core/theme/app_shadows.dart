import 'package:flutter/material.dart';

class ShadowTints {
  final Color card;
  final Color lift;
  final Color bar;
  final Color slab;

  const ShadowTints({
    required this.card,
    required this.lift,
    required this.bar,
    required this.slab,
  });

  static const light = ShadowTints(
    card: Color.fromRGBO(63, 62, 32, 0.45),
    lift: Color.fromRGBO(52, 51, 26, 0.35),
    bar: Color.fromRGBO(52, 51, 26, 0.55),
    slab: Color.fromRGBO(52, 51, 26, 0.7),
  );

  static const dark = ShadowTints(
    card: Color.fromRGBO(0, 0, 0, 0.45),
    lift: Color.fromRGBO(0, 0, 0, 0.35),
    bar: Color.fromRGBO(0, 0, 0, 0.55),
    slab: Color.fromRGBO(0, 0, 0, 0.7),
  );

  static ShadowTints of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}
