import 'package:flutter/material.dart';

// Este arquivo está sob test/ → isento (ENG-183). As linhas abaixo NÃO podem
// sinalizar (sem // expect_lint); se sinalizarem, o run falha (lint inesperado).
abstract class TestFixtureColors {
  static const Color brand = Color(0xFF123456);
  static const Color white = Colors.white;
}

// test/ também é isento de avoid_raw_print. As chamadas abaixo NÃO podem
// sinalizar.
void debugInTest() {
  print('debugging a test');
  debugPrint('debugging a test');
}
