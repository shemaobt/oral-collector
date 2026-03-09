import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';

/// Badge showing the upload status of a recording.
///
/// States:
/// - `local`     → gray dot, "Not synced"
/// - `pending`   → areia dot, "Pending"  (alias used by callers; internally same as local)
/// - `uploading` → animated telha, "Uploading..."
/// - `uploaded`  → verde-claro check, "Uploaded"
/// - `failed`    → red dot, "Failed" + optional Retry link
class UploadStatusBadge extends StatefulWidget {
  const UploadStatusBadge({
    super.key,
    required this.status,
    this.onRetry,
    this.compact = false,
  });

  /// Upload status string: 'local', 'pending', 'uploading', 'uploaded', 'failed'.
  final String status;

  /// Optional callback for the retry action on failed uploads.
  final VoidCallback? onRetry;

  /// When true, uses smaller font/icon sizes (for list cards).
  final bool compact;

  @override
  State<UploadStatusBadge> createState() => _UploadStatusBadgeState();
}

class _UploadStatusBadgeState extends State<UploadStatusBadge>
    with SingleTickerProviderStateMixin {
  AnimationController? _animController;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
  }

  @override
  void didUpdateWidget(UploadStatusBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) {
      _setupAnimation();
    }
  }

  void _setupAnimation() {
    if (widget.status == 'uploading') {
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
    final iconSize = widget.compact ? 12.0 : 14.0;
    final fontSize = widget.compact ? 11.0 : 13.0;
    final hPad = widget.compact ? 6.0 : 8.0;
    final vPad = widget.compact ? 2.0 : 3.0;

    final IconData icon;
    final Color color;
    final String label;

    switch (widget.status) {
      case 'uploaded':
        icon = LucideIcons.checkCircle;
        color = AppColors.success;
        label = 'Uploaded';
        break;
      case 'uploading':
        icon = LucideIcons.upload;
        color = AppColors.primary; // telha
        label = 'Uploading...';
        break;
      case 'failed':
        icon = LucideIcons.cloudOff;
        color = AppColors.error;
        label = 'Failed';
        break;
      case 'pending':
        icon = LucideIcons.clock;
        color = AppColors.border; // areia
        label = 'Pending';
        break;
      default: // 'local'
        icon = LucideIcons.smartphone;
        color = Colors.grey;
        label = 'Not synced';
    }

    Widget iconWidget = Icon(icon, size: iconSize, color: color);

    // Animate the icon when uploading
    if (widget.status == 'uploading' && _animController != null) {
      iconWidget = RotationTransition(
        turns: _animController!,
        child: Icon(LucideIcons.refreshCw, size: iconSize, color: color),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
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
        ),
        if (widget.status == 'failed' && widget.onRetry != null) ...[
          const SizedBox(width: 6),
          GestureDetector(
            onTap: widget.onRetry,
            child: Text(
              'Retry',
              style: TextStyle(
                fontSize: fontSize,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.primary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
