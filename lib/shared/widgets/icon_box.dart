import 'package:flutter/material.dart';

class IconBox extends StatelessWidget {
  const IconBox({
    super.key,
    required this.icon,
    required this.color,
    this.size = 36,
    this.iconSize = 18,
    this.radius = 10,
    this.alpha = 0.12,
  });

  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;
  final double radius;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: alpha),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(icon, size: iconSize, color: color),
    );
  }
}
