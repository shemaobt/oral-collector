import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_colors.dart';

class RecordingTitleSection extends StatelessWidget {
  const RecordingTitleSection({
    super.key,
    required this.theme,
    required this.colors,
    required this.recording,
    required this.isEditingTitle,
    required this.titleController,
    required this.onSave,
    required this.onCancel,
    required this.onStartEdit,
  });

  final ThemeData theme;
  final AppColorSet colors;
  final LocalRecording recording;
  final bool isEditingTitle;
  final TextEditingController titleController;
  final Function(String) onSave;
  final VoidCallback onCancel;
  final VoidCallback onStartEdit;

  @override
  Widget build(BuildContext context) {
    if (isEditingTitle) {
      return Row(
        children: [
          Expanded(
            child: TextField(
              controller: titleController,
              autofocus: true,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              decoration: InputDecoration(
                hintText: 'Recording title',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: colors.accent, width: 2),
                ),
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              onSubmitted: onSave,
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: () => onSave(titleController.text),
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

    return GestureDetector(
      onTap: onStartEdit,
      child: Row(
        children: [
          Expanded(
            child: Text(
              recording.title ?? 'Untitled',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
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
