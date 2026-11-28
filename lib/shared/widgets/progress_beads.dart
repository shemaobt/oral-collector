import 'package:flutter/widgets.dart';

import '../../core/theme/app_colors.dart';
import 'hand_cut_disc.dart';

const int _count = 10;
const double _pitch = 14;
const double _bead = 10;

class ProgressBeads extends StatelessWidget {
  const ProgressBeads({super.key, required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return ExcludeSemantics(
      child: CustomPaint(
        size: const Size(_count * _pitch, _bead),
        painter: _BeadsPainter(
          lit: (percent ~/ 10).clamp(0, _count),
          litColor: colors.accent,
          paleColor: colors.pale,
          rtl: Directionality.of(context) == TextDirection.rtl,
        ),
      ),
    );
  }
}

class _BeadsPainter extends CustomPainter {
  const _BeadsPainter({
    required this.lit,
    required this.litColor,
    required this.paleColor,
    required this.rtl,
  });

  final int lit;
  final Color litColor;
  final Color paleColor;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < _count; i++) {
      final slot = rtl ? _count - 1 - i : i;
      canvas.save();
      canvas.translate(slot * _pitch + (rtl ? _pitch - _bead : 0), 0);
      HandCutDiscPainter(
        fill: i < lit ? litColor : paleColor,
      ).paint(canvas, const Size(_bead, _bead));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_BeadsPainter old) =>
      old.lit != lit ||
      old.litColor != litColor ||
      old.paleColor != paleColor ||
      old.rtl != rtl;
}
