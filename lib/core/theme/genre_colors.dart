import 'package:flutter/material.dart';

import '../../features/recording/domain/entities/classification.dart';
import 'app_colors.dart';

class GenreTone {
  const GenreTone({
    required this.disc,
    required this.soft,
    required this.onDisc,
    required this.ringAlpha,
  });

  final Color disc;
  final Color soft;
  final Color onDisc;
  final double ringAlpha;

  static GenreTone lerp(GenreTone a, GenreTone b, double t) => GenreTone(
    disc: Color.lerp(a.disc, b.disc, t)!,
    soft: Color.lerp(a.soft, b.soft, t)!,
    onDisc: Color.lerp(a.onDisc, b.onDisc, t)!,
    ringAlpha: a.ringAlpha + (b.ringAlpha - a.ringAlpha) * t,
  );
}

class GenreColors extends ThemeExtension<GenreColors> {
  const GenreColors({required this.tones});

  final List<GenreTone> tones;

  GenreTone? forGenre(int index, String genreId) =>
      genreId == kUnclassifiedGenreId ? null : tones[index % tones.length];

  static GenreColors of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<GenreColors>() ??
        (theme.brightness == Brightness.dark ? dark : light);
  }

  @override
  GenreColors copyWith({List<GenreTone>? tones}) =>
      GenreColors(tones: tones ?? this.tones);

  @override
  GenreColors lerp(covariant ThemeExtension<GenreColors>? other, double t) {
    if (other is! GenreColors) return this;
    return GenreColors(
      tones: [
        for (var i = 0; i < tones.length; i++)
          GenreTone.lerp(tones[i], other.tones[i], t),
      ],
    );
  }

  static const light = GenreColors(
    tones: [
      GenreTone(
        disc: Color(0xFFC9A26B),
        soft: Color(0xFFF6EAD3),
        onDisc: AppColors.foreground,
        ringAlpha: 0.45,
      ),
      GenreTone(
        disc: Color(0xFF89AAA3),
        soft: Color(0xFFE1ECE8),
        onDisc: AppColors.foreground,
        ringAlpha: 0.55,
      ),
      GenreTone(
        disc: Color(0xFF777D45),
        soft: Color(0xFFECEDD8),
        onDisc: AppColors.background,
        ringAlpha: 0.40,
      ),
      GenreTone(
        disc: Color(0xFF9C5D45),
        soft: Color(0xFFF2E2DA),
        onDisc: AppColors.background,
        ringAlpha: 0.30,
      ),
    ],
  );

  static const dark = GenreColors(
    tones: [
      GenreTone(
        disc: Color(0xFFC9A26B),
        soft: Color(0xFF2A2318),
        onDisc: AppColors.darkBackground,
        ringAlpha: 0.45,
      ),
      GenreTone(
        disc: Color(0xFF89AAA3),
        soft: Color(0xFF1B2624),
        onDisc: AppColors.darkBackground,
        ringAlpha: 0.55,
      ),
      GenreTone(
        disc: Color(0xFF98A05C),
        soft: Color(0xFF232518),
        onDisc: AppColors.darkBackground,
        ringAlpha: 0.40,
      ),
      GenreTone(
        disc: Color(0xFFBD7559),
        soft: Color(0xFF2E1E17),
        onDisc: AppColors.darkBackground,
        ringAlpha: 0.30,
      ),
    ],
  );
}
