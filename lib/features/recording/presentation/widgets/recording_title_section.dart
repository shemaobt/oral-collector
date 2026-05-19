import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

class RecordingTitleSection extends StatelessWidget {
  const RecordingTitleSection({
    super.key,
    required this.theme,
    required this.colors,
    required this.title,
    required this.isEditing,
    required this.controller,
    required this.onSave,
    required this.onCancel,
    required this.onStartEdit,
  });

  final ThemeData theme;
  final AppColorSet colors;
  final String? title;
  final bool isEditing;
  final TextEditingController controller;
  final Function(String) onSave;
  final VoidCallback onCancel;
  final VoidCallback onStartEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (isEditing) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: true,
              maxLines: 1,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: onSave,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                hintText: l10n.recording_titleHint,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: colors.accent, width: 2),
                ),
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: () => onSave(controller.text),
            icon: const Icon(LucideIcons.check, size: 18),
            style: IconButton.styleFrom(
              backgroundColor: colors.success.withValues(alpha: 0.15),
              foregroundColor: colors.success,
            ),
          ),
          const SizedBox(width: 4),
          IconButton.filled(
            onPressed: onCancel,
            icon: const Icon(LucideIcons.x, size: 18),
            style: IconButton.styleFrom(
              backgroundColor: colors.error.withValues(alpha: 0.15),
              foregroundColor: colors.error,
            ),
          ),
        ],
      );
    }

    final hasText = title != null && title!.trim().isNotEmpty;

    return GestureDetector(
      onTap: onStartEdit,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              hasText ? title!.trim() : l10n.recording_titleEmpty,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: hasText
                    ? colors.foreground
                    : colors.secondary.withValues(alpha: 0.6),
                fontStyle: hasText ? FontStyle.normal : FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            LucideIcons.pencil,
            size: 16,
            color: colors.secondary.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }
}
