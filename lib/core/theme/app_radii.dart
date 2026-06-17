import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Canonical corner-radius scale (raw doubles) — the single source of truth.
///
/// Migration keeps the existing non-const call shape:
/// `BorderRadius.circular(RadiusScale.r16)`, `Radius.circular(RadiusScale.r12)`.
abstract final class RadiusScale {
  static const double r4 = 4;
  static const double r8 = 8;
  static const double r12 = 12;
  static const double r16 = 16;
  static const double r20 = 20;
  static const double r24 = 24;
  static const double r28 = 28;
  static const double r32 = 32;
}

/// Theme-scoped radius tokens. Defaults to [RadiusScale]; read via
/// `context.radii.r12`.
class AppRadii extends ThemeExtension<AppRadii> {
  const AppRadii({
    this.r4 = RadiusScale.r4,
    this.r8 = RadiusScale.r8,
    this.r12 = RadiusScale.r12,
    this.r16 = RadiusScale.r16,
    this.r20 = RadiusScale.r20,
    this.r24 = RadiusScale.r24,
    this.r28 = RadiusScale.r28,
    this.r32 = RadiusScale.r32,
  });

  final double r4;
  final double r8;
  final double r12;
  final double r16;
  final double r20;
  final double r24;
  final double r28;
  final double r32;

  /// Registered value, and the `context.radii` default when unregistered.
  static const AppRadii fallback = AppRadii();

  @override
  AppRadii copyWith({
    double? r4,
    double? r8,
    double? r12,
    double? r16,
    double? r20,
    double? r24,
    double? r28,
    double? r32,
  }) {
    return AppRadii(
      r4: r4 ?? this.r4,
      r8: r8 ?? this.r8,
      r12: r12 ?? this.r12,
      r16: r16 ?? this.r16,
      r20: r20 ?? this.r20,
      r24: r24 ?? this.r24,
      r28: r28 ?? this.r28,
      r32: r32 ?? this.r32,
    );
  }

  @override
  AppRadii lerp(AppRadii? other, double t) {
    if (other is! AppRadii) return this;
    return AppRadii(
      r4: lerpDouble(r4, other.r4, t)!,
      r8: lerpDouble(r8, other.r8, t)!,
      r12: lerpDouble(r12, other.r12, t)!,
      r16: lerpDouble(r16, other.r16, t)!,
      r20: lerpDouble(r20, other.r20, t)!,
      r24: lerpDouble(r24, other.r24, t)!,
      r28: lerpDouble(r28, other.r28, t)!,
      r32: lerpDouble(r32, other.r32, t)!,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppRadii &&
          other.r4 == r4 &&
          other.r8 == r8 &&
          other.r12 == r12 &&
          other.r16 == r16 &&
          other.r20 == r20 &&
          other.r24 == r24 &&
          other.r28 == r28 &&
          other.r32 == r32;

  @override
  int get hashCode => Object.hash(r4, r8, r12, r16, r20, r24, r28, r32);
}
