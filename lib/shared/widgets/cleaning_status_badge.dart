import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../utils/cleaning_status_style.dart';

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

    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);
    final style = CleaningStatusStyle.forStatus(widget.status, colors, l10n);
    if (!style.isFlagged) {
      return const SizedBox.shrink();
    }

    final iconSize = widget.compact ? 12.0 : 14.0;
    // `null` keeps labelSmall's native 11 (== the old compact size); only the
    // off-token 13 stays as an explicit override (ENG-114 convention).
    final double? fontSize = widget.compact ? null : 13.0;
    final hPad = widget.compact ? 6.0 : 8.0;
    final vPad = widget.compact ? 2.0 : 3.0;

    final icon = style.icon;
    final color = style.color;
    final label = style.label;

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
          const SizedBox(width: SpacingScale.s4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: fontSize,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
