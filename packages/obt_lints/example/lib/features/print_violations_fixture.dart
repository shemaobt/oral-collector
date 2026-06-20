import 'package:flutter/material.dart'; // re-exporta debugPrint (foundation)

// --- Violações (DEVEM sinalizar) ---

void logsRaw() {
  // expect_lint: avoid_raw_print
  print('hello');
  // expect_lint: avoid_raw_print
  debugPrint('world');
}

// --- Controles (NÃO podem sinalizar — sem // expect_lint) ---

// Função homônima de um objeto (chamada com receptor → target != null): é um
// método de instância, não a global print/debugPrint. A regra não pode sinalizar.
class Printer {
  void print(String s) {}
  void debugPrint(String s) {}
}

void usesReceiver(Printer p) {
  p.print('ok');
  p.debugPrint('ok');
}

// Chamada top-level de função benigna (target == null, mas nome ≠
// print/debugPrint): prova que a regra discrimina pelo nome e não sinaliza
// qualquer invocação sem receptor.
void greet(String s) {}

void usesBenignTopLevel() {
  greet('ok');
}
