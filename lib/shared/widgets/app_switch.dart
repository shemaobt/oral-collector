import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import 'hand_cut_disc.dart';
import 'hand_cut_rect.dart';
import 'printed_shadow_scope.dart';

const double _width = 52;
const double _height = 30;
const double _radius = 15;
const double _knob = 24;
const double _inset = 3;
const Offset _shadowOffset = Offset(2, 3);

class AppSwitch extends StatelessWidget {
  const AppSwitch({super.key, required this.on, required this.onChanged});

  final bool on;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final shadows = PrintedShadows.of(context);
    final enabled = onChanged != null;
    final printed = enabled && !PrintedShadowScope.paints(context);
    final track = CustomPaint(
      size: const Size(_width, _height),
      painter: HandCutRectPainter(
        fill: on ? colors.primary : colors.pale,
        radius: _radius,
        shadow: printed ? (on ? shadows.ink : shadows.paper) : null,
        shadowOffset: _shadowOffset,
      ),
      child: Stack(
        children: [
          PositionedDirectional(
            top: _inset,
            start: on ? null : _inset,
            end: on ? _inset : null,
            child: CustomPaint(
              size: const Size.square(_knob),
              painter: HandCutDiscPainter(fill: on ? colors.card : colors.knob),
            ),
          ),
        ],
      ),
    );
    return Semantics(
      toggled: on,
      enabled: enabled,
      onTap: enabled ? () => onChanged!(!on) : null,
      excludeSemantics: true,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: GestureDetector(
          onTap: enabled ? () => onChanged!(!on) : null,
          child: SizedBox(width: _width, height: _height, child: track),
        ),
      ),
    );
  }
}
