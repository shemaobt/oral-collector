import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_shadows.dart';
import 'hand_cut_rect.dart';
import 'pressable.dart';
import 'printed_shadow_scope.dart';

const double _height = 38;
const double _touchHeight = 44;
const double _padding = 14;

class AppFilterChoice extends StatelessWidget {
  const AppFilterChoice({
    super.key,
    required this.label,
    required this.chosen,
    required this.onTap,
  });

  final String label;
  final bool chosen;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final shadows = PrintedShadows.of(context);
    final piece = PrintedShadowScope(
      child: CustomPaint(
        painter: HandCutRectPainter(
          fill: chosen ? colors.primary : colors.card,
          radius: RadiusScale.r12,
          shadow: chosen ? shadows.ink : shadows.paper,
          shadowOffset: markShadowOffset,
        ),
        child: Container(
          height: _height,
          padding: const EdgeInsets.symmetric(horizontal: _padding),
          alignment: Alignment.center,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 15,
              fontWeight: chosen ? FontWeight.w600 : FontWeight.w500,
              color: chosen ? colors.card : colors.foreground,
            ),
          ),
        ),
      ),
    );
    return Semantics(
      button: true,
      selected: chosen,
      enabled: onTap != null,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: Align(
        widthFactor: 1,
        heightFactor: 1,
        child: Pressable(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: _touchHeight),
            child: Center(widthFactor: 1, child: piece),
          ),
        ),
      ),
    );
  }
}
