import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';

class NoProjectCard extends StatelessWidget {
  const NoProjectCard({super.key, required this.onBrowse});

  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: colors.surfaceAlt,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          children: [
            Icon(
              LucideIcons.folderOpen,
              size: 48,
              color: colors.secondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'Select a project to get started',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colors.secondary,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onBrowse,
              icon: const Icon(LucideIcons.search, size: 18),
              label: const Text('Browse Projects'),
              style: FilledButton.styleFrom(
                backgroundColor: colors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
