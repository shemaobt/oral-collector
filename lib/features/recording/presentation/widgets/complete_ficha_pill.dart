import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../l10n/app_localizations.dart';

/// The entry point into the guided completion flow (ENG-374).
///
/// A ficha with nothing open renders nothing at all: an "all good" badge would
/// keep asking for attention it no longer needs. The pill is primary-filled, not
/// a warning tone — an unfinished ficha is work left to do, not a system alert.
class CompleteFichaPill extends StatelessWidget {
  const CompleteFichaPill({
    super.key,
    required this.pendencyCount,
    required this.onTap,
  });

  final int pendencyCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (pendencyCount == 0) return const SizedBox.shrink();

    final colors = AppColors.of(context);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(RadiusScale.r32),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: SpacingScale.s16,
              vertical: SpacingScale.s8,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.clipboardCheck,
                  size: SpacingScale.s16,
                  color: colors.onPrimary,
                ),
                const SizedBox(width: SpacingScale.s8),
                Flexible(
                  // The label gives way before the badge does: it is fixed text
                  // the user can recover from memory, while the count is the
                  // information the pill exists to carry.
                  child: Text(
                    l10n.recording_completeFicha,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colors.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: SpacingScale.s8),
                _CountBadge(count: pendencyCount),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final theme = Theme.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: SpacingScale.s20,
        minHeight: SpacingScale.s20,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.onPrimary.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(RadiusScale.r12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: SpacingScale.s8),
          child: Center(
            widthFactor: 1,
            child: Text(
              '$count',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.onPrimary,
                fontWeight: FontWeight.w700,
                // The count changes as steps resolve; tabular figures keep the
                // badge from resizing under the user's finger.
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
