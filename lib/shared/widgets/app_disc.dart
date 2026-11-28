import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/genre_colors.dart';
import 'hand_cut_disc.dart';
import 'printed_shadow_scope.dart';

enum DiscSize {
  small(32),
  medium(44),
  large(56),
  big(68),
  empty(88),
  huge(96);

  const DiscSize(this.diameter);

  final double diameter;
}

enum DiscTone {
  resting,
  onCard,
  action,
  record,
  live,
  working,
  failed,
  g1,
  g2,
  g3,
  g4,
}

class AppDisc extends StatelessWidget {
  const AppDisc({
    super.key,
    required this.child,
    this.size = DiscSize.medium,
    this.tone = DiscTone.resting,
    this.pressable = false,
    this.enabled = true,
  });

  final Widget child;
  final DiscSize size;
  final DiscTone tone;
  final bool pressable;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final genres = GenreColors.of(context).tones;
    final shadows = PrintedShadows.of(context);
    final (fill, sign, shadow) = switch (tone) {
      DiscTone.resting => (colors.card, colors.foreground, shadows.paper),
      DiscTone.onCard => (colors.pale, colors.foreground, shadows.paper),
      DiscTone.action => (colors.primary, colors.card, shadows.ink),
      DiscTone.record => (colors.mic, colors.onColor, shadows.brick),
      DiscTone.live => (colors.accent, colors.onColor, shadows.tile),
      DiscTone.working => (colors.clay, colors.foreground, shadows.clay),
      DiscTone.failed => (colors.soft, colors.onSoft, shadows.terracotta),
      DiscTone.g1 => (genres[0].disc, genres[0].onDisc, shadows.paper),
      DiscTone.g2 => (genres[1].disc, genres[1].onDisc, shadows.paper),
      DiscTone.g3 => (genres[2].disc, genres[2].onDisc, shadows.paper),
      DiscTone.g4 => (genres[3].disc, genres[3].onDisc, shadows.paper),
    };
    final printed = pressable && enabled && !PrintedShadowScope.paints(context);
    final disc = SizedBox.square(
      dimension: size.diameter,
      child: CustomPaint(
        painter: HandCutDiscPainter(
          fill: fill,
          shadow: printed ? shadow : null,
        ),
        child: Center(
          child: IconTheme.merge(
            data: IconThemeData(color: sign, size: size.diameter * 0.46),
            child: DefaultTextStyle.merge(
              style: TextStyle(color: sign),
              child: child,
            ),
          ),
        ),
      ),
    );
    final piece = printed ? PrintedShadowScope(child: disc) : disc;
    return enabled ? piece : Opacity(opacity: 0.4, child: piece);
  }
}
