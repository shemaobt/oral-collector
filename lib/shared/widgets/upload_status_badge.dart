import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

class UploadStatusBadge extends StatefulWidget {
  const UploadStatusBadge({
    super.key,
    required this.status,
    this.onRetry,
    this.compact = false,
  });

  final String status;
  final VoidCallback? onRetry;
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
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
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
        color = colors.success;
        label = l10n.recording_statusUploaded;
        break;
      case 'uploading':
        icon = LucideIcons.upload;
        color = colors.accent;
        label = l10n.recording_statusUploading;
        break;
      case 'failed':
        icon = LucideIcons.cloudOff;
        color = colors.error;
        label = l10n.recording_statusFailed;
        break;
      case 'pending':
        icon = LucideIcons.clock;
        color = colors.border;
        label = l10n.filter_pending;
        break;
      default:
        icon = LucideIcons.smartphone;
        color = colors.border;
        label = l10n.detail_notSynced;
    }

    Widget iconWidget = Icon(icon, size: iconSize, color: color);

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
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: fontSize,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (widget.status == 'failed' && widget.onRetry != null) ...[
          const SizedBox(width: 4),
          TextButton(
            onPressed: widget.onRetry,
            style: TextButton.styleFrom(
              minimumSize: const Size(44, 36),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              l10n.common_retry,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: fontSize,
                color: colors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
