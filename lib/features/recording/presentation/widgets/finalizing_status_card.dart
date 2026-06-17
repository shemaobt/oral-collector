import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/tokens.dart';
import '../notifiers/recording_session_state.dart';

/// Inline status card shown in place of the Pause/Stop controls while the
/// recording is being finalized.
///
/// Displays an upload icon, a static reassurance message, and the current
/// finalization stage. A thin indeterminate progress bar lives beneath the
/// card. Intentionally avoids a fake percentage — see design rationale notes.
class FinalizingStatusCard extends StatelessWidget {
  const FinalizingStatusCard({
    super.key,
    required this.stage,
    this.degraded = false,
  });

  final FinalizationStage stage;
  final bool degraded;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SpacingScale.s24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: colors.surfaceAlt,
              border: Border.all(color: colors.border.withValues(alpha: 0.55)),
              borderRadius: BorderRadius.circular(RadiusScale.r16),
            ),
            padding: const EdgeInsets.fromLTRB(
              SpacingScale.s16,
              SpacingScale.s16,
              SpacingScale.s16,
              SpacingScale.s16,
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colors.accent.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.uploadCloud,
                    size: 18,
                    color: colors.accent,
                  ),
                ),
                const SizedBox(width: SpacingScale.s16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.recording_processingYourAudio,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.foreground,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        degraded
                            ? l10n.recording_finalizationDegradedHint
                            : l10n.recording_dontCloseSaveNext,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: SpacingScale.s8),
                _StageLabel(stage: stage, color: colors.accent, theme: theme),
              ],
            ),
          ),
          const SizedBox(height: SpacingScale.s8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: SpacingScale.s4,
              child: LinearProgressIndicator(
                backgroundColor: colors.border.withValues(alpha: 0.45),
                valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StageLabel extends StatelessWidget {
  const _StageLabel({
    required this.stage,
    required this.color,
    required this.theme,
  });

  final FinalizationStage stage;
  final Color color;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final label = _shortStageLabel(AppLocalizations.of(context), stage);
    if (label.isEmpty) return const SizedBox.shrink();
    return Text(
      label,
      textAlign: TextAlign.right,
      style: theme.textTheme.labelSmall?.copyWith(
        color: color,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
      ),
    );
  }
}

String _shortStageLabel(AppLocalizations l10n, FinalizationStage stage) {
  switch (stage) {
    case FinalizationStage.finalizing:
      return l10n.recording_stageShortFinalizing;
    case FinalizationStage.combiningSegments:
      return l10n.recording_stageShortCombining;
    case FinalizationStage.compressingAudio:
      return l10n.recording_stageShortCompressing;
    case FinalizationStage.idle:
      return '';
  }
}
