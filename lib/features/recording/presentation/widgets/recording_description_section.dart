import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

class RecordingDescriptionSection extends StatelessWidget {
  const RecordingDescriptionSection({
    super.key,
    required this.theme,
    required this.colors,
    required this.description,
    required this.isEditing,
    required this.controller,
    required this.onSave,
    required this.onCancel,
    required this.onStartEdit,
  });

  final ThemeData theme;
  final AppColorSet colors;
  final String? description;
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: true,
              minLines: 2,
              maxLines: 6,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: l10n.recording_descriptionHint,
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

    final hasText = description != null && description!.trim().isNotEmpty;

    return GestureDetector(
      onTap: onStartEdit,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              hasText ? description!.trim() : l10n.recording_descriptionEmpty,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: hasText
                    ? colors.foreground
                    : colors.secondary.withValues(alpha: 0.6),
                fontStyle: hasText ? FontStyle.normal : FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              LucideIcons.pencil,
              size: 16,
              color: colors.secondary.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
