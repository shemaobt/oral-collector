import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/tokens.dart';

/// The detail screen's overflow action menu, shown only when the user can edit.
/// Extracted from recording_detail_screen's build() (ENG-194 PR-B); the parent
/// keeps the `canEdit` gate.
class RecordingActionMenu extends StatelessWidget {
  const RecordingActionMenu({
    super.key,
    required this.colors,
    required this.isUnclassified,
    required this.onTrim,
    required this.onExport,
    required this.onReplace,
    required this.onMove,
    required this.onClassify,
    required this.onDelete,
  });

  final AppColorSet colors;
  final bool isUnclassified;
  final VoidCallback onTrim;
  final VoidCallback onExport;
  final VoidCallback onReplace;
  final VoidCallback onMove;
  final VoidCallback onClassify;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopupMenuButton<String>(
      icon: Icon(LucideIcons.moreVertical, color: colors.foreground),
      onSelected: (value) {
        switch (value) {
          case 'trim':
            onTrim();
          case 'export':
            onExport();
          case 'replace':
            onReplace();
          case 'move':
            onMove();
          case 'classify':
            onClassify();
          case 'delete':
            onDelete();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'trim',
          child: Row(
            children: [
              const Icon(LucideIcons.scissors, size: 18),
              const SizedBox(width: SpacingScale.s12),
              Text(l10n.recording_splitRecording),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'export',
          child: Row(
            children: [
              const Icon(LucideIcons.share2, size: 18),
              const SizedBox(width: SpacingScale.s12),
              Text(l10n.recording_exportAudio),
            ],
          ),
        ),
        if (isUnclassified)
          PopupMenuItem(
            value: 'classify',
            child: Row(
              children: [
                Icon(LucideIcons.tag, size: 18, color: colors.warning),
                const SizedBox(width: SpacingScale.s12),
                Text(l10n.classify_action),
              ],
            ),
          )
        else
          PopupMenuItem(
            value: 'move',
            child: Row(
              children: [
                const Icon(LucideIcons.folderInput, size: 18),
                const SizedBox(width: SpacingScale.s12),
                Text(l10n.recording_moveCategory),
              ],
            ),
          ),
        PopupMenuItem(
          value: 'replace',
          child: Row(
            children: [
              Icon(LucideIcons.refreshCw, size: 18, color: colors.error),
              const SizedBox(width: SpacingScale.s12),
              Text(
                l10n.recording_replaceAudio,
                style: TextStyle(color: colors.error),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(LucideIcons.trash2, size: 18, color: colors.error),
              const SizedBox(width: SpacingScale.s12),
              Text(l10n.common_delete, style: TextStyle(color: colors.error)),
            ],
          ),
        ),
      ],
    );
  }
}
