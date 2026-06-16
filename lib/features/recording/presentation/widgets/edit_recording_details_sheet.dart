import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

class EditRecordingDetailsResult {
  const EditRecordingDetailsResult({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;
}

Future<EditRecordingDetailsResult?> showEditRecordingDetailsSheet(
  BuildContext context, {
  required String initialTitle,
  required String initialDescription,
}) {
  return showModalBottomSheet<EditRecordingDetailsResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.transparent,
    builder: (ctx) => _EditRecordingDetailsSheet(
      initialTitle: initialTitle,
      initialDescription: initialDescription,
    ),
  );
}

class _EditRecordingDetailsSheet extends StatefulWidget {
  const _EditRecordingDetailsSheet({
    required this.initialTitle,
    required this.initialDescription,
  });

  final String initialTitle;
  final String initialDescription;

  @override
  State<_EditRecordingDetailsSheet> createState() =>
      _EditRecordingDetailsSheetState();
}

class _EditRecordingDetailsSheetState
    extends State<_EditRecordingDetailsSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  String? _titleError;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _descriptionController = TextEditingController(
      text: widget.initialDescription,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onSave() {
    final l10n = AppLocalizations.of(context);
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = l10n.recording_titleRequired);
      return;
    }
    Navigator.of(context).pop(
      EditRecordingDetailsResult(
        title: title,
        description: _descriptionController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: Container(
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: colors.border.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.recording_editDetails,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.common_cancel),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              l10n.recording_title,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _titleController,
              autofocus: true,
              maxLines: 1,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.sentences,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                hintText: l10n.recording_titleHint,
                errorText: _titleError,
                filled: true,
                fillColor: colors.surfaceAlt,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.accent, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
              onChanged: (_) {
                if (_titleError != null) {
                  setState(() => _titleError = null);
                }
              },
            ),
            const SizedBox(height: 14),
            Text(
              l10n.recording_description,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _descriptionController,
              minLines: 3,
              maxLines: 6,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: l10n.recording_descriptionHint,
                filled: true,
                fillColor: colors.surfaceAlt,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.accent, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accent,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  l10n.recording_saveChanges,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
