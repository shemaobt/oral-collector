import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';

enum StatusBannerVariant { plain, warn, error, hot, info }

class StatusBanner extends StatelessWidget {
  const StatusBanner({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.variant = StatusBannerVariant.plain,
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
        variant: StatusBannerVariant.hot,
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

    final (background, foreground) = switch (variant) {
      StatusBannerVariant.plain => (colors.surfaceAlt, colors.foreground),
      StatusBannerVariant.warn => (colors.woodSoft, colors.woodText),
      StatusBannerVariant.error => (colors.brickSoft, colors.error),
      StatusBannerVariant.hot => (colors.soft, colors.deep),
      StatusBannerVariant.info => (colors.bridgeSoft, colors.infoText),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SpacingScale.s16,
        SpacingScale.s12,
        SpacingScale.s16,
        0,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingScale.s16,
          vertical: SpacingScale.s12,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(RadiusScale.r16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: foreground),
            const SizedBox(width: SpacingScale.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: foreground,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: SpacingScale.s4),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: foreground,
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
