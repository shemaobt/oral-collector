import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/tokens.dart';
import '../utils/error_helpers.dart';

void showErrorSnackBar(
  BuildContext context,
  Object rawError, {
  String Function(String friendlyError)? template,
}) {
  final colors = AppColors.of(context);
  final theme = Theme.of(context);
  final l10n = AppLocalizations.of(context);
  final friendly = friendlyErrorFor(rawError, l10n);
  final message = template?.call(friendly) ?? friendly;

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(SpacingScale.s8),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(RadiusScale.r8),
              ),
              child: const Icon(
                LucideIcons.alertTriangle,
                size: 18,
                color: AppColors.white,
              ),
            ),
            const SizedBox(width: SpacingScale.s12),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: colors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusScale.r16),
        ),
        margin: const EdgeInsets.fromLTRB(
          SpacingScale.s16,
          0,
          SpacingScale.s16,
          SpacingScale.s16,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingScale.s16,
          vertical: SpacingScale.s16,
        ),
        duration: const Duration(seconds: 4),
      ),
    );
}
