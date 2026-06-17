import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';

enum StatusBannerVariant { warning, info }

class StatusBanner extends StatelessWidget {
  const StatusBanner({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.variant = StatusBannerVariant.warning,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final StatusBannerVariant variant;

  factory StatusBanner.offline(AppLocalizations l10n, {Key? key}) =>
      StatusBanner(
        key: key,
        icon: LucideIcons.wifiOff,
        title: l10n.projectSettings_offlineTitle,
        subtitle: l10n.status_offlineSubtitle,
        variant: StatusBannerVariant.warning,
      );

  factory StatusBanner.noProject(AppLocalizations l10n, {Key? key}) =>
      StatusBanner(
        key: key,
        icon: LucideIcons.shieldAlert,
        title: l10n.status_noProject,
        subtitle: l10n.status_noProjectSubtitle,
        variant: StatusBannerVariant.info,
      );

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final theme = Theme.of(context);

    final Color tint;
    switch (variant) {
      case StatusBannerVariant.warning:
        tint = colors.accent;
      case StatusBannerVariant.info:
        tint = colors.info;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SpacingScale.s16,
        SpacingScale.s12,
        SpacingScale.s16,
        0,
      ),
      child: Container(
        padding: const EdgeInsets.all(SpacingScale.s16),
        decoration: BoxDecoration(
          color: tint.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(RadiusScale.r16),
          border: Border.all(color: tint.withValues(alpha: 0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: tint),
            const SizedBox(width: SpacingScale.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: tint,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: SpacingScale.s4),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.secondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
