import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

/// What the person chose on the way out of the confirmation form.
enum LeaveRecordingChoice {
  /// Park the audio: it stays on disk and comes back in the unsaved list.
  keepForLater,

  /// Delete the audio for good.
  discard,
}

/// Asks what to do with a recording the person is walking away from.
///
/// Returns null when they decide to stay.
///
/// [canKeepForLater] is false wherever there is nowhere to park the audio — the
/// browser, which creates no session row at all. There the dialog is exactly
/// what it has always been, two ways out and the copy that says the recording
/// is about to be deleted, because that is still the truth (ENG-518).
Future<LeaveRecordingChoice?> showLeaveRecordingDialog(
  BuildContext context, {
  required bool canKeepForLater,
}) {
  final l10n = AppLocalizations.of(context);
  final colors = AppColors.of(context);
  return showDialog<LeaveRecordingChoice>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(
        canKeepForLater
            ? l10n.recording_leaveTitle
            : l10n.recording_discardTitle,
      ),
      content: Text(
        canKeepForLater
            ? l10n.recording_leaveMessage
            : l10n.recording_discardMessage,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(l10n.common_cancel),
        ),
        if (canKeepForLater)
          TextButton(
            onPressed: () =>
                Navigator.of(ctx).pop(LeaveRecordingChoice.keepForLater),
            child: Text(l10n.recording_keepForLater),
          ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(LeaveRecordingChoice.discard),
          style: TextButton.styleFrom(foregroundColor: colors.error),
          child: Text(l10n.recording_discard),
        ),
      ],
    ),
  );
}
