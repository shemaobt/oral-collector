import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'pressable.dart';

class AppLink extends StatelessWidget {
  const AppLink({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final base = Theme.of(context).textTheme.labelLarge?.copyWith(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.underline,
      decorationThickness: 1.5,
    );
    return TextButton(
      onPressed: onPressed,
      style:
          TextButton.styleFrom(
            foregroundColor: c.foreground,
            disabledForegroundColor: c.secondary,
            minimumSize: const Size(0, 44),
            overlayColor: AppColors.transparent,
            backgroundBuilder: pressLookBackground,
          ).copyWith(
            textStyle: WidgetStateProperty.resolveWith(
              (states) => base?.copyWith(
                decorationColor: states.contains(WidgetState.disabled)
                    ? c.secondary
                    : c.foreground,
              ),
            ),
          ),
      child: Text(label),
    );
  }
}
