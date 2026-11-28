import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'pressable.dart';

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
        disabledForegroundColor: c.secondary,
        minimumSize: const Size(0, 52),
        backgroundBuilder: pressLookBackground,
        textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      child: Text(label),
    );
  }
}
