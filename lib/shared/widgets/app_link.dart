import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

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
        disabledForegroundColor: c.secondary,
        minimumSize: const Size(0, 44),
        textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          decoration: TextDecoration.underline,
          decorationThickness: 1.5,
        ),
      ),
      child: Text(label),
    );
  }
}
