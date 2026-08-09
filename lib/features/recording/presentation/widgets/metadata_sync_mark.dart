import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/tokens.dart';
import '../../domain/entities/pending_metadata_field.dart';

/// How a metadata edit the server has not taken is presented (ENG-405).
///
/// One mapping shared by the list card and the detail screen's status card, in
/// the shape `CleaningStatusStyle` already uses, so the two surfaces cannot
/// drift into describing the same row differently.
///
/// The vocabulary is the upload queue's — same tokens, same glyph per *kind* of
/// refusal — because the user has already learned it there. What it must never
/// borrow is the upload's *subject*: this axis is independent of whether the
/// audio went up, so every label speaks of the change, never of the recording.
@immutable
class MetadataSyncStyle {
  const MetadataSyncStyle({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;

  /// Deliberately not one colour for every unsent edit. Waiting for a
  /// connection is routine and costs the user nothing, so painting it in
  /// [AppColorSet.error] would raise an alarm about something that will clear
  /// itself; a refusal never clears itself, so painting it in the calm ink
  /// would hide the one state that needs a person.
  final Color color;

  final String label;

  /// The presentation for [status], or null when there is nothing to show.
  ///
  /// Null covers `synced` and — on purpose — any token this build does not
  /// know, which is what a row written by a newer build looks like. Guessing at
  /// one would be worse than staying quiet: an invented mark on a row that is
  /// perfectly in order is a false alarm the user cannot act on.
  static MetadataSyncStyle? forStatus(
    String status,
    AppColorSet colors,
    AppLocalizations l10n,
  ) => switch (status) {
    MetadataSyncStatus.pending => MetadataSyncStyle(
      // A clock, not a cloud: every cloud glyph on this screen belongs to the
      // audio upload, and the point of this mark is that the two are separate.
      icon: LucideIcons.clock,
      color: colors.secondary,
      label: l10n.recording_metadataSyncPending,
    ),
    MetadataSyncStatus.failedForbidden => MetadataSyncStyle(
      // The one refusal with no upload counterpart, so it takes the glyph the
      // app already spends on permission rather than one of the queue's.
      icon: LucideIcons.lock,
      color: colors.error,
      label: l10n.recording_metadataSyncForbidden,
    ),
    MetadataSyncStatus.failedConflict => MetadataSyncStyle(
      // Same stack of pages the card draws for an upload refused on a title
      // clash: same cause, same way out.
      icon: LucideIcons.copy,
      color: colors.error,
      label: l10n.recording_metadataSyncConflict,
    ),
    MetadataSyncStatus.failedExhausted => MetadataSyncStyle(
      icon: LucideIcons.alertOctagon,
      color: colors.error,
      label: l10n.recording_metadataSyncExhausted,
    ),
    _ => null,
  };
}

/// The list card's line for an unsent metadata edit (ENG-405).
///
/// Public so a test can assert the line is absent by type rather than by
/// hunting for a string that some other row might one day carry — the same
/// reasoning as `RecordingDescriptionLine`.
///
/// A row of its own under the footer, rather than another chip inside it: the
/// footer already rations its width between the classification, the pendency
/// chip and the duration, and a fourth claimant would push the classification
/// out on a phone. It sits beside the upload-progress and paused-while-
/// recording rows, which is where the card puts state that is about the moment
/// rather than about the recording.
class RecordingMetadataSyncMark extends StatelessWidget {
  const RecordingMetadataSyncMark({super.key, required this.style});

  final MetadataSyncStyle style;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(style.icon, size: 12, color: style.color),
        const SizedBox(width: SpacingScale.s4),
        Flexible(
          child: Text(
            style.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: style.color,
              fontWeight: FontWeight.w500,
            ),
            // Two lines because the refusals name their cause, and the cause
            // is the part that tells the user what to do; one line drops it at
            // any large text scale. Beyond two the card stops being a list row.
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
