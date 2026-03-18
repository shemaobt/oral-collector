import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';

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

  /// Offline warning banner.
  const StatusBanner.offline({super.key})
    : icon = LucideIcons.wifiOff,
      title = 'You are offline',
      subtitle =
          'Some features like syncing and loading data require an internet connection.',
      variant = StatusBannerVariant.warning;

  /// No project membership banner.
  const StatusBanner.noProject({super.key})
    : icon = LucideIcons.shieldAlert,
      title = 'No project assigned',
      subtitle =
          'You haven\'t been added to any project yet. Please contact your administrator and wait to be assigned.',
      variant = StatusBannerVariant.info;

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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: tint.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: tint.withValues(alpha: 0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: tint),
            const SizedBox(width: 12),
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
                    const SizedBox(height: 4),
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
