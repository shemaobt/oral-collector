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

class QuestionShadows {
  static const light = [
    BoxShadow(color: Color.fromRGBO(63, 62, 32, 0.06), spreadRadius: 1),
    BoxShadow(
      color: Color.fromRGBO(63, 62, 32, 0.6),
      offset: Offset(0, 24),
      blurRadius: 50,
      spreadRadius: -24,
    ),
  ];

  static const dark = [
    BoxShadow(color: Color.fromRGBO(243, 239, 226, 0.08), spreadRadius: 1),
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.7),
      offset: Offset(0, 24),
      blurRadius: 50,
      spreadRadius: -20,
    ),
  ];

  static List<BoxShadow> of(BuildContext context) =>
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
