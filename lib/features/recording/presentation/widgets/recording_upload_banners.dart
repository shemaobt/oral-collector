import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/classification.dart';
import '../../domain/entities/local_recording_entity.dart';
import 'recording_action_banner.dart';

/// Everything that explains a blocked upload, stacked in a fixed order.
///
/// Each banner names one reason the recording is not on the server and offers
/// the single action that clears it. Extracted from the detail screen's build()
/// so the set can be rendered — and its order checked — without mounting the
/// hero player.
class RecordingUploadBanners extends StatelessWidget {
  const RecordingUploadBanners({
    super.key,
    required this.recording,
    required this.canEdit,
    required this.onEditDetails,
    required this.onRetryUpload,
    required this.onDelete,
    required this.onClearSecondary,
  });

  final LocalRecordingEntity recording;

  /// Gates every banner action that writes to the recording. `false` renders
  /// the banner with a disabled button, so the explanation survives even when
  /// the viewer cannot act on it.
  final bool canEdit;

  final VoidCallback onEditDetails;
  final VoidCallback onRetryUpload;
  final VoidCallback onDelete;
  final VoidCallback onClearSecondary;

  bool get _hasSecondaryCollision => secondaryEqualsPrimary(
    primaryRegisterId: recording.registerId,
    primaryGenreId: recording.genreId,
    primarySubcategoryId: recording.subcategoryId,
    secondaryRegisterId: recording.secondaryRegisterId,
    secondaryGenreId: recording.secondaryGenreId,
    secondarySubcategoryId: recording.secondarySubcategoryId,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    RecordingActionBanner banner({
      required IconData icon,
      required String message,
      required String actionLabel,
      required VoidCallback? onAction,
    }) => RecordingActionBanner(
      theme: theme,
      icon: icon,
      message: message,
      actionLabel: actionLabel,
      accentColor: theme.colorScheme.error,
      backgroundColor: theme.colorScheme.errorContainer.withValues(alpha: 0.35),
      borderColor: theme.colorScheme.error.withValues(alpha: 0.5),
      actionBackgroundColor: theme.colorScheme.error.withValues(alpha: 0.12),
      onAction: onAction,
    );

    final banners = <Widget>[
      // The upload was rejected because the title is already taken in this
      // project; the only way forward is a rename, which requeues the upload.
      if (recording.uploadStatus == 'failed_conflict')
        banner(
          icon: LucideIcons.alertCircle,
          message: l10n.recording_duplicateTitleMessage(recording.title ?? ''),
          actionLabel: l10n.recording_editDetails,
          onAction: canEdit ? onEditDetails : null,
        ),
      // The upload never left the device because the description is missing or
      // too short for the create rule; lengthening it requeues the recording.
      if (recording.uploadStatus == 'failed_description')
        banner(
          icon: LucideIcons.alertCircle,
          message: l10n.recording_descriptionGapMessage,
          actionLabel: l10n.recording_editDetails,
          onAction: canEdit ? onEditDetails : null,
        ),
      // The upload spent its retry budget and left the queue (ENG-377). Nothing
      // else will pick it up, so the way back in has to be offered here.
      if (recording.uploadStatus == 'failed_exhausted')
        banner(
          icon: LucideIcons.alertOctagon,
          message: l10n.recording_uploadExhaustedMessage,
          actionLabel: l10n.detail_retry,
          onAction: onRetryUpload,
        ),
      // The audio is not on the device any more, so there is nothing to send.
      // No retry here: the engine already looked everywhere it knows, and the
      // app deletes files outright, so another attempt would find the same
      // nothing. What is left to offer is removing the row that outlived its
      // audio.
      if (recording.uploadStatus == 'failed_missing_file')
        banner(
          icon: LucideIcons.fileX,
          message: l10n.recording_fileMissingMessage,
          actionLabel: l10n.common_delete,
          onAction: canEdit ? onDelete : null,
        ),
      if (_hasSecondaryCollision)
        banner(
          icon: LucideIcons.alertCircle,
          message: l10n.recording_secondaryCollisionBanner,
          actionLabel: l10n.recording_clearSecondary,
          onAction: canEdit ? onClearSecondary : null,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final banner in banners) ...[
          banner,
          const SizedBox(height: SpacingScale.s16),
        ],
      ],
    );
  }
}
