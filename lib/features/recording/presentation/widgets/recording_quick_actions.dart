import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/tokens.dart';

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
    this.isUnclassified = false,
  });

  final LocalRecording recording;
  final AppColorSet colors;
  final ThemeData theme;
  final bool canEdit;
  final VoidCallback onTrim;
  final VoidCallback onToggleCleaning;
  final VoidCallback onMoveCategory;
  final VoidCallback onDelete;
  final bool isUnclassified;

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
        const SizedBox(height: SpacingScale.s12),
        Wrap(
          spacing: SpacingScale.s8,
          runSpacing: SpacingScale.s8,
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
              color: cleaningIsActive ? colors.success : colors.warning,
              colors: colors,
              theme: theme,
              onTap: onToggleCleaning,
            ),
            if (canEdit)
              ActionTile(
                icon: isUnclassified
                    ? LucideIcons.tag
                    : LucideIcons.folderInput,
                label: isUnclassified ? l10n.classify_action : l10n.action_move,
                color: isUnclassified ? colors.warning : colors.info,
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
      borderRadius: BorderRadius.circular(RadiusScale.r16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(RadiusScale.r16),
        child: SizedBox(
          width: 80,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 76),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 22, color: color),
                const SizedBox(height: SpacingScale.s8),
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
      ),
    );
  }
}
