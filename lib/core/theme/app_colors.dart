import 'package:flutter/material.dart';

class AppColorSet {
  final Color primary;
  final Color accent;
  final Color background;
  final Color foreground;
  final Color card;
  final Color surfaceAlt;
  final Color secondary;
  final Color info;
  final Color success;
  final Color border;
  final Color error;

  const AppColorSet({
    required this.primary,
    required this.accent,
    required this.background,
    required this.foreground,
    required this.card,
    required this.surfaceAlt,
    required this.secondary,
    required this.info,
    required this.success,
    required this.border,
    required this.error,
  });
}

abstract class AppColors {
  static const Color primary = Color(0xFF2E2D0C);
  static const Color accent = Color(0xFFD45200);
  static const Color background = Color(0xFFEEEBDD);
  static const Color foreground = Color(0xFF0A0703);
  static const Color card = Color(0xFFFAF9F3);
  static const Color surfaceAlt = Color(0xFFD9D5C2);
  static const Color secondary = Color(0xFF46452C);
  static const Color info = Color(0xFF178570);
  static const Color success = Color(0xFF3F6E10);
  static const Color border = Color(0xFF9A9671);
  static const Color error = Color(0xFFDC2626);

  static const Color darkPrimary = Color(0xFFD4D1A8);
  static const Color darkAccent = Color(0xFFF09045);
  static const Color darkBackground = Color(0xFF1C1A14);
  static const Color darkForeground = Color(0xFFF2EFE4);
  static const Color darkSurface = Color(0xFF262318);
  static const Color darkSurfaceAlt = Color(0xFF302D22);
  static const Color darkSecondary = Color(0xFF9E9C7A);
  static const Color darkInfo = Color(0xFF4EC4AD);
  static const Color darkSuccess = Color(0xFF9DC044);
  static const Color darkBorder = Color(0xFF5A5440);

  static AppColorSet of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? _dark : _light;
  }

  static const _light = AppColorSet(
    primary: primary,
    accent: accent,
    background: background,
    foreground: foreground,
    card: card,
    surfaceAlt: surfaceAlt,
    secondary: secondary,
    info: info,
    success: success,
    border: border,
    error: error,
  );

  static const _dark = AppColorSet(
    primary: darkPrimary,
    accent: darkAccent,
    background: darkBackground,
    foreground: darkForeground,
    card: darkSurface,
    surfaceAlt: darkSurfaceAlt,
    secondary: darkSecondary,
    info: darkInfo,
    success: darkSuccess,
    border: darkBorder,
    error: error,
  );
}
