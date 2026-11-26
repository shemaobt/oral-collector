import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';

enum StripeTone { telha, brick, wood }

class AppTile extends StatelessWidget {
  const AppTile({
    super.key,
    required this.child,
    this.stripe,
    this.padding = const EdgeInsets.all(SpacingScale.s16),
    this.radius = RadiusScale.r24,
  });

  static const stripeKey = ValueKey('app-tile-stripe');
  static const double stripeWidth = 4;

  final Widget child;
  final StripeTone? stripe;
  final EdgeInsetsGeometry padding;
  final double radius;

  Color _stripeColor(AppColorSet colors) => switch (stripe!) {
    StripeTone.telha => colors.accent,
    StripeTone.brick => colors.error,
    StripeTone.wood => colors.wood,
  };

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final corners = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: corners,
        border: Border.all(color: colors.border, width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: corners,
        child: Stack(
          children: [
            Padding(padding: padding, child: child),
            if (stripe != null)
              PositionedDirectional(
                start: 0,
                top: 0,
                bottom: 0,
                width: stripeWidth,
                child: ColoredBox(key: stripeKey, color: _stripeColor(colors)),
              ),
          ],
        ),
      ),
    );
  }
}
