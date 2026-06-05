import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Canonical spacing scale on the 4px grid — the single source of truth.
///
/// `const`-usable so migrated call sites keep their const-ness, e.g.
/// `const EdgeInsets.all(SpacingScale.s16)`, `const SizedBox(height: SpacingScale.s8)`.
abstract final class SpacingScale {
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s28 = 28;
  static const double s32 = 32;
  static const double s40 = 40;
  static const double s48 = 48;
}

/// Theme-scoped spacing tokens. Defaults to [SpacingScale]; registered in
/// `ThemeData.extensions` and read via `context.spacing.s16`.
class AppSpacing extends ThemeExtension<AppSpacing> {
  const AppSpacing({
    this.s4 = SpacingScale.s4,
    this.s8 = SpacingScale.s8,
    this.s12 = SpacingScale.s12,
    this.s16 = SpacingScale.s16,
    this.s20 = SpacingScale.s20,
    this.s24 = SpacingScale.s24,
    this.s28 = SpacingScale.s28,
    this.s32 = SpacingScale.s32,
    this.s40 = SpacingScale.s40,
    this.s48 = SpacingScale.s48,
  });

  final double s4;
  final double s8;
  final double s12;
  final double s16;
  final double s20;
  final double s24;
  final double s28;
  final double s32;
  final double s40;
  final double s48;

  /// Registered value, and the `context.spacing` default when unregistered.
  static const AppSpacing fallback = AppSpacing();

  @override
  AppSpacing copyWith({
    double? s4,
    double? s8,
    double? s12,
    double? s16,
    double? s20,
    double? s24,
    double? s28,
    double? s32,
    double? s40,
    double? s48,
  }) {
    return AppSpacing(
      s4: s4 ?? this.s4,
      s8: s8 ?? this.s8,
      s12: s12 ?? this.s12,
      s16: s16 ?? this.s16,
      s20: s20 ?? this.s20,
      s24: s24 ?? this.s24,
      s28: s28 ?? this.s28,
      s32: s32 ?? this.s32,
      s40: s40 ?? this.s40,
      s48: s48 ?? this.s48,
    );
  }

  @override
  AppSpacing lerp(AppSpacing? other, double t) {
    if (other is! AppSpacing) return this;
    return AppSpacing(
      s4: lerpDouble(s4, other.s4, t)!,
      s8: lerpDouble(s8, other.s8, t)!,
      s12: lerpDouble(s12, other.s12, t)!,
      s16: lerpDouble(s16, other.s16, t)!,
      s20: lerpDouble(s20, other.s20, t)!,
      s24: lerpDouble(s24, other.s24, t)!,
      s28: lerpDouble(s28, other.s28, t)!,
      s32: lerpDouble(s32, other.s32, t)!,
      s40: lerpDouble(s40, other.s40, t)!,
      s48: lerpDouble(s48, other.s48, t)!,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSpacing &&
          other.s4 == s4 &&
          other.s8 == s8 &&
          other.s12 == s12 &&
          other.s16 == s16 &&
          other.s20 == s20 &&
          other.s24 == s24 &&
          other.s28 == s28 &&
          other.s32 == s32 &&
          other.s40 == s40 &&
          other.s48 == s48;

  @override
  int get hashCode =>
      Object.hash(s4, s8, s12, s16, s20, s24, s28, s32, s40, s48);
}
