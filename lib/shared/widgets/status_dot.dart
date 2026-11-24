import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum StatusDotKind { ok, stopped, now }

class StatusDot extends StatelessWidget {
  const StatusDot({super.key, required this.kind});

  static const double size = 9;

  final StatusDotKind kind;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final color = switch (kind) {
      StatusDotKind.ok => colors.success,
      StatusDotKind.stopped => colors.error,
      StatusDotKind.now => colors.accent,
    };
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
