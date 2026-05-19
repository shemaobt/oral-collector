import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/utils/format.dart';
import '../../data/services/recovery_coordinator.dart';

class UnsavedRecordingsBanner extends StatelessWidget {
  const UnsavedRecordingsBanner({
    super.key,
    required this.sessions,
    required this.onReview,
  });

  final List<InterruptedSession> sessions;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);
    final theme = Theme.of(context);
    final localeTag = Localizations.localeOf(context).toString();
    final isDark = theme.brightness == Brightness.dark;

    final latest = sessions.first;
    final summary = l10n.recovery_latestSummary(
      formatDurationCompactWithSeconds(latest.totalDuration),
      formatRelativeTime(context, latest.startedAt, localeTag),
    );

    return Container(
      decoration: BoxDecoration(
        color: colors.accent.withValues(alpha: isDark ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.accent.withValues(alpha: isDark ? 0.35 : 0.22),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: [
          _MicCounterBadge(
            count: sessions.length,
            accent: colors.accent,
            isDark: isDark,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.recovery_unsavedCount(sessions.length),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.foreground,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  summary,
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
          _ReviewButton(label: l10n.recovery_review, onTap: onReview),
        ],
      ),
    );
  }
}

class _MicCounterBadge extends StatelessWidget {
  const _MicCounterBadge({
    required this.count,
    required this.accent,
    required this.isDark,
  });

  final int count;
  final Color accent;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: isDark ? 0.22 : 0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(LucideIcons.mic, size: 18, color: accent),
          ),
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                count > 99 ? '99+' : '$count',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewButton extends StatelessWidget {
  const _ReviewButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Material(
      color: colors.accent,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
