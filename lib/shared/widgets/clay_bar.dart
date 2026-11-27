import 'package:flutter/widgets.dart';

import '../../core/theme/app_colors.dart';
import 'hand_cut_rect.dart';

const double _height = 14;
const double _radius = 4;
const double _opacity = 0.4;

class ClayBar extends StatelessWidget {
  const ClayBar({super.key, this.width, this.height = _height});

  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final clay = AppColors.of(context).clay;
    return ExcludeSemantics(
      child: SizedBox(
        width: width ?? double.infinity,
        height: height,
        child: CustomPaint(
          painter: HandCutRectPainter(
            fill: clay.withValues(alpha: _opacity),
            radius: _radius,
          ),
        ),
      ),
    );
  }
}
