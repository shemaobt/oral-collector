import 'package:flutter/material.dart';

import 'app_durations.dart';
import 'app_radii.dart';
import 'app_spacing.dart';

/// Ergonomic token accessors: `context.spacing.s16`, `context.radii.r12`,
/// `context.durations.ms200`.
///
/// Each falls back to the const scale default when the extension is not
/// registered (e.g. tests that pump a bare `MaterialApp`).
extension TokenContext on BuildContext {
  AppSpacing get spacing =>
      Theme.of(this).extension<AppSpacing>() ?? AppSpacing.fallback;

  AppRadii get radii =>
      Theme.of(this).extension<AppRadii>() ?? AppRadii.fallback;

  AppDurations get durations =>
      Theme.of(this).extension<AppDurations>() ?? AppDurations.fallback;
}
