import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

/// Single source of truth mapping a recording's cleaning-status string to its
/// presentation. Consumed by [CleaningStatusBadge] and the cleaning row of
/// RecordingStatusSection. Statuses: none, needs_cleaning, cleaning, cleaned,
/// failed.
@immutable
class CleaningStatusStyle {
  const CleaningStatusStyle({
    required this.icon,
    required this.color,
    required this.label,
    required this.isFlagged,
  });

  final IconData icon;
  final Color color;
  final String label;

  /// `none` and unknown values are not flagged: the badge hides them while the
  /// status section renders a neutral "not flagged" row.
  final bool isFlagged;

  factory CleaningStatusStyle.forStatus(
    String status,
    AppColorSet colors,
    AppLocalizations l10n,
  ) {
    switch (status) {
      case 'needs_cleaning':
        return CleaningStatusStyle(
          icon: LucideIcons.alertCircle,
          color: colors.warning,
          label: l10n.cleaning_needsCleaning,
          isFlagged: true,
        );
      case 'cleaning':
        return CleaningStatusStyle(
          icon: LucideIcons.loader,
          color: colors.info,
          label: l10n.cleaning_cleaning,
          isFlagged: true,
        );
      case 'cleaned':
        return CleaningStatusStyle(
          icon: LucideIcons.sparkles,
          color: colors.success,
          label: l10n.cleaning_cleaned,
          isFlagged: true,
        );
      case 'failed':
        return CleaningStatusStyle(
          icon: LucideIcons.alertTriangle,
          color: colors.error,
          label: l10n.cleaning_cleanFailed,
          isFlagged: true,
        );
      default:
        return CleaningStatusStyle(
          icon: LucideIcons.minus,
          color: colors.secondary,
          label: l10n.detail_notFlagged,
          isFlagged: false,
        );
    }
  }
}
