import 'package:flutter/foundation.dart';
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
  final Color success;
  final Color onPrimary;
  final Color warning;
  final Color border;
  final Color error;
  final Color deep;
  final Color soft;
  final Color wood;
  final Color pale;
  final Color tint;
  final Color mic;
  final Color clay;
  final Color sand;
  final Color onColor;
  final Color knob;
  final Color count;
  final Color onSoft;
  final Color noteInk;
  final Color stretch;

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
    required this.onPrimary,
    required this.warning,
    required this.border,
    required this.error,
    required this.deep,
    required this.soft,
    required this.wood,
    required this.pale,
    required this.tint,
    required this.mic,
    required this.clay,
    required this.sand,
    required this.onColor,
    required this.knob,
    required this.count,
    required this.onSoft,
    required this.noteInk,
    required this.stretch,
  });

  static Color _keep(Color? next, Color current) => next ?? current;

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
    Color? success,
    Color? onPrimary,
    Color? warning,
    Color? border,
    Color? error,
    Color? deep,
    Color? soft,
    Color? wood,
    Color? pale,
    Color? tint,
    Color? mic,
    Color? clay,
    Color? sand,
    Color? onColor,
    Color? knob,
    Color? count,
    Color? onSoft,
    Color? noteInk,
    Color? stretch,
  }) {
    return AppColorSet(
      primary: _keep(primary, this.primary),
      accent: _keep(accent, this.accent),
      background: _keep(background, this.background),
      foreground: _keep(foreground, this.foreground),
      card: _keep(card, this.card),
      surfaceAlt: _keep(surfaceAlt, this.surfaceAlt),
      secondary: _keep(secondary, this.secondary),
      info: _keep(info, this.info),
      success: _keep(success, this.success),
      onPrimary: _keep(onPrimary, this.onPrimary),
      warning: _keep(warning, this.warning),
      border: _keep(border, this.border),
      error: _keep(error, this.error),
      deep: _keep(deep, this.deep),
      soft: _keep(soft, this.soft),
      wood: _keep(wood, this.wood),
      pale: _keep(pale, this.pale),
      tint: _keep(tint, this.tint),
      mic: _keep(mic, this.mic),
      clay: _keep(clay, this.clay),
      sand: _keep(sand, this.sand),
      onColor: _keep(onColor, this.onColor),
      knob: _keep(knob, this.knob),
      count: _keep(count, this.count),
      onSoft: _keep(onSoft, this.onSoft),
      noteInk: _keep(noteInk, this.noteInk),
      stretch: _keep(stretch, this.stretch),
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
      success: Color.lerp(success, other.success, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      border: Color.lerp(border, other.border, t)!,
      error: Color.lerp(error, other.error, t)!,
      deep: Color.lerp(deep, other.deep, t)!,
      soft: Color.lerp(soft, other.soft, t)!,
      wood: Color.lerp(wood, other.wood, t)!,
      pale: Color.lerp(pale, other.pale, t)!,
      tint: Color.lerp(tint, other.tint, t)!,
      mic: Color.lerp(mic, other.mic, t)!,
      clay: Color.lerp(clay, other.clay, t)!,
      sand: Color.lerp(sand, other.sand, t)!,
      onColor: Color.lerp(onColor, other.onColor, t)!,
      knob: Color.lerp(knob, other.knob, t)!,
      count: Color.lerp(count, other.count, t)!,
      onSoft: Color.lerp(onSoft, other.onSoft, t)!,
      noteInk: Color.lerp(noteInk, other.noteInk, t)!,
      stretch: Color.lerp(stretch, other.stretch, t)!,
    );
  }

  List<Color> get _roles => [
    primary,
    accent,
    background,
    foreground,
    card,
    surfaceAlt,
    secondary,
    info,
    success,
    onPrimary,
    warning,
    border,
    error,
    deep,
    soft,
    wood,
    pale,
    tint,
    mic,
    clay,
    sand,
    onColor,
    knob,
    count,
    onSoft,
    noteInk,
    stretch,
  ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppColorSet && listEquals(other._roles, _roles);
  }

  @override
  int get hashCode => Object.hashAll(_roles);
}

