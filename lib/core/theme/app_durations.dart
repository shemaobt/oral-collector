import 'package:flutter/foundation.dart' show lerpDuration;
import 'package:flutter/material.dart';

/// Canonical UI/animation (motion) durations — the single source of truth.
///
/// Only animation/transition timings live here. I/O timeouts, logic timers, and
/// snackbar/feedback display durations are deliberately excluded.
abstract final class DurationScale {
  static const Duration ms120 = Duration(milliseconds: 120);
  static const Duration ms150 = Duration(milliseconds: 150);
  static const Duration ms200 = Duration(milliseconds: 200);
  static const Duration ms250 = Duration(milliseconds: 250);
  static const Duration ms300 = Duration(milliseconds: 300);
  static const Duration ms900 = Duration(milliseconds: 900);
  static const Duration ms1100 = Duration(milliseconds: 1100);
  static const Duration ms1200 = Duration(milliseconds: 1200);
}

/// Theme-scoped motion tokens. Defaults to [DurationScale]; read via
/// `context.durations.ms200`.
class AppDurations extends ThemeExtension<AppDurations> {
  const AppDurations({
    this.ms120 = DurationScale.ms120,
    this.ms150 = DurationScale.ms150,
    this.ms200 = DurationScale.ms200,
    this.ms250 = DurationScale.ms250,
    this.ms300 = DurationScale.ms300,
    this.ms900 = DurationScale.ms900,
    this.ms1100 = DurationScale.ms1100,
    this.ms1200 = DurationScale.ms1200,
  });

  final Duration ms120;
  final Duration ms150;
  final Duration ms200;
  final Duration ms250;
  final Duration ms300;
  final Duration ms900;
  final Duration ms1100;
  final Duration ms1200;

  /// Registered value, and the `context.durations` default when unregistered.
  static const AppDurations fallback = AppDurations();

  @override
  AppDurations copyWith({
    Duration? ms120,
    Duration? ms150,
    Duration? ms200,
    Duration? ms250,
    Duration? ms300,
    Duration? ms900,
    Duration? ms1100,
    Duration? ms1200,
  }) {
    return AppDurations(
      ms120: ms120 ?? this.ms120,
      ms150: ms150 ?? this.ms150,
      ms200: ms200 ?? this.ms200,
      ms250: ms250 ?? this.ms250,
      ms300: ms300 ?? this.ms300,
      ms900: ms900 ?? this.ms900,
      ms1100: ms1100 ?? this.ms1100,
      ms1200: ms1200 ?? this.ms1200,
    );
  }

  @override
  AppDurations lerp(AppDurations? other, double t) {
    if (other is! AppDurations) return this;
    return AppDurations(
      ms120: lerpDuration(ms120, other.ms120, t),
      ms150: lerpDuration(ms150, other.ms150, t),
      ms200: lerpDuration(ms200, other.ms200, t),
      ms250: lerpDuration(ms250, other.ms250, t),
      ms300: lerpDuration(ms300, other.ms300, t),
      ms900: lerpDuration(ms900, other.ms900, t),
      ms1100: lerpDuration(ms1100, other.ms1100, t),
      ms1200: lerpDuration(ms1200, other.ms1200, t),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppDurations &&
          other.ms120 == ms120 &&
          other.ms150 == ms150 &&
          other.ms200 == ms200 &&
          other.ms250 == ms250 &&
          other.ms300 == ms300 &&
          other.ms900 == ms900 &&
          other.ms1100 == ms1100 &&
          other.ms1200 == ms1200;

  @override
  int get hashCode =>
      Object.hash(ms120, ms150, ms200, ms250, ms300, ms900, ms1100, ms1200);
}
