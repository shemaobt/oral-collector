import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

class ReplaceAudioDialog extends StatelessWidget {
  const ReplaceAudioDialog({super.key, required this.wasUploaded});

  final bool wasUploaded;

  static Future<bool> show(
    BuildContext context, {
    required bool wasUploaded,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => ReplaceAudioDialog(wasUploaded: wasUploaded),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(LucideIcons.alertTriangle, size: 20, color: colors.error),
          const SizedBox(width: 8),
          Expanded(child: Text(l10n.recording_replaceTitle)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.recording_replaceMessage,
            style: theme.textTheme.bodyMedium,
          ),
          if (wasUploaded) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.error.withValues(alpha: 0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(LucideIcons.uploadCloud, size: 16, color: colors.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.recording_replaceReuploadNotice,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.common_cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(foregroundColor: colors.error),
          child: Text(l10n.recording_replaceConfirm),
        ),
      ],
    );
  }
}
