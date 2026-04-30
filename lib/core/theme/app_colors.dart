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
  final Color infoText;
  final Color success;
  final Color successText;
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
    required this.infoText,
    required this.success,
    required this.successText,
    required this.border,
    required this.error,
  });
}

abstract class AppColors {
  static const Color brandBranco = Color(0xFFF6F5EB);
  static const Color brandAreia = Color(0xFFC5C29F);
  static const Color brandAzul = Color(0xFF89AAA3);
  static const Color brandTelha = Color(0xFFBE4A01);
  static const Color brandVerdeClaro = Color(0xFF777D45);
  static const Color brandVerde = Color(0xFF3F3E20);
  static const Color brandPreto = Color(0xFF0A0703);

  static const Color primary = brandVerde;
  static const Color accent = brandTelha;
  static const Color background = brandBranco;
  static const Color foreground = brandPreto;
  static const Color card = Color(0xFFFDFCF3);
  static const Color surfaceAlt = Color(0xFFEDE9D5);
  static const Color secondary = Color(0xFF4A4830);
  static const Color info = brandAzul;
  static const Color infoText = Color(0xFF4D6F68);
  static const Color success = brandVerdeClaro;
  static const Color successText = Color(0xFF5D6233);
  static const Color border = brandAreia;
  static const Color error = Color(0xFFB91C1C);

  static const Color surfaceContainerLowest = Color(0xFFFDFCF3);
  static const Color surfaceContainerLow = Color(0xFFFAF8EC);
  static const Color surfaceContainer = Color(0xFFF6F5EB);
  static const Color surfaceContainerHigh = Color(0xFFF1EEDE);
  static const Color surfaceContainerHighest = Color(0xFFEDE9D5);
  static const Color outlineVariant = Color(0xFFE3DFC4);
  static const Color switchThumbUnselected = Color(0xFF8B8863);

  static const Color darkPrimary = Color(0xFFD4D1A8);
  static const Color darkAccent = Color(0xFFF09045);
  static const Color darkBackground = Color(0xFF1C1A14);
  static const Color darkForeground = Color(0xFFF2EFE4);
  static const Color darkSurface = Color(0xFF262318);
  static const Color darkSurfaceAlt = Color(0xFF302D22);
  static const Color darkSecondary = Color(0xFF9E9C7A);
  static const Color darkInfo = Color(0xFF4EC4AD);
  static const Color darkInfoText = Color(0xFF9FD4C6);
  static const Color darkSuccess = Color(0xFF9DC044);
  static const Color darkSuccessText = Color(0xFFB4C976);
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
    infoText: infoText,
    success: success,
    successText: successText,
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
    infoText: darkInfoText,
    success: darkSuccess,
    successText: darkSuccessText,
    border: darkBorder,
    error: error,
  );
}
