import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/utils/format.dart';

class WaveformToolsRow extends StatelessWidget {
  const WaveformToolsRow({
    super.key,
    required this.position,
    required this.canSplitAtPosition,
    required this.onSplitAtPosition,
    required this.isWeb,
    required this.onExcludeRange,
  });

  final Duration position;
  final bool canSplitAtPosition;
  final VoidCallback? onSplitAtPosition;
  final bool isWeb;
  final VoidCallback? onExcludeRange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: colors.accent,
      fontWeight: FontWeight.w700,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final showSplit = canSplitAtPosition && onSplitAtPosition != null;
    final showExclude = !isWeb && onExcludeRange != null;

    Widget tool(IconData icon, String label, VoidCallback onTap) =>
        OutlinedButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.accent,
            minimumSize: const Size(0, 36),
            padding: const EdgeInsets.symmetric(horizontal: SpacingScale.s8),
            side: BorderSide(color: colors.accent.withValues(alpha: 0.45)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(RadiusScale.r8),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: colors.accent),
              const SizedBox(width: SpacingScale.s4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: labelStyle,
                ),
              ),
            ],
          ),
        );

    return Wrap(
      spacing: SpacingScale.s8,
      runSpacing: SpacingScale.s4,
      children: [
        if (showSplit)
          tool(
            LucideIcons.scissors,
            formatPositionCentis(position),
            onSplitAtPosition!,
          ),
        if (showExclude)
          tool(
            LucideIcons.eraser,
            AppLocalizations.of(context).trim_excludeRange,
            onExcludeRange!,
          ),
      ],
    );
  }
}
