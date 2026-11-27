import 'package:flutter/material.dart';

class ShadowTints {
  final Color card;
  final Color lift;
  final Color bar;
  final Color slab;
  final List<BoxShadow> edge;

  const ShadowTints({
    required this.card,
    required this.lift,
    required this.bar,
    required this.slab,
    required this.edge,
  });

  static const light = ShadowTints(
    card: Color.fromRGBO(63, 62, 32, 0.45),
    lift: Color.fromRGBO(52, 51, 26, 0.35),
    bar: Color.fromRGBO(52, 51, 26, 0.55),
    slab: Color.fromRGBO(52, 51, 26, 0.7),
    edge: [
      BoxShadow(color: Color.fromRGBO(70, 58, 30, 0.05), spreadRadius: 1),
      BoxShadow(
        color: Color.fromRGBO(70, 58, 30, 0.05),
        offset: Offset(0, 1),
        blurRadius: 2,
      ),
      BoxShadow(
        color: Color.fromRGBO(70, 58, 30, 0.18),
        offset: Offset(0, 10),
        blurRadius: 24,
        spreadRadius: -14,
      ),
    ],
  );

  static const dark = ShadowTints(
    card: Color.fromRGBO(0, 0, 0, 0.45),
    lift: Color.fromRGBO(0, 0, 0, 0.35),
    bar: Color.fromRGBO(0, 0, 0, 0.55),
    slab: Color.fromRGBO(0, 0, 0, 0.7),
    edge: [
      BoxShadow(color: Color.fromRGBO(243, 239, 226, 0.07), spreadRadius: 1),
    ],
  );

  static ShadowTints of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}
