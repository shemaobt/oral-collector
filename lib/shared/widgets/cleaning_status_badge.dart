import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';

/// Badge showing the cleaning status of a recording.
///
/// States:
/// - `none`            → hidden (returns SizedBox.shrink)
/// - `needs_cleaning`  → yellow/amber badge, "Needs Cleaning"
/// - `cleaning`        → animated spinner, "Cleaning..."
/// - `cleaned`         → green badge, "Cleaned"
/// - `failed`          → red badge, "Clean Failed"
class CleaningStatusBadge extends StatefulWidget {
  const CleaningStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  /// Cleaning status string: 'none', 'needs_cleaning', 'cleaning', 'cleaned', 'failed'.
  final String status;

  /// When true, uses smaller font/icon sizes (for list cards).
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
    // Hidden when status is 'none'
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

    // Animate the icon when cleaning is in progress
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
            style: TextStyle(
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
