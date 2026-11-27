import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart' show lerpDuration;
import 'package:flutter/material.dart';

/// The app's motion set — the single source of truth. A value one moment needs
/// on its own is a constant added here, never a field of [AppMotion].
abstract final class MotionScale {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration base = Duration(milliseconds: 320);
  static const Duration slow = Duration(milliseconds: 450);
  static const Curve enter = Cubic(.05, .7, .1, 1);
  static const Curve leave = Cubic(.3, 0, .8, .15);
  static const double rise = 24;
  static const double slide = 40;
  static const double pressScale = 0.95;
  static const Duration pressIn = Duration(milliseconds: 120);
  static const Duration pressOut = Duration(milliseconds: 320);
  static const Curve pressBack = Cubic(.2, 1.9, .4, 1);
  static const Duration stagger = Duration(milliseconds: 70);
  static const Curve loop = Curves.easeInOut;
  static const Duration checkWait = Duration(milliseconds: 250);
  static const Duration checkRun = Duration(milliseconds: 1100);
}

/// Theme-scoped motion tokens. Read via `context.motion`, which zeroes the six
/// times and sets [still] when the person asks for less motion.
class AppMotion extends ThemeExtension<AppMotion> {
  const AppMotion({
    this.fast = MotionScale.fast,
    this.base = MotionScale.base,
    this.slow = MotionScale.slow,
    this.enter = MotionScale.enter,
    this.leave = MotionScale.leave,
    this.rise = MotionScale.rise,
    this.slide = MotionScale.slide,
    this.pressScale = MotionScale.pressScale,
    this.pressIn = MotionScale.pressIn,
    this.pressOut = MotionScale.pressOut,
    this.pressBack = MotionScale.pressBack,
    this.stagger = MotionScale.stagger,
    this.still = false,
  });

  final Duration fast;
  final Duration base;
  final Duration slow;
  final Curve enter;
  final Curve leave;
  final double rise;
  final double slide;
  final double pressScale;
  final Duration pressIn;
  final Duration pressOut;
  final Curve pressBack;
  final Duration stagger;
  final bool still;

  /// Registered value, and the `context.motion` default when unregistered.
  static const AppMotion fallback = AppMotion();

  @override
  AppMotion copyWith({
    Duration? fast,
    Duration? base,
    Duration? slow,
    Curve? enter,
    Curve? leave,
    double? rise,
    double? slide,
    double? pressScale,
    Duration? pressIn,
    Duration? pressOut,
    Curve? pressBack,
    Duration? stagger,
    bool? still,
  }) {
    return AppMotion(
      fast: fast ?? this.fast,
      base: base ?? this.base,
      slow: slow ?? this.slow,
      enter: enter ?? this.enter,
      leave: leave ?? this.leave,
      rise: rise ?? this.rise,
      slide: slide ?? this.slide,
      pressScale: pressScale ?? this.pressScale,
      pressIn: pressIn ?? this.pressIn,
      pressOut: pressOut ?? this.pressOut,
      pressBack: pressBack ?? this.pressBack,
      stagger: stagger ?? this.stagger,
      still: still ?? this.still,
    );
  }

  /// Curves and flags cannot blend: this set's below the middle, the other's
  /// from the middle on.
  @override
  AppMotion lerp(AppMotion? other, double t) {
    if (other is! AppMotion) return this;
    final AppMotion curves = t < 0.5 ? this : other;
    return AppMotion(
      fast: lerpDuration(fast, other.fast, t),
      base: lerpDuration(base, other.base, t),
      slow: lerpDuration(slow, other.slow, t),
      enter: curves.enter,
      leave: curves.leave,
      rise: lerpDouble(rise, other.rise, t)!,
      slide: lerpDouble(slide, other.slide, t)!,
      pressScale: lerpDouble(pressScale, other.pressScale, t)!,
      pressIn: lerpDuration(pressIn, other.pressIn, t),
      pressOut: lerpDuration(pressOut, other.pressOut, t),
      pressBack: curves.pressBack,
      stagger: lerpDuration(stagger, other.stagger, t),
      still: curves.still,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppMotion &&
          other.fast == fast &&
          other.base == base &&
          other.slow == slow &&
          other.enter == enter &&
          other.leave == leave &&
          other.rise == rise &&
          other.slide == slide &&
          other.pressScale == pressScale &&
          other.pressIn == pressIn &&
          other.pressOut == pressOut &&
          other.pressBack == pressBack &&
          other.stagger == stagger &&
          other.still == still;

  @override
  int get hashCode => Object.hash(
    fast,
    base,
    slow,
    enter,
    leave,
    rise,
    slide,
    pressScale,
    pressIn,
    pressOut,
    pressBack,
    stagger,
    still,
  );
}
