import 'package:flutter/material.dart';

// --- Violações (DEVEM sinalizar) ---

// expect_lint: avoid_hardcoded_color
const seed = Color(0xFF3D8E80);

// expect_lint: avoid_hardcoded_color
final fromArgb = Color.fromARGB(255, 1, 2, 3);

Color whiteBox() {
  // expect_lint: avoid_material_colors
  return Colors.white;
}

Color blended() {
  // expect_lint: avoid_material_colors
  return Colors.black.withValues(alpha: 0.08);
}

Color accent() {
  // expect_lint: avoid_material_colors
  return Colors.redAccent;
}

Color shade() {
  // expect_lint: avoid_material_colors
  return Colors.red.shade300;
}

// --- Controles (NÃO podem sinalizar — sem // expect_lint) ---

class AppColors {
  const AppColors(this.primary);
  final Color primary;
}

Color noFalsePositive(AppColors tokens) {
  final a = tokens.primary; // acesso a membro, não Colors.* → sem lint
  return Color.lerp(a, a, 0.5)!; // método estático, não construtor → sem lint
}
