import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';

class SlabCard extends StatelessWidget {
  const SlabCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(SpacingScale.s16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final textColor = colors.onPrimary;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(RadiusScale.r24),
      ),
      child: Padding(
        padding: padding,
        child: DefaultTextStyle.merge(
          style: TextStyle(color: textColor),
          child: IconTheme.merge(
            data: IconThemeData(color: textColor),
            child: child,
          ),
        ),
      ),
    );
  }
}
