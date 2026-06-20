import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/tokens.dart';

class NoProjectCard extends StatelessWidget {
  const NoProjectCard({super.key, required this.onBrowse});

  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SpacingScale.s16,
        SpacingScale.s24,
        SpacingScale.s16,
        0,
      ),
      child: Container(
        padding: const EdgeInsets.all(SpacingScale.s28),
        decoration: BoxDecoration(
          color: colors.surfaceAlt,
          borderRadius: BorderRadius.circular(RadiusScale.r24),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          children: [
            Icon(
              LucideIcons.folderOpen,
              size: 48,
              color: colors.secondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: SpacingScale.s12),
            Text(
              l10n.home_noProjectTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colors.secondary,
              ),
            ),
            const SizedBox(height: SpacingScale.s16),
            FilledButton.icon(
              onPressed: onBrowse,
              icon: const Icon(LucideIcons.search, size: 18),
              label: Text(l10n.home_browseProjects),
              style: FilledButton.styleFrom(
                backgroundColor: colors.accent,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(RadiusScale.r12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
