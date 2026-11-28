import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'brush_sign.dart';

class AppWordButton extends StatelessWidget {
  const AppWordButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: c.error,
        minimumSize: const Size(0, 52),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      ),
      child: Text(label),
    );
  }
}

class AppLink extends StatelessWidget {
  const AppLink({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: c.foreground,
        minimumSize: const Size(0, 44),
        textStyle: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          decoration: TextDecoration.underline,
          decorationThickness: 1.5,
          decorationColor: c.foreground,
        ),
      ),
      child: Text(label),
    );
  }
}

class AppSignButton extends StatelessWidget {
  const AppSignButton({
    super.key,
    required this.sign,
    required this.semanticLabel,
    required this.onPressed,
    this.color,
  });

  final Sign sign;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: semanticLabel,
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
              color: onPressed == null ? c.secondary : color ?? c.foreground,
            ),
          ),
        ),
      ),
    );
  }
}
