import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/utils/format.dart';
import '../../../../shared/utils/recording_description.dart';
import '../../../sync/presentation/notifiers/sync_notifier.dart';
import '../../domain/entities/classification.dart';
import '../../domain/entities/local_recording_entity.dart';
import '../../domain/entities/local_recording_entity_classification.dart';
import '../../domain/entities/review_pendency.dart';
import '../notifiers/recording_session_notifier.dart';
import 'metadata_sync_mark.dart';

/// The colour the upload state paints, or null for a recording that is merely
/// local — the one state with no colour of its own.
///
/// Null rather than a default colour because the rail and the icon want
/// different fallbacks, and comparing the returned colour to decide which
/// branch produced it would silently change the icon on any palette where two
/// tokens happen to collide.
Color? _statusAccent(String uploadStatus, AppColorSet colors) =>
    switch (uploadStatus) {
      'uploaded' || 'verified' => colors.success,
      'uploading' => colors.accent,
      'failed' ||
      'failed_conflict' ||
      'failed_description' ||
      'failed_exhausted' ||
      'failed_missing_file' => colors.error,
      _ => null,
    };

/// One glyph per state, including one per *kind* of blocked upload.
///
/// Every blocked state shares `colors.error`, and their label only exists in
/// the tooltip and in semantics, so the shape is the whole of what a sighted
/// user gets to tell them apart: a stack of pages for a title that clashes
/// with another recording's, a page of text for a description that is too
/// short to send, a stop sign for an upload that ran out of attempts, a
/// crossed-out page for audio that is no longer on the device.
IconData _statusIcon(String uploadStatus) => switch (uploadStatus) {
  'uploaded' || 'verified' => LucideIcons.checkCircle2,
  'uploading' => LucideIcons.upload,
  'failed' => LucideIcons.cloudOff,
  'failed_conflict' => LucideIcons.copy,
  'failed_description' => LucideIcons.fileText,
  'failed_exhausted' => LucideIcons.alertOctagon,
  'failed_missing_file' => LucideIcons.fileX,
  _ => LucideIcons.smartphone,
};

String _statusLabel(String uploadStatus, AppLocalizations l10n) =>
    switch (uploadStatus) {
      'uploaded' || 'verified' => l10n.recording_statusUploaded,
      'uploading' => l10n.recording_statusUploading,
      'failed' => l10n.recording_statusFailed,
      'failed_conflict' => l10n.recording_statusNameConflict,
      'failed_description' => l10n.recording_statusDescriptionTooShort,
      'failed_exhausted' => l10n.recording_statusRetriesExhausted,
      'failed_missing_file' => l10n.recording_statusFileMissing,
      _ => l10n.recording_statusLocal,
    };

/// The description as the card should show it, or null when the line goes.
///
/// Trimmed before anything else: `blankToNull` alone calls "   " present while
/// [isDescriptionSufficient] calls it empty, and the card drew quotation marks
/// around the whitespace that disagreement left behind.
String? _visibleDescription(String? raw) => blankToNull(raw?.trim());

/// Width the left status rail takes before the content column gets any.
const double _railWidth = 4;

/// One definition of the duration's type, shared by the [Text] that paints it
/// and by the measurement that decides whether it is painted at all.
TextStyle? _durationStyle(BuildContext context) =>
    Theme.of(context).textTheme.labelSmall?.copyWith(
      color: AppColors.of(context).secondary.withValues(alpha: 0.7),
      fontFeatures: const [FontFeature.tabularFigures()],
    );

/// Width [text] takes when laid out the way a [Text] carrying [style] would.
///
/// The footer has to rank the pendency chip above the duration, and a [Row]
/// cannot express that: it gives every non-flex child its intrinsic width
/// first and hands only the remainder to the flexible one, so whichever
/// element is left out of the flex is served first regardless of rank.
/// Measuring both strings up front is what lets the row decide instead of the
/// layout algorithm. Two short single-line strings, once per build.
double _textWidth(BuildContext context, String text, TextStyle? style) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: DefaultTextStyle.of(context).style.merge(style),
    ),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    maxLines: 1,
  )..layout();
  return painter.width;
}

