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

class PrintedShadows {
  final Color ink;
  final Color paper;
  final Color brick;
  final Color tile;
  final Color clay;
  final Color terracotta;

  const PrintedShadows({
    required this.ink,
    required this.paper,
    required this.brick,
    required this.tile,
    required this.clay,
    required this.terracotta,
  });

  static const light = PrintedShadows(
    ink: Color(0xFFCFCDB2),
    paper: Color(0xFFDBD5C6),
    brick: Color(0xFFDFC1B6),
    tile: Color(0xFFEBC9AD),
    clay: Color(0xFFE4DBCB),
    terracotta: Color(0xFFE4BFA6),
  );

  static const dark = PrintedShadows(
    ink: Color(0xFF16160E),
    paper: Color(0xFF16160E),
    brick: Color(0xFF16160E),
    tile: Color(0xFF16160E),
    clay: Color(0xFF16160E),
    terracotta: Color(0xFF16160E),
  );

  static PrintedShadows of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}