abstract class AppColors {
  static const Color brandPonte = Color(0xFF3F6862);
  static const Color brandTelha = Color(0xFFBE4A01);
  static const Color brandVerdeClaro = Color(0xFF777D45);
  static const Color brandVerde = Color(0xFF3F3E20);

  static const Color primary = brandVerde;
  static const Color accent = brandTelha;
  static const Color background = Color(0xFFF7F4EE);
  static const Color foreground = brandVerde;
  static const Color card = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF0EDE5);
  static const Color secondary = Color(0xFF5A5A3E);
  static const Color info = brandPonte;
  static const Color success = brandVerdeClaro;

  /// Text and icons drawn on top of [primary]: the page tone, not pure white.
  static const Color onPrimary = background;
  static const Color darkOnPrimary = darkBackground;

  static const Color warning = Color(0xFFC7A268);
  static const Color border = Color.fromRGBO(63, 62, 32, 0.16);
  static const Color error = Color(0xFF872F00);
  static const Color pale = Color(0xFFE9E5DA);
  static const Color mic = Color(0xFF8C2B26);

  static const Color darkPrimary = Color(0xFFF3EFE2);
  static const Color darkAccent = Color(0xFFE08A52);
  static const Color darkBackground = Color(0xFF2A2A1C);
  static const Color darkForeground = Color(0xFFF3EFE2);
  static const Color darkSurface = Color(0xFF373724);
  static const Color darkSurfaceAlt = Color(0xFF424129);
  static const Color darkSecondary = Color(0xFFBDB9A0);
  static const Color darkInfo = Color(0xFFA3C0B9);
  static const Color darkSuccess = Color(0xFFA9AF6F);
  static const Color darkWarning = Color(0xFFE2C08F);
  static const Color darkBorder = Color.fromRGBO(243, 239, 226, 0.15);
  static const Color darkError = Color(0xFFE9C3A6);
  static const Color darkPale = Color(0xFF4B4A31);

  // Neutral anchors: pure white/black/transparent, migrated 1:1 from
  // Colors.white/black/transparent call sites (ENG-183).
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Color(0x00000000);

  // Long-tail semantic tokens migrated from inline literals (ENG-183).
  static const Color authHeroAccent = Color(0xFFFFB380); // signup hero accent

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
    success: success,
    onPrimary: onPrimary,
    warning: warning,
    border: border,
    error: error,
    deep: Color(0xFFA63B00),
    soft: Color(0xFFF2D8C2),
    wood: Color(0xFFF0E2C8),
    pale: pale,
    tint: Color.fromRGBO(63, 62, 32, 0.08),
    mic: mic,
    clay: Color(0xFFB9A990),
    sand: Color(0xFFC5C29F),
    onColor: Color(0xFFFFFFFF),
    knob: Color(0xFFFFFFFF),
    count: mic,
    onSoft: error,
    noteInk: foreground,
    stretch: Color(0xFFF2D8C2),
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
    success: darkSuccess,
    onPrimary: darkOnPrimary,
    warning: darkWarning,
    border: darkBorder,
    error: darkError,
    deep: Color(0xFFEBA573),
    soft: Color(0xFFE9C3A6),
    wood: Color(0xFF4A4028),
    pale: darkPale,
    tint: Color.fromRGBO(243, 239, 226, 0.08),
    mic: Color(0xFFC4584E),
    clay: Color(0xFF9C8F76),
    sand: Color(0xFFC5C29F),
    onColor: Color(0xFFFBF8EF),
    knob: darkSecondary,
    count: darkForeground,
    onSoft: Color(0xFF872F00),
    noteInk: Color(0xFF33321A),
    stretch: Color(0xFF5A593D),
  );
}
