import 'package:flutter/material.dart';

/// Categorical (index-addressed) decorative palettes for cards and waveforms.
///
/// These are non-semantic accent colors picked by list position (`index %
/// length`), not by a `ColorScheme` role, so they live here rather than in
/// `AppColorSet`. Single-theme / value-identical (ADR-0002, ENG-116): a raw
/// `Color(...)` is allowed only under `lib/core/theme/`.
abstract class AppPalettes {
  static const List<Color> genreAccents = [
    Color(0xFF3D8E80),
    Color(0xFFC25010),
    Color(0xFF5E7A2B),
    Color(0xFF9B7040),
    Color(0xFF4A7FA3),
    Color(0xFFD06835),
    Color(0xFF4E8A4A),
    Color(0xFF8B5E9B),
  ];

  static const List<Color> projectAccents = [
    Color(0xFFD45200),
    Color(0xFF1A8A78),
    Color(0xFF477A12),
    Color(0xFF8B5CF6),
    Color(0xFFE0A526),
    Color(0xFF2563EB),
  ];

  /// Accent for a genre card at [index], cycling through [genreAccents].
  static Color genreAccent(int index) =>
      genreAccents[index % genreAccents.length];

  /// Accent for a project card at [index], cycling through [projectAccents].
  static Color projectAccent(int index) =>
      projectAccents[index % projectAccents.length];

  /// Hero genre card accent (matches `genreAccents[0]`).
  static const Color heroGenreAccent = Color(0xFF3D8E80);

  /// Default scrolling-waveform cursor (matches `projectAccents[0]`).
  static const Color waveformCursorDefault = Color(0xFFD45200);
}
