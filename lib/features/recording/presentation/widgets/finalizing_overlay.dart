import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../notifiers/recording_session_state.dart';

class FinalizingOverlay extends StatelessWidget {
  const FinalizingOverlay({
    super.key,
    required this.stage,
    required this.onDiscard,
    this.error,
    this.degraded = false,
  });

  final FinalizationStage stage;
  final String? error;
  final bool degraded;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final semanticsLabel = error != null
        ? '${l10n.recording_finalizationFailed}. ${l10n.recording_finalizationFailedBody}'
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
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: error != null
                    ? _ErrorContent(
                        colors: colors,
                        theme: theme,
                        l10n: l10n,
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
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: colors.accent,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          _stageText(l10n, stage),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(color: colors.foreground),
        ),
        if (degraded) ...[
          const SizedBox(height: 8),
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
    required this.onDiscard,
  });

  final AppColorSet colors;
  final ThemeData theme;
  final AppLocalizations l10n;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(LucideIcons.alertTriangle, size: 40, color: colors.accent),
        const SizedBox(height: 16),
        Text(
          l10n.recording_finalizationFailed,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            color: colors.foreground,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.recording_finalizationFailedBody,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: colors.secondary),
        ),
        const SizedBox(height: 24),
        FilledButton.tonal(
          onPressed: onDiscard,
          child: Text(l10n.recording_discardAndReturn),
        ),
      ],
    );
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
