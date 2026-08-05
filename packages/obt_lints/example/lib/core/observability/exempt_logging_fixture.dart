import 'package:flutter/material.dart';

// Este arquivo está sob lib/core/observability/ → isento (ADR-0010). As linhas
// abaixo NÃO podem sinalizar (sem // expect_lint); se sinalizarem, o run falha
// (lint inesperado).
void lowLevelFallback() {
  print('boot');
  debugPrint('boot');
}
