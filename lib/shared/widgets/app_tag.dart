import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

enum AppTagSize {
  pill(30, 15),
  chip(22, 11),
  caps(0, 7);

  const AppTagSize(this.height, this.radius);

  final double height;
  final double radius;
}

enum AppTagTone { telha, wood, plain, error, bridge, ink }

class AppTag extends StatelessWidget {
  const AppTag({
    super.key,
    required this.label,
    this.size = AppTagSize.pill,
    this.tone = AppTagTone.telha,
    this.icon,
  });

  final String label;
  final AppTagSize size;
  final AppTagTone tone;
  final IconData? icon;

  (Color, Color) _pair(AppColorSet colors) => switch (tone) {
    AppTagTone.telha => (colors.soft, colors.deep),
    AppTagTone.wood => (colors.woodSoft, colors.woodText),
    AppTagTone.plain => (colors.surfaceAlt, colors.secondary),
    AppTagTone.error => (colors.brickSoft, colors.error),
    AppTagTone.bridge => (colors.bridgeSoft, colors.info),
    AppTagTone.ink => (colors.slab, colors.onPrimary),
  };

  EdgeInsetsGeometry get _padding => switch (size) {
    AppTagSize.pill => const EdgeInsetsDirectional.fromSTEB(
      SpacingScale.s12,
      0,
      SpacingScale.s12,
      0,
    ),
    AppTagSize.chip => const EdgeInsets.symmetric(horizontal: SpacingScale.s8),
    AppTagSize.caps => const EdgeInsets.symmetric(
      horizontal: SpacingScale.s8,
      vertical: SpacingScale.s4,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final (fill, ink) = _pair(AppColors.of(context));
    final text = Theme.of(context).textTheme;
    final isCaps = size == AppTagSize.caps;
    final style = (size == AppTagSize.pill ? text.labelMedium : text.labelSmall)
        ?.copyWith(color: ink, letterSpacing: isCaps ? 0.9 : null);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(size.radius),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: size.height),
        child: Padding(
          padding: _padding,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: ink),
                const SizedBox(width: SpacingScale.s4),
              ],
              Flexible(
                child: Text(isCaps ? label.toUpperCase() : label, style: style),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
