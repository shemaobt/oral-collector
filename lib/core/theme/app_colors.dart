import 'package:flutter/material.dart';

class AppColorSet extends ThemeExtension<AppColorSet> {
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
  final Color warning;
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
    required this.warning,
    required this.border,
    required this.error,
  });

  @override
  AppColorSet copyWith({
    Color? primary,
    Color? accent,
    Color? background,
    Color? foreground,
    Color? card,
    Color? surfaceAlt,
    Color? secondary,
    Color? info,
    Color? infoText,
    Color? success,
    Color? successText,
    Color? warning,
    Color? border,
    Color? error,
  }) {
    return AppColorSet(
      primary: primary ?? this.primary,
      accent: accent ?? this.accent,
      background: background ?? this.background,
      foreground: foreground ?? this.foreground,
      card: card ?? this.card,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      secondary: secondary ?? this.secondary,
      info: info ?? this.info,
      infoText: infoText ?? this.infoText,
      success: success ?? this.success,
      successText: successText ?? this.successText,
      warning: warning ?? this.warning,
      border: border ?? this.border,
      error: error ?? this.error,
    );
  }

  @override
  AppColorSet lerp(covariant ThemeExtension<AppColorSet>? other, double t) {
    if (other is! AppColorSet) return this;
    return AppColorSet(
      primary: Color.lerp(primary, other.primary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      background: Color.lerp(background, other.background, t)!,
      foreground: Color.lerp(foreground, other.foreground, t)!,
      card: Color.lerp(card, other.card, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoText: Color.lerp(infoText, other.infoText, t)!,
      success: Color.lerp(success, other.success, t)!,
      successText: Color.lerp(successText, other.successText, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      border: Color.lerp(border, other.border, t)!,
      error: Color.lerp(error, other.error, t)!,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppColorSet &&
        other.primary == primary &&
        other.accent == accent &&
        other.background == background &&
        other.foreground == foreground &&
        other.card == card &&
        other.surfaceAlt == surfaceAlt &&
        other.secondary == secondary &&
        other.info == info &&
        other.infoText == infoText &&
        other.success == success &&
        other.successText == successText &&
        other.warning == warning &&
        other.border == border &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(
    primary,
    accent,
    background,
    foreground,
    card,
    surfaceAlt,
    secondary,
    info,
    infoText,
    success,
    successText,
    warning,
    border,
    error,
  );
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
  static const Color warning = Color(0xFFFFA000);
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
  static const Color darkWarning = Color(0xFFE0A458);
  static const Color darkBorder = Color(0xFF5A5440);

  static AppColorSet of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<AppColorSet>() ??
        (theme.brightness == Brightness.dark ? dark : light);
  }

  static const light = AppColorSet(
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
    warning: warning,
    border: border,
    error: error,
  );

  static const dark = AppColorSet(
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
    warning: darkWarning,
    border: darkBorder,
    error: error,
  );
}
