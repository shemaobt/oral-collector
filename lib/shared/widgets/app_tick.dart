import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_opacity.dart';
import '../../core/theme/app_shadows.dart';
import 'brush_sign.dart';
import 'hand_cut_rect.dart';
import 'printed_shadow_scope.dart';

const double _size = 26;
const double _radius = 6;
const double _signSize = 16;
const double _minHeight = 44;
const double _gap = 12;

class AppTick extends StatelessWidget {
  const AppTick({
    super.key,
    required this.marked,
    required this.onChanged,
    this.label,
  });

  final bool marked;
  final ValueChanged<bool>? onChanged;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final shadows = PrintedShadows.of(context);
    final enabled = onChanged != null;
    final printed = enabled && !PrintedShadowScope.paints(context);
    final shadow = marked ? shadows.ink : shadows.paper;
    final box = SizedBox.square(
      dimension: _size,
      child: CustomPaint(
        painter: HandCutRectPainter(
          fill: marked ? colors.primary : colors.card,
          radius: _radius,
          shadow: printed ? shadow : null,
          shadowOffset: markShadowOffset,
        ),
        child: marked
            ? Center(
                child: BrushSign(
                  Sign.check,
                  size: _signSize,
                  color: colors.card,
                ),
              )
            : null,
      ),
    );
    final text = label;
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _minHeight),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: _gap,
        children: [
          box,
          if (text != null)
            Expanded(
              child: Text(
                text,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: colors.foreground),
              ),
            ),
        ],
      ),
    );
    return Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: 1,
      heightFactor: 1,
      child: Semantics(
        checked: marked,
        enabled: enabled,
        label: text,
        onTap: enabled ? () => onChanged!(!marked) : null,
        excludeSemantics: true,
        child: Opacity(
          opacity: enabled ? 1 : OpacityScale.o40,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: enabled ? () => onChanged!(!marked) : null,
              child: row,
            ),
          ),
        ),
      ),
    );
  }
}
