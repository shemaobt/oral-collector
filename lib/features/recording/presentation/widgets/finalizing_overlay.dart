import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/tokens.dart';
import '../notifiers/recording_session_state.dart';

class FinalizingOverlay extends StatelessWidget {
  const FinalizingOverlay({
    super.key,
    required this.stage,
    required this.onDiscard,
    this.hasError = false,
    this.degraded = false,
    this.errorKind,
  });

  final FinalizationStage stage;
  final bool hasError;
  final bool degraded;

  /// Drives the body copy. Without it the screen falls back to the
  /// missing-segments wording, which is only true on the native path.
  final FinalizationErrorKind? errorKind;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final semanticsLabel = hasError
        ? '${l10n.recording_finalizationFailed}. ${_errorBody(l10n, errorKind)}'
        : _stageText(l10n, stage);

    return Semantics(
      container: true,
      liveRegion: true,
      label: semanticsLabel,
      child: SizedBox.expand(
        child: ColoredBox(
          color: colors.background,
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingScale.s32,
                ),
                child: hasError
                    ? _ErrorContent(
                        colors: colors,
                        theme: theme,
                        l10n: l10n,
                        errorKind: errorKind,
                        onDiscard: onDiscard,
                      )
                    : _ProgressContent(
                        colors: colors,
                        theme: theme,
                        l10n: l10n,
                        stage: stage,
                        degraded: degraded,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressContent extends StatelessWidget {
  const _ProgressContent({
    required this.colors,
    required this.theme,
    required this.l10n,
    required this.stage,
    required this.degraded,
  });

  final AppColorSet colors;
  final ThemeData theme;
  final AppLocalizations l10n;
  final FinalizationStage stage;
  final bool degraded;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: SpacingScale.s28,
          height: SpacingScale.s28,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: colors.accent,
          ),
        ),
        const SizedBox(height: SpacingScale.s20),
        Text(
          _stageText(l10n, stage),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(color: colors.foreground),
        ),
        if (degraded) ...[
          const SizedBox(height: SpacingScale.s8),
          Text(
            l10n.recording_finalizationDegradedHint,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: colors.secondary),
          ),
        ],
      ],
    );
  }
}

class _ErrorContent extends StatelessWidget {
  const _ErrorContent({
    required this.colors,
    required this.theme,
    required this.l10n,
    required this.errorKind,
    required this.onDiscard,
  });

  final AppColorSet colors;
  final ThemeData theme;
  final AppLocalizations l10n;
  final FinalizationErrorKind? errorKind;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(LucideIcons.alertTriangle, size: 40, color: colors.accent),
        const SizedBox(height: SpacingScale.s16),
        Text(
          l10n.recording_finalizationFailed,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            color: colors.foreground,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: SpacingScale.s8),
        Text(
          _errorBody(l10n, errorKind),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: colors.secondary),
        ),
        const SizedBox(height: SpacingScale.s24),
        FilledButton.tonal(
          onPressed: onDiscard,
          // Dismissing clears the error and nothing else — no audio is thrown
          // away here, so the button must not say it is.
          child: Text(l10n.recording_finalizationErrorBack),
        ),
      ],
    );
  }
}

String _errorBody(AppLocalizations l10n, FinalizationErrorKind? kind) {
  switch (kind) {
    case FinalizationErrorKind.noAudio:
      return l10n.recording_finalizationFailedBodyNoAudio;
    case FinalizationErrorKind.downloadFailed:
      return l10n.recording_finalizationFailedBodyDownload;
    case FinalizationErrorKind.captureInterrupted:
      return l10n.recording_finalizationFailedBodyCaptureInterrupted;
    case FinalizationErrorKind.finalizationFailed:
      return l10n.recording_finalizationFailedBodyPipeline;
    case FinalizationErrorKind.noSegments:
    case null:
      return l10n.recording_finalizationFailedBody;
  }
}

String _stageText(AppLocalizations l10n, FinalizationStage stage) {
  switch (stage) {
    case FinalizationStage.finalizing:
      return l10n.recording_finalizing;
    case FinalizationStage.combiningSegments:
      return l10n.recording_combiningSegments;
    case FinalizationStage.compressingAudio:
      return l10n.recording_compressingAudio;
    case FinalizationStage.idle:
      return '';
  }
}
