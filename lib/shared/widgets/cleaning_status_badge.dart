import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';

class CleaningStatusBadge extends StatefulWidget {
  const CleaningStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  final String status;
  final bool compact;

  @override
  State<CleaningStatusBadge> createState() => _CleaningStatusBadgeState();
}

class _CleaningStatusBadgeState extends State<CleaningStatusBadge>
    with SingleTickerProviderStateMixin {
  AnimationController? _animController;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
  }

  @override
  void didUpdateWidget(CleaningStatusBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) {
      _setupAnimation();
    }
  }

  void _setupAnimation() {
    if (widget.status == 'cleaning') {
      _animController ??= AnimationController(
        vsync: this,
        duration: const Duration(seconds: 1),
      )..repeat();
    } else {
      _animController?.dispose();
      _animController = null;
    }
  }

  @override
  void dispose() {
    _animController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.status == 'none') {
      return const SizedBox.shrink();
    }

    final iconSize = widget.compact ? 12.0 : 14.0;
    final fontSize = widget.compact ? 11.0 : 13.0;
    final hPad = widget.compact ? 6.0 : 8.0;
    final vPad = widget.compact ? 2.0 : 3.0;

    final IconData icon;
    final Color color;
    final String label;

    switch (widget.status) {
      case 'needs_cleaning':
        icon = LucideIcons.alertCircle;
        color = Colors.amber.shade700;
        label = 'Needs Cleaning';
        break;
      case 'cleaning':
        icon = LucideIcons.loader;
        color = AppColors.info;
        label = 'Cleaning...';
        break;
      case 'cleaned':
        icon = LucideIcons.sparkles;
        color = AppColors.success;
        label = 'Cleaned';
        break;
      case 'failed':
        icon = LucideIcons.alertTriangle;
        color = AppColors.error;
        label = 'Clean Failed';
        break;
      default:
        return const SizedBox.shrink();
    }

    Widget iconWidget = Icon(icon, size: iconSize, color: color);

    if (widget.status == 'cleaning' && _animController != null) {
      iconWidget = RotationTransition(
        turns: _animController!,
        child: Icon(LucideIcons.loader, size: iconSize, color: color),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconWidget,
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: fontSize,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
