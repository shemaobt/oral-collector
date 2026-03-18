import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_colors.dart';

class RecordingQuickActions extends StatelessWidget {
  const RecordingQuickActions({
    super.key,
    required this.recording,
    required this.colors,
    required this.theme,
    required this.canEdit,
    required this.onTrim,
    required this.onToggleCleaning,
    required this.onMoveCategory,
    required this.onDelete,
  });

  final LocalRecording recording;
  final AppColorSet colors;
  final ThemeData theme;
  final bool canEdit;
  final VoidCallback onTrim;
  final VoidCallback onToggleCleaning;
  final VoidCallback onMoveCategory;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cleaningIsActive =
        recording.cleaningStatus != 'none' &&
        recording.cleaningStatus != 'cleaned';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.action_actions,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ActionTile(
              icon: LucideIcons.scissors,
              label: l10n.action_split,
              color: colors.primary,
              colors: colors,
              theme: theme,
              onTap: onTrim,
            ),
            ActionTile(
              icon: cleaningIsActive
                  ? LucideIcons.checkCircle
                  : LucideIcons.alertCircle,
              label: cleaningIsActive
                  ? l10n.action_clearFlag
                  : l10n.action_flagClean,
              color: cleaningIsActive ? colors.success : Colors.amber.shade700,
              colors: colors,
              theme: theme,
              onTap: onToggleCleaning,
            ),
            if (canEdit)
              ActionTile(
                icon: LucideIcons.folderInput,
                label: l10n.action_move,
                color: colors.info,
                colors: colors,
                theme: theme,
                onTap: onMoveCategory,
              ),
            if (canEdit)
              ActionTile(
                icon: LucideIcons.trash2,
                label: l10n.action_delete,
                color: colors.error,
                colors: colors,
                theme: theme,
                onTap: onDelete,
              ),
          ],
        ),
      ],
    );
  }
}

class ActionTile extends StatelessWidget {
  const ActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.colors,
    required this.theme,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final AppColorSet colors;
  final ThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 80,
          height: 76,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(height: 6),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
