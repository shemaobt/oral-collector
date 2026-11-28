import 'package:flutter/material.dart';

import 'app_motion.dart';
import 'app_opacity.dart';
import 'app_radii.dart';
import 'app_spacing.dart';

/// Ergonomic token accessors: `context.spacing.s16`, `context.radii.r12`,
/// `context.motion.base`.
///
/// Each falls back to the const scale default when the extension is not
/// registered (e.g. tests that pump a bare `MaterialApp`).
extension TokenContext on BuildContext {
  AppSpacing get spacing =>
      Theme.of(this).extension<AppSpacing>() ?? AppSpacing.fallback;

  AppRadii get radii =>
      Theme.of(this).extension<AppRadii>() ?? AppRadii.fallback;

  AppMotion get motion {
    final AppMotion set =
        Theme.of(this).extension<AppMotion>() ?? AppMotion.fallback;
    return MediaQuery.maybeDisableAnimationsOf(this) ?? false
        ? set.copyWith(
            fast: Duration.zero,
            base: Duration.zero,
            slow: Duration.zero,
            pressIn: Duration.zero,
            pressOut: Duration.zero,
            stagger: Duration.zero,
            still: true,
          )
        : set;
  }

  AppOpacity get opacity =>
      Theme.of(this).extension<AppOpacity>() ?? AppOpacity.fallback;
}
