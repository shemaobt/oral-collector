import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import 'brush_sign.dart';
import 'hand_cut_rect.dart';
import 'printed_shadow_scope.dart';

const double _minHeight = 56;
const double _padX = 14;
const double _padY = 8;
const double _radius = 14;
const double _gap = 12;
const double _lineGap = 2;
const double _checkSize = 18;

class AppOption extends StatelessWidget {
  const AppOption({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.explanation,
  });

  final String title;
  final String? explanation;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final shadows = PrintedShadows.of(context);
    final text = Theme.of(context).textTheme;
    final fill = selected ? colors.primary : colors.card;
    final shadow = selected ? shadows.ink : shadows.paper;
    final titleColor = selected ? colors.card : colors.foreground;
    final explanationColor = selected
        ? colors.card.withValues(alpha: 0.8)
        : colors.secondary;
    final line = explanation;

    return Semantics(
      checked: selected,
      inMutuallyExclusiveGroup: true,
      onTap: onTap,
      excludeSemantics: true,
      label: line == null ? title : '$title. $line',
      child: PrintedShadowScope(
        child: CustomPaint(
          painter: HandCutRectPainter(
            fill: fill,
            radius: _radius,
            shadow: shadow,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(_radius),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: _minHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: _padX,
                    vertical: _padY,
                  ),
                  child: Row(
                    spacing: _gap,
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: _lineGap,
                          children: [
                            Text(
                              title,
                              style: text.bodyLarge?.copyWith(
                                fontSize: 17,
                                height: 1.25,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: titleColor,
                              ),
                            ),
                            if (line != null)
                              Text(
                                line,
                                style: text.bodySmall?.copyWith(
                                  color: explanationColor,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (selected)
                        BrushSign(
                          Sign.check,
                          size: _checkSize,
                          color: colors.card,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
