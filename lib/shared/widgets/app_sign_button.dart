import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'brush_sign.dart';

class AppSignButton extends StatelessWidget {
  const AppSignButton({
    super.key,
    required this.sign,
    required this.semanticLabel,
    required this.onPressed,
  });

  final Sign sign;
  final String semanticLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: semanticLabel,
      onTap: onPressed,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onPressed,
        radius: 22,
        child: SizedBox.square(
          dimension: 44,
          child: Center(
            child: BrushSign(
              sign,
              size: 24,
              color: onPressed == null ? c.secondary : c.foreground,
            ),
          ),
        ),
      ),
    );
  }
}