/// One row of the recordings list (ENG-374, card V3).
///
/// The list answers "which recordings still need me?", so the room the upload
/// chip and the duration chip used to take now goes to the description and to
/// a single pendency chip. Upload state survives as an icon with its old label
/// moved into semantics — colour alone would say nothing to a screen reader.
///
/// Three rows: the title line (title, upload glyph, date), an optional
/// description line, and the footer (tag, classification, pendency chip,
/// chevron). The glyph is up on the title line because it answers "is this one
/// safe yet", which is a property of the recording the title names; the
/// classification is down in the footer because folding those two rows into one
/// is what keeps the card to the height the design package specifies.
///
/// ENG-382 let the duration back into the footer as plain text rather than a
/// chip: it earns a place by telling an accidental misfire from a real
/// session, but it re-enters ranked below the description that displaced it.
/// The classification joining that row outranks it too, so on a phone the
/// duration no longer renders at all — which is the package's "the duration
/// does not come back", reached by the ranking rather than by deleting it.
///
/// Every row below is a private widget that reads its own `l10n` off the
/// context; nothing on this card takes localizations as a parameter.
class RecordingCard extends ConsumerWidget {
  const RecordingCard({
    super.key,
    required this.recording,
    required this.genreName,
    required this.onTap,
    this.subcategoryName,
    this.registerName,
    this.onDelete,
  });

  final LocalRecordingEntity recording;
  final String? genreName;
  final String? subcategoryName;
  final String? registerName;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final isUploadingThis = ref.watch(
      syncNotifierProvider.select((s) => s.uploadingId == recording.id),
    );
    final uploadProgress = ref.watch(
      syncNotifierProvider.select(
        (s) => s.uploadingId == recording.id ? s.syncProgress : 0,
      ),
    );
    final isRecordingActive = ref.watch(
      recordingSessionNotifierProvider.select((s) => s.isRecording),
    );
    final isPausedByRecording =
        isRecordingActive &&
        recording.uploadStatus == 'local' &&
        (recording.uploadedBytes > 0 || recording.resumableSessionUri != null);
    final description = _visibleDescription(recording.description);
    final metadataSync = MetadataSyncStyle.forStatus(
      recording.metadataSyncStatus,
      colors,
      AppLocalizations.of(context),
    );

