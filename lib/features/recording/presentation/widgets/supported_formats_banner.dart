import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/supported_audio_formats.dart';

class SupportedFormatsBanner extends StatelessWidget {
  const SupportedFormatsBanner({super.key, this.dense = false, this.onDismiss});

  final bool dense;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 12 : 16,
        vertical: dense ? 10 : 14,
      ),
      decoration: BoxDecoration(
        color: colors.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(dense ? 12 : 16),
        border: Border.all(color: colors.info.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.info, size: dense ? 16 : 18, color: colors.infoText),
          SizedBox(width: dense ? 8 : 12),
          Expanded(
            child: Text(
              l10n.import_supportedFormats(kSupportedAudioExtensionsDisplay()),
              style:
                  (dense
                          ? theme.textTheme.bodySmall
                          : theme.textTheme.bodyMedium)
                      ?.copyWith(color: colors.infoText, height: 1.3),
            ),
          ),
          if (onDismiss != null) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: onDismiss,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  LucideIcons.x,
                  size: dense ? 14 : 16,
                  color: colors.infoText.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
