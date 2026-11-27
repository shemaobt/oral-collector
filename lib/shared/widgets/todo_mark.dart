import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

const double _circle = 13;
const double _stroke = 1.5;
const double _gap = 6;
const int _dashes = 8;
const double _dashShare = 0.55;

class TodoMark extends StatelessWidget {
  const TodoMark({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final ink = AppColors.of(context).foreground;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: CustomPaint(
            size: const Size.square(_circle),
            painter: _DashedCirclePainter(ink),
          ),
        ),
        const SizedBox(width: _gap),
        Flexible(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: ink,
            ),
          ),
        ),
      ],
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  const _DashedCirclePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(_stroke / 2);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke;
    const step = 2 * pi / _dashes;
    for (var i = 0; i < _dashes; i++) {
      canvas.drawArc(rect, i * step, step * _dashShare, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter old) => old.color != color;
}
