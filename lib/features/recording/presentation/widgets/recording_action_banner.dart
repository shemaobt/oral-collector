import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';

/// A warning/error banner with a message and a tonal action button, used for
/// the detail screen's unclassified-prompt and secondary-collision banners.
/// Extracted from recording_detail_screen's build() (ENG-194 PR-B); the caller
/// passes the exact palette so the two variants stay byte-identical to before.
class RecordingActionBanner extends StatelessWidget {
  const RecordingActionBanner({
    super.key,
    required this.theme,
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.accentColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.actionBackgroundColor,
    required this.onAction,
  });

  final ThemeData theme;
  final IconData icon;
  final String message;
  final String actionLabel;
  final Color accentColor;
  final Color backgroundColor;
  final Color borderColor;
  final Color actionBackgroundColor;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SpacingScale.s16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(RadiusScale.r12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: accentColor),
          const SizedBox(width: SpacingScale.s8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(color: accentColor),
            ),
          ),
          const SizedBox(width: SpacingScale.s8),
          FilledButton.tonal(
            onPressed: onAction,
            style: FilledButton.styleFrom(
              backgroundColor: actionBackgroundColor,
              foregroundColor: accentColor,
              padding: const EdgeInsets.symmetric(
                horizontal: SpacingScale.s12,
                vertical: SpacingScale.s8,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
