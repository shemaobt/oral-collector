import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/genre_colors.dart';

enum DiscSize {
  small(36),
  medium(44),
  large(56);

  const DiscSize(this.diameter);

  final double diameter;
}

enum DiscTone { inset, ink, g1, g2, g3, g4, none }

class AppDisc extends StatelessWidget {
  const AppDisc({
    super.key,
    required this.child,
    this.size = DiscSize.medium,
    this.tone = DiscTone.inset,
  });

  final Widget child;
  final DiscSize size;
  final DiscTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final genres = GenreColors.of(context).tones;
    final (fill, foreground) = switch (tone) {
      DiscTone.inset => (colors.surfaceAlt, colors.primary),
      DiscTone.ink => (colors.primary, colors.background),
      DiscTone.g1 => (genres[0].disc, genres[0].onDisc),
      DiscTone.g2 => (genres[1].disc, genres[1].onDisc),
      DiscTone.g3 => (genres[2].disc, genres[2].onDisc),
      DiscTone.g4 => (genres[3].disc, genres[3].onDisc),
      DiscTone.none => (Colors.transparent, colors.secondary),
    };
    return Container(
      width: size.diameter,
      height: size.diameter,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fill,
        border: tone == DiscTone.none
            ? Border.all(color: colors.border, width: 1.8)
            : null,
      ),
      child: IconTheme.merge(
        data: IconThemeData(color: foreground),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: foreground),
          child: child,
        ),
      ),
    );
  }
}
