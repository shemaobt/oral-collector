import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/utils/format.dart';
import '../../data/services/recovery_coordinator.dart';

enum _RowAction { resume, discard }

class UnsavedRecordingRow extends StatelessWidget {
  const UnsavedRecordingRow({
    super.key,
    required this.session,
    required this.title,
    required this.showNewBadge,
    required this.localeTag,
    required this.onResume,
    required this.onSave,
    required this.onDiscard,
  });

  final InterruptedSession session;
  final String title;
  final bool showNewBadge;
  final String localeTag;
  final VoidCallback onResume;
  final VoidCallback onSave;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);
    final theme = Theme.of(context);
    final subtitle =
        '${formatDurationCompactWithSeconds(session.totalDuration)} · '
        '${formatRelativeTime(context, session.startedAt, localeTag)}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          _PlayButton(onTap: onResume),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.foreground,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (showNewBadge) ...[
                      const SizedBox(width: 8),
                      _NewBadge(label: l10n.recovery_newBadge),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.secondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _SavePill(label: l10n.recovery_save, onTap: onSave),
          PopupMenuButton<_RowAction>(
            icon: Icon(
              LucideIcons.moreHorizontal,
              size: 18,
              color: colors.secondary,
            ),
            tooltip: null,
            position: PopupMenuPosition.under,
            onSelected: (action) {
              switch (action) {
                case _RowAction.resume:
                  onResume();
                  break;
                case _RowAction.discard:
                  onDiscard();
                  break;
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: _RowAction.resume,
                child: Row(
                  children: [
                    Icon(LucideIcons.play, size: 16, color: colors.secondary),
                    const SizedBox(width: 10),
                    Text(l10n.recovery_resume),
                  ],
                ),
              ),
              PopupMenuItem(
                value: _RowAction.discard,
                child: Row(
                  children: [
                    Icon(LucideIcons.trash2, size: 16, color: colors.error),
                    const SizedBox(width: 10),
                    Text(
                      l10n.recovery_discard,
                      style: TextStyle(color: colors.error),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Semantics(
      label: AppLocalizations.of(context).recovery_resume,
      button: true,
      child: Material(
        color: colors.accent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: const SizedBox(
            width: 44,
            height: 44,
            child: Icon(LucideIcons.play, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

class _SavePill extends StatelessWidget {
  const _SavePill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final theme = Theme.of(context);
    return Material(
      color: colors.surfaceAlt,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: colors.foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _NewBadge extends StatelessWidget {
  const _NewBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colors.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colors.accent,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