    // The footer needs its own width to rank the chip above the duration, and
    // the measurement has to happen here rather than down in `_FooterRow`:
    // everything below is wrapped in an `IntrinsicHeight` for the rail, and a
    // `LayoutBuilder` refuses to answer the intrinsic query that sends.
    return LayoutBuilder(
      builder: (context, constraints) => _cardBody(
        context,
        colors: colors,
        description: description,
        isUploadingThis: isUploadingThis,
        uploadProgress: uploadProgress,
        isPausedByRecording: isPausedByRecording,
        metadataSync: metadataSync,
        footerWidth: constraints.maxWidth.isFinite
            ? constraints.maxWidth - _railWidth - SpacingScale.s16 * 2
            : null,
      ),
    );
  }

  Widget _cardBody(
    BuildContext context, {
    required AppColorSet colors,
    required String? description,
    required bool isUploadingThis,
    required int uploadProgress,
    required bool isPausedByRecording,
    required MetadataSyncStyle? metadataSync,
    required double? footerWidth,
  }) {
    return Material(
      color: colors.card,
      borderRadius: BorderRadius.circular(RadiusScale.r16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: _railWidth,
                decoration: BoxDecoration(
                  color:
                      _statusAccent(recording.uploadStatus, colors) ??
                      colors.border,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(RadiusScale.r16),
                    bottomLeft: Radius.circular(RadiusScale.r16),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SpacingScale.s16,
                    vertical: SpacingScale.s12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TitleRow(recording: recording, width: footerWidth),
                      if (description != null) ...[
                        const SizedBox(height: 2),
                        RecordingDescriptionLine(description: description),
                      ],
                      const SizedBox(height: SpacingScale.s8),
                      _FooterRow(
                        recording: recording,
                        genreName: genreName,
                        subcategoryName: subcategoryName,
                        registerName: registerName,
                        width: footerWidth,
                      ),
                      if (isUploadingThis) ...[
                        const SizedBox(height: SpacingScale.s8),
                        _UploadProgressRow(progress: uploadProgress),
                      ],
                      if (isPausedByRecording) ...[
                        const SizedBox(height: SpacingScale.s8),
                        const _PausedWhileRecordingRow(),
                      ],
                      if (metadataSync != null) ...[
                        const SizedBox(height: SpacingScale.s8),
                        RecordingMetadataSyncMark(style: metadataSync),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TitleRow extends StatelessWidget {
  const _TitleRow({required this.recording, required this.width});

  final LocalRecordingEntity recording;

  /// Room the row has to spend, or null when the card's width is unbounded.
  final double? width;

  static const double _statusTarget = 24;

  /// The most of the row the date may take.
  ///
  /// The date is non-flex so that the title yields to it at ordinary sizes —
  /// a truncated title is still recognisable, a truncated date is not. That
  /// ranking has to stop somewhere: in Arabic at 2.0x the spelled-out date
  /// plus the upload glyph outgrow the row, and without a ceiling the title
  /// is pushed off the card rather than merely shortened.
  static const double _dateShare = 0.45;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final title = blankToNull(recording.title);
    final statusLabel = _statusLabel(recording.uploadStatus, l10n);
    return Row(
      children: [
        Expanded(
          child: Text(
            title ?? formatUntitledRecordingTime(recording.recordedAt, locale),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              // A timestamp standing in for a title is not the recording's
              // name, and italic in the softer ink is what says so.
              fontStyle: title == null ? FontStyle.italic : FontStyle.normal,
              color: title == null ? colors.secondary : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: SpacingScale.s8),
        // The upload state belongs on this line (card V3): it answers "is this
        // one safe yet", which is a property of the recording the title names,
        // not of the classification the footer describes.
        Tooltip(
          message: statusLabel,
          // The glyph stays small; its long-press target does not. A 13px hit
          // area puts the only visible copy of the status label out of reach.
          child: SizedBox.square(
            dimension: _statusTarget,
            child: Center(
              child: Icon(
                _statusIcon(recording.uploadStatus),
                size: 13,
                // The rail is allowed to be faint. The icon carries the state,
                // so a local recording borrows the readable grey instead.
                color:
                    _statusAccent(recording.uploadStatus, colors) ??
                    colors.secondary,
                semanticLabel: statusLabel,
              ),
            ),
          ),
        ),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: width == null ? double.infinity : width! * _dateShare,
          ),
          child: Text(
            formatRecordingDate(recording.recordedAt, locale, l10n: l10n),
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.secondary.withValues(alpha: 0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// The classification as one line, and whether it is one at all.
///
/// The register is part of it (card V3, "classificação completa"): the list
/// screen has always handed the card a `registerName`, and the card dropped it
/// — so a recording classified down to its register read exactly like one that
/// was still missing it.
({String text, bool isUnclassified}) _classification(
  BuildContext context, {
  required LocalRecordingEntity recording,
  required String? genreName,
  required String? subcategoryName,
  required String? registerName,
}) {
  final l10n = AppLocalizations.of(context);
  if (recording.isUnclassified) {
    return (text: l10n.recording_unclassified, isUnclassified: true);
  }
  final parts = <String>[?genreName, ?subcategoryName, ?registerName];
  return (
    text: parts.isEmpty ? l10n.recording_unknownGenre : parts.join(' > '),
    isUnclassified: false,
  );
}

/// One definition of the classification's type, shared by the [Text] that
/// paints it and by the measurement that rations the footer.
///
/// Unclassified is italic in the ordinary ink, never `warning`: that token is
/// reserved for system trouble — a corrupted file, an upload that failed — and
/// spending it on a field the user simply has not filled in yet says something
/// broke when nothing did.
TextStyle? _classificationStyle(BuildContext context, bool isUnclassified) =>
    Theme.of(context).textTheme.labelSmall?.copyWith(
      color: AppColors.of(context).secondary,
      fontWeight: FontWeight.w600,
      fontStyle: isUnclassified ? FontStyle.italic : FontStyle.normal,
    );

class _FooterRow extends StatelessWidget {
  const _FooterRow({
    required this.recording,
    required this.genreName,
    required this.subcategoryName,
    required this.registerName,
    required this.width,
  });

  final LocalRecordingEntity recording;
  final String? genreName;
  final String? subcategoryName;
  final String? registerName;

  /// Room the row has to spend, or null when the card's width is unbounded
  /// and there is nothing to ration.
  final double? width;

  static const double _tagSize = 12;
  static const double _chevronSize = 16;
  static const double _secondarySize = 12;

  /// The most of the shared space the chip may take.
  ///
  /// It outranks the classification — it is the call to action, and it is the
  /// one element whose label cannot be guessed from an ellipsis — but a row
  /// where it takes everything leaves the card unable to say which recording
  /// it is. Only ever binds at large text scales on a narrow phone; at any
  /// ordinary size the chip is well under its share and the classification
  /// keeps the rest.
  static const double _chipShare = 0.6;

  /// Everything in the row that is neither the classification, the chip nor
  /// the duration: the tag, the chevron, the gaps between the slots, and the
  /// secondary-classification glyph when the recording carries one.
  double _furniture(bool hasSecondary) =>
      _tagSize +
      _chevronSize +
      SpacingScale.s8 * 4 +
      (hasSecondary ? _secondarySize + SpacingScale.s4 : 0);

  /// Whether the duration can be shown without taking anything from the two
  /// things ranked above it.
  ///
  /// The duration is the footer's lowest-ranked element (ENG-382 let it back in
  /// on that condition), so it appears only when the classification and the
  /// chip already have the width they want — which, now that the classification
  /// shares this row, is rarely true on a phone. Anything short of that and it
  /// goes entirely: `Flexible` with an ellipsis would paint `1:0…`, which reads
  /// as a wrong duration rather than as an absent one.
  bool _durationFits(
    BuildContext context, {
    required String classification,
    required bool isUnclassified,
    required String? pendency,
    required String duration,
  }) {
    final available = width;
    if (available == null) return true;
    final chip = pendency == null
        ? 0.0
        : _PendencyChip.widthFor(context, pendency);
    return _textWidth(
              context,
              classification,
              _classificationStyle(context, isUnclassified),
            ) +
            chip +
            _textWidth(context, duration, _durationStyle(context)) +
            _furniture(recording.hasSecondary) <=
        available;
  }

  /// The width cap the chip is laid out under, or null when the card's width
  /// is unbounded and nothing has to be rationed.
  double? _chipCap(BuildContext context, {required bool showDuration}) {
    final available = width;
    if (available == null) return null;
    final duration = showDuration
        ? _textWidth(
            context,
            formatDurationHMS(recording.durationSeconds),
            _durationStyle(context),
          )
        : 0.0;
    final shared = available - _furniture(recording.hasSecondary) - duration;
    return shared <= 0 ? 0 : shared * _chipShare;
  }

  /// At most one chip: naming every open field would crowd the row the
  /// description just moved into, so two or more collapse into a count — and a
  /// count has no kind, so it loses the per-kind glyph with the per-kind name.
  ({String label, IconData icon})? _pendency(AppLocalizations l10n) {
    final pendencies = recordingPendencies(recording);
    if (pendencies.isEmpty) return null;
    if (pendencies.length > 1) {
      return (
        label: l10n.recording_pendencyCount(pendencies.length),
        icon: LucideIcons.circleDashed,
      );
    }
    return switch (pendencies.first) {
      PendencyKind.classification => (
        label: l10n.recording_pendencyClassification,
        // The same tag this row labels the classification with: the chip names
        // the field the label is standing in for.
        icon: LucideIcons.tag,
      ),
      PendencyKind.description => (
        label: l10n.recording_pendencyDescription,
        icon: LucideIcons.fileText,
      ),
      PendencyKind.storyteller => (
        label: l10n.recording_pendencyStoryteller,
        icon: LucideIcons.userMinus,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);
    final classification = _classification(
      context,
      recording: recording,
      genreName: genreName,
      subcategoryName: subcategoryName,
      registerName: registerName,
    );
    final pendency = _pendency(l10n);
    final duration = formatDurationHMS(recording.durationSeconds);
    // The classification takes the slack through its Expanded, and the duration
    // is in the row at all only when everything above it already fits. Leaving
    // the duration in unconditionally would invert the ranking: a Row sizes its
    // non-flex children first, so the duration would be paid before the
    // classification and the classification would absorb the whole shortfall.
    final showDuration = _durationFits(
      context,
      classification: classification.text,
      isUnclassified: classification.isUnclassified,
      pendency: pendency?.label,
      duration: duration,
    );
    return Row(
      children: [
        Icon(LucideIcons.tag, size: _tagSize, color: colors.secondary),
        const SizedBox(width: SpacingScale.s8),
        Expanded(
          child: Text(
            classification.text,
            style: _classificationStyle(context, classification.isUnclassified),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (recording.hasSecondary) ...[
          const SizedBox(width: SpacingScale.s4),
          Tooltip(
            message: l10n.recording_alsoClassifiedAsTooltip,
            child: Icon(
              LucideIcons.layers,
              size: 12,
              color: colors.secondary.withValues(alpha: 0.7),
              semanticLabel: l10n.recording_alsoClassifiedAsTooltip,
            ),
          ),
        ],
        if (pendency != null) ...[
          const SizedBox(width: SpacingScale.s8),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth:
                  _chipCap(context, showDuration: showDuration) ??
                  double.infinity,
            ),
            child: _PendencyChip(label: pendency.label, icon: pendency.icon),
          ),
        ],
        if (showDuration) ...[
          const SizedBox(width: SpacingScale.s8),
          Text(
            // Seconds, not the compact hours-and-minutes form: an accidental
            // three-second misfire and a real forty-minute take both read as
            // "0m" there, and telling those apart is why the duration is back.
            duration,
            // `00:03` is ambiguous read aloud — mm:ss and hh:mm sound the
            // same. The compact form names its units, so the announcement
            // carries the fact the glyphs only imply.
            semanticsLabel: formatDurationCompactWithSeconds(
              Duration(
                milliseconds: (recording.durationSeconds * 1000).round(),
              ),
            ),
            style: _durationStyle(context),
          ),
        ],
        const SizedBox(width: SpacingScale.s8),
        Icon(
          LucideIcons.chevronRight,
          size: _chevronSize,
          color: colors.border,
        ),
      ],
    );
  }
}

/// The description the user wrote, quoted when it falls short of the rule.
///
/// Public so a test can assert the line is absent by type — asserting on the
/// quotation marks would pass the day any other string on the card carries
/// one, and would never say the line itself went away. Same reasoning as
/// `PendingWebUploadCard`.
class RecordingDescriptionLine extends StatelessWidget {
  const RecordingDescriptionLine({super.key, required this.description});

  /// Already trimmed and non-empty — see `_visibleDescription`.
  final String description;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isShort = !isDescriptionSufficient(description);
    return Text(
      // Curly quotes, not ASCII ones: a description that itself contains `"`
      // rendered as `""oi""`, which reads as one confused string rather than
      // as the app quoting the user. They are not localized — fr wants « »
      // and zh 「」, but neither `intl` nor `flutter_localizations` exposes
      // CLDR's quotation marks, and eleven ARB keys buy too little.
      isShort ? '“$description”' : description,
      // Screen readers do not announce quotation marks at default verbosity,
      // and once a card has two or more open fields the chip only carries a
      // count, so nothing else would say this line is the deficient one.
      semanticsLabel: isShort
          ? '${AppLocalizations.of(context).recording_pendencyDescription}: '
                '$description'
          : null,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        fontSize: 12,
        color: colors.secondary.withValues(alpha: 0.85),
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _PendencyChip extends StatelessWidget {
  const _PendencyChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  static const double _iconSize = 11;
  static const double _iconGap = SpacingScale.s4;
  static const double _horizontalPadding = SpacingScale.s8;

  static TextStyle? _labelStyle(BuildContext context) =>
      Theme.of(context).textTheme.labelSmall?.copyWith(
        color: AppColors.of(context).secondary,
        fontWeight: FontWeight.w600,
      );

  /// Width the chip wants for [label] before anything squeezes it — what the
  /// footer compares the duration against.
  static double widthFor(BuildContext context, String label) =>
      _horizontalPadding * 2 +
      _iconSize +
      _iconGap +
      _textWidth(context, label, _labelStyle(context));

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: _horizontalPadding,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: colors.chipSurface,
        borderRadius: BorderRadius.circular(RadiusScale.r8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: _iconSize, color: colors.secondary),
          const SizedBox(width: _iconGap),
          Flexible(
            child: Text(
              label,
              style: _labelStyle(context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadProgressRow extends StatelessWidget {
  const _UploadProgressRow({required this.progress});

  final int progress;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: (progress / 100).clamp(0.0, 1.0),
              minHeight: 3,
              backgroundColor: colors.border.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation(colors.accent),
            ),
          ),
        ),
        const SizedBox(width: SpacingScale.s8),
        Text(
          '$progress%',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colors.accent,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _PausedWhileRecordingRow extends StatelessWidget {
  const _PausedWhileRecordingRow();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Row(
      children: [
        Icon(
          LucideIcons.pauseCircle,
          size: 12,
          color: colors.secondary.withValues(alpha: 0.7),
        ),
        const SizedBox(width: SpacingScale.s4),
        Flexible(
          child: Text(
            AppLocalizations.of(context).upload_pausedWhileRecording,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.secondary.withValues(alpha: 0.85),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
