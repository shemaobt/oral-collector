import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class IconBox extends StatelessWidget {
  const IconBox({super.key, required this.icon, this.color});

  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      child: Icon(
        icon,
        size: 24,
        color: color ?? AppColors.of(context).foreground,
      ),
    );
  }
}
