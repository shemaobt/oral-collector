import 'package:flutter/material.dart';
import '../../../../core/theme/tokens.dart';

class MiniStatBadge extends StatelessWidget {
  const MiniStatBadge({
    super.key,
    required this.icon,
    required this.text,
    required this.color,
    required this.isDark,
    required this.bgBase,
  });

  final IconData icon;
  final String text;
  final Color color;
  final bool isDark;
  final Color bgBase;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingScale.s8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: bgBase.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(RadiusScale.r8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
