import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/tokens.dart';
import '../../domain/entities/local_recording_entity.dart';
import 'recording_about_section.dart';

/// Title + classification block of the detail screen: the about section, the
/// primary genre breadcrumb, the register row, the "also classified as"
/// secondary card (with edit/clear), the add-alternative affordance, and the
/// split-origin indicator. Extracted from recording_detail_screen's build()
/// (ENG-194 PR-B); the parent computes the breadcrumb strings and passes them.
class RecordingClassificationSection extends StatelessWidget {
  const RecordingClassificationSection({
    super.key,
    required this.recording,
    required this.theme,
    required this.colors,
    required this.genreBreadcrumb,
    required this.registerName,
    required this.isUnclassified,
    required this.hasSecondary,
    required this.secondaryBreadcrumb,
    required this.secondaryRegisterName,
    required this.canEdit,
    required this.onEditDetails,
    required this.onEditSecondary,
    required this.onClearSecondary,
  });

  final LocalRecordingEntity recording;
  final ThemeData theme;
  final AppColorSet colors;
  final String genreBreadcrumb;
  final String? registerName;
  final bool isUnclassified;
  final bool hasSecondary;
  final String secondaryBreadcrumb;
  final String? secondaryRegisterName;
  final bool canEdit;
  final VoidCallback onEditDetails;
  final VoidCallback onEditSecondary;
  final VoidCallback onClearSecondary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        RecordingAboutSection(
          theme: theme,
          colors: colors,
          title: recording.title,
          description: recording.description,
          canEdit: canEdit,
          onEdit: onEditDetails,
        ),
        const SizedBox(height: SpacingScale.s16),
        Row(
          children: [
            Icon(
              isUnclassified ? LucideIcons.tag : LucideIcons.layers,
              size: 14,
              color: isUnclassified ? colors.warning : colors.accent,
            ),
            const SizedBox(width: SpacingScale.s8),
            Flexible(
              child: Text(
                genreBreadcrumb,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isUnclassified ? colors.warning : colors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        if (registerName != null) ...[
          const SizedBox(height: SpacingScale.s4),
          Row(
            children: [
              Icon(LucideIcons.volume2, size: 14, color: colors.secondary),
              const SizedBox(width: SpacingScale.s8),
              Flexible(
                child: Text(
                  registerName!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.secondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
        if (!isUnclassified && hasSecondary) ...[
          const SizedBox(height: SpacingScale.s8),
          Material(
            color: AppColors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(RadiusScale.r8),
              side: BorderSide(
                color: colors.foreground.withValues(alpha: 0.18),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: canEdit ? onEditSecondary : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingScale.s8,
                  vertical: SpacingScale.s8,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.layers,
                      size: 13,
                      color: colors.foreground.withValues(alpha: 0.55),
                    ),
                    const SizedBox(width: SpacingScale.s8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.recording_alsoClassifiedAs,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colors.foreground.withValues(alpha: 0.55),
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (secondaryBreadcrumb.isNotEmpty)
                            Text(
                              secondaryBreadcrumb,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.foreground.withValues(
                                  alpha: 0.85,
                                ),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          if (secondaryRegisterName != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Row(
                                children: [
                                  Icon(
                                    LucideIcons.volume2,
                                    size: 11,
                                    color: colors.foreground.withValues(
                                      alpha: 0.55,
                                    ),
                                  ),
                                  const SizedBox(width: SpacingScale.s4),
                                  Flexible(
                                    child: Text(
                                      secondaryRegisterName!,
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: colors.foreground.withValues(
                                              alpha: 0.65,
                                            ),
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (canEdit)
                      IconButton(
                        icon: const Icon(LucideIcons.x, size: 14),
                        tooltip: l10n.recording_removeSecondary,
                        color: colors.foreground.withValues(alpha: 0.6),
                        onPressed: onClearSecondary,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
        if (!isUnclassified && !hasSecondary && canEdit) ...[
          const SizedBox(height: SpacingScale.s8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onEditSecondary,
              icon: const Icon(LucideIcons.plus, size: 14),
              label: Text(l10n.recording_addAlternative),
              style: TextButton.styleFrom(
                foregroundColor: colors.foreground.withValues(alpha: 0.65),
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingScale.s8,
                  vertical: SpacingScale.s4,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: theme.textTheme.labelSmall,
              ),
            ),
          ),
        ],
        if (recording.splitFromId != null) ...[
          const SizedBox(height: SpacingScale.s8),
          Row(
            children: [
              Icon(
                LucideIcons.scissors,
                size: 13,
                color: colors.foreground.withValues(alpha: 0.55),
              ),
              const SizedBox(width: SpacingScale.s8),
              Flexible(
                child: Text(
                  (recording.splitIndex != null &&
                          recording.splitSegmentCount != null)
                      ? l10n.recording_partOf(
                          recording.splitIndex! + 1,
                          recording.splitSegmentCount!,
                        )
                      : l10n.recording_splitFrom(recording.splitFromId ?? ''),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.foreground.withValues(alpha: 0.65),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
