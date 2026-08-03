import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/review_pendency.dart';

/// The guided list of what a recording still owes (ENG-374).
///
/// Steps are never removed once resolved: a row disappearing under the user's
/// finger costs them their place in the list. They stay, marked done, so the
/// progress is the point.
class CompleteFichaSheet extends StatelessWidget {
  const CompleteFichaSheet({
    super.key,
    required this.steps,
    required this.resolved,
    required this.onStep,
  });

  /// The sheet's primary action, which jumps to the first unfinished step.
  static const Key ctaKey = Key('complete_ficha_cta');

  final List<PendencyKind> steps;
  final Set<PendencyKind> resolved;
  final void Function(PendencyKind) onStep;

  PendencyKind? get _firstOpenStep {
    for (final step in steps) {
      if (!resolved.contains(step)) return step;
    }
    return null;
  }

  int get _openCount => steps.where((s) => !resolved.contains(s)).length;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final nextStep = _firstOpenStep;
    final openCount = _openCount;

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(RadiusScale.r20),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: SpacingScale.s8),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // The steps scroll and the action does not: under a large system
            // font the list alone can outgrow the screen, and an action that
            // scrolls with it ends up below the bottom edge with nothing left
            // to scroll it back into view.
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  SpacingScale.s20,
                  SpacingScale.s20,
                  SpacingScale.s20,
                  0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.recording_completeFichaTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    // Nothing open means nothing to count; the ticked-off list
                    // says the rest.
                    if (openCount > 0) ...[
                      const SizedBox(height: SpacingScale.s4),
                      Text(
                        l10n.recording_completeFichaSubtitle(openCount),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.foreground.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                    const SizedBox(height: SpacingScale.s16),
                    for (var i = 0; i < steps.length; i++)
                      CompleteFichaStepTile(
                        kind: steps[i],
                        position: i + 1,
                        done: resolved.contains(steps[i]),
                        onTap: () => onStep(steps[i]),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(SpacingScale.s20),
              child: _Cta(
                label: resolved.isEmpty
                    ? l10n.recording_completeFichaStart
                    : l10n.recording_completeFichaContinue,
                onTap: nextStep == null ? null : () => onStep(nextStep),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One step of the guided flow: what is open, why it matters, and a way in.
class CompleteFichaStepTile extends StatelessWidget {
  const CompleteFichaStepTile({
    super.key,
    required this.kind,
    required this.position,
    required this.done,
    required this.onTap,
  });

  final PendencyKind kind;

  /// 1-based number drawn in the leading circle.
  final int position;

  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(RadiusScale.r12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: SpacingScale.s8),
          child: Row(
            children: [
              _StepMarker(position: position, done: done),
              const SizedBox(width: SpacingScale.s12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _title(l10n, kind),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _context(l10n, kind),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.foreground.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: SpacingScale.s8),
              Icon(LucideIcons.chevronRight, size: 16, color: colors.border),
            ],
          ),
        ),
      ),
    );
  }

  static String _title(AppLocalizations l10n, PendencyKind kind) =>
      switch (kind) {
        PendencyKind.classification => l10n.recording_pendencyClassification,
        PendencyKind.description => l10n.recording_pendencyDescription,
        PendencyKind.storyteller => l10n.recording_pendencyStoryteller,
      };

  static String _context(AppLocalizations l10n, PendencyKind kind) =>
      switch (kind) {
        PendencyKind.classification =>
          l10n.recording_pendencyClassificationContext,
        PendencyKind.description => l10n.recording_pendencyDescriptionContext,
        PendencyKind.storyteller => l10n.recording_pendencyStorytellerContext,
      };
}

class _StepMarker extends StatelessWidget {
  const _StepMarker({required this.position, required this.done});

  final int position;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final theme = Theme.of(context);

    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: done ? colors.primary : null,
        shape: BoxShape.circle,
        border: Border.all(color: colors.primary, width: 1.5),
      ),
      child: done
          ? Icon(LucideIcons.check, size: 16, color: colors.onPrimary)
          : Text(
              '$position',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }
}

class _Cta extends StatelessWidget {
  const _Cta({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return SizedBox(
      height: 48,
      child: FilledButton(
        key: CompleteFichaSheet.ctaKey,
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RadiusScale.r12),
          ),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}
