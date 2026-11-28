import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import 'brush_sign.dart';
import 'hand_cut_rect.dart';
import 'pressable.dart';

const double _height = 36;
const double _touchHeight = 44;
const double _radius = 10;
const double _gap = 6;

class AppActiveFilter extends StatelessWidget {
  const AppActiveFilter({
    super.key,
    required this.name,
    required this.onRemove,
  });

  final String name;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final piece = CustomPaint(
      painter: HandCutRectPainter(fill: colors.primary, radius: _radius),
      child: Container(
        height: _height,
        padding: const EdgeInsetsDirectional.only(start: 12, end: 8),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: _gap,
          children: [
            Flexible(
              child: Text(
                name,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colors.card,
                ),
              ),
            ),
            BrushSign(Sign.plus, size: 14, color: colors.card, turns: 0.125),
          ],
        ),
      ),
    );
    return Semantics(
      button: true,
      label: AppLocalizations.of(context).filters_removeFilter(name),
      excludeSemantics: true,
      onTap: onRemove,
      child: Align(
        widthFactor: 1,
        heightFactor: 1,
        child: Pressable(
          onTap: onRemove,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: _touchHeight),
            child: Center(widthFactor: 1, child: piece),
          ),
        ),
      ),
    );
  }
}
