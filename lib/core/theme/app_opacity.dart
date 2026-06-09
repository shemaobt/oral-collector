import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Canonical opacity/alpha scale (raw doubles) — the single source of truth.
///
/// Migration keeps the existing call shape:
/// `color.withValues(alpha: OpacityScale.o40)`.
abstract final class OpacityScale {
  static const double o06 = 0.06;
  static const double o08 = 0.08;
  static const double o10 = 0.1;
  static const double o12 = 0.12;
  static const double o15 = 0.15;
  static const double o30 = 0.3;
  static const double o40 = 0.4;
  static const double o50 = 0.5;
  static const double o55 = 0.55;
  static const double o60 = 0.6;
  static const double o70 = 0.7;
}

/// Theme-scoped opacity tokens. Defaults to [OpacityScale]; read via
/// `context.opacity.o40`.
class AppOpacity extends ThemeExtension<AppOpacity> {
  const AppOpacity({
    this.o06 = OpacityScale.o06,
    this.o08 = OpacityScale.o08,
    this.o10 = OpacityScale.o10,
    this.o12 = OpacityScale.o12,
    this.o15 = OpacityScale.o15,
    this.o30 = OpacityScale.o30,
    this.o40 = OpacityScale.o40,
    this.o50 = OpacityScale.o50,
    this.o55 = OpacityScale.o55,
    this.o60 = OpacityScale.o60,
    this.o70 = OpacityScale.o70,
  });

  final double o06;
  final double o08;
  final double o10;
  final double o12;
  final double o15;
  final double o30;
  final double o40;
  final double o50;
  final double o55;
  final double o60;
  final double o70;

  /// Registered value, and the `context.opacity` default when unregistered.
  static const AppOpacity fallback = AppOpacity();

  @override
  AppOpacity copyWith({
    double? o06,
    double? o08,
    double? o10,
    double? o12,
    double? o15,
    double? o30,
    double? o40,
    double? o50,
    double? o55,
    double? o60,
    double? o70,
  }) {
    return AppOpacity(
      o06: o06 ?? this.o06,
      o08: o08 ?? this.o08,
      o10: o10 ?? this.o10,
      o12: o12 ?? this.o12,
      o15: o15 ?? this.o15,
      o30: o30 ?? this.o30,
      o40: o40 ?? this.o40,
      o50: o50 ?? this.o50,
      o55: o55 ?? this.o55,
      o60: o60 ?? this.o60,
      o70: o70 ?? this.o70,
    );
  }

  @override
  AppOpacity lerp(AppOpacity? other, double t) {
    if (other is! AppOpacity) return this;
    return AppOpacity(
      o06: lerpDouble(o06, other.o06, t)!,
      o08: lerpDouble(o08, other.o08, t)!,
      o10: lerpDouble(o10, other.o10, t)!,
      o12: lerpDouble(o12, other.o12, t)!,
      o15: lerpDouble(o15, other.o15, t)!,
      o30: lerpDouble(o30, other.o30, t)!,
      o40: lerpDouble(o40, other.o40, t)!,
      o50: lerpDouble(o50, other.o50, t)!,
      o55: lerpDouble(o55, other.o55, t)!,
      o60: lerpDouble(o60, other.o60, t)!,
      o70: lerpDouble(o70, other.o70, t)!,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppOpacity &&
          other.o06 == o06 &&
          other.o08 == o08 &&
          other.o10 == o10 &&
          other.o12 == o12 &&
          other.o15 == o15 &&
          other.o30 == o30 &&
          other.o40 == o40 &&
          other.o50 == o50 &&
          other.o55 == o55 &&
          other.o60 == o60 &&
          other.o70 == o70;

  @override
  int get hashCode =>
      Object.hash(o06, o08, o10, o12, o15, o30, o40, o50, o55, o60, o70);
}
