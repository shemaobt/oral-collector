import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/tokens.dart';

class RecordingAboutSection extends StatelessWidget {
  const RecordingAboutSection({
    super.key,
    required this.theme,
    required this.colors,
    required this.title,
    required this.description,
    required this.canEdit,
    required this.onEdit,
  });

  final ThemeData theme;
  final AppColorSet colors;
  final String? title;
  final String? description;
  final bool canEdit;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasTitle = title != null && title!.trim().isNotEmpty;
    final hasDescription =
        description != null && description!.trim().isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                hasTitle ? title!.trim() : l10n.recording_titleEmpty,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: hasTitle
                      ? colors.foreground
                      : colors.secondary.withValues(alpha: 0.6),
                  fontStyle: hasTitle ? FontStyle.normal : FontStyle.italic,
                ),
              ),
              const SizedBox(height: SpacingScale.s8),
              Text(
                hasDescription
                    ? description!.trim()
                    : l10n.recording_descriptionEmpty,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: hasDescription
                      ? colors.foreground.withValues(alpha: 0.85)
                      : colors.secondary.withValues(alpha: 0.6),
                  fontStyle: hasDescription
                      ? FontStyle.normal
                      : FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        if (canEdit) ...[
          const SizedBox(width: SpacingScale.s12),
          Material(
            color: colors.accent,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onEdit,
              child: const SizedBox(
                width: SpacingScale.s40,
                height: SpacingScale.s40,
                child: Icon(
                  LucideIcons.pencil,
                  size: 18,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
