import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Parses a `#RRGGBB` / `RRGGBB` hex string into an opaque [Color], returning
/// [fallback] when null or malformed. Lives in the theme layer because raw
/// `Color` construction is allowed only here (ADR-0002/0007); the input is
/// runtime data (e.g. a genre's color), not a hardcoded literal.
Color parseHexColor(String? hex, [Color fallback = AppColors.primary]) {
  if (hex == null || hex.length < 7) return fallback;
  try {
    final hexValue = hex.replaceFirst('#', '');
    return Color(int.parse('FF$hexValue', radix: 16));
  } catch (_) {
    return fallback;
  }
}
