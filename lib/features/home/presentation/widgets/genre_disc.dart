import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/genre_colors.dart';

class GenreDisc extends StatelessWidget {
  const GenreDisc({
    super.key,
    required this.tone,
    required this.icon,
    required this.size,
    required this.iconSize,
  });

  final GenreTone? tone;
  final IconData icon;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final tone = this.tone;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: tone?.disc ?? AppColors.transparent,
        border: tone == null
            ? Border.all(color: colors.border, width: 1.8)
            : null,
      ),
      child: Icon(
        icon,
        size: iconSize,
        color: tone?.onDisc ?? colors.secondary,
      ),
    );
  }
}

BoxDecoration genreCardDecoration(
  AppColorSet colors,
  GenreTone? tone,
  double radius,
) => BoxDecoration(
  color: tone?.soft ?? colors.card,
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(
    color: tone == null
        ? colors.border
        : tone.disc.withValues(alpha: tone.ringAlpha),
    width: 1.5,
  ),
);
