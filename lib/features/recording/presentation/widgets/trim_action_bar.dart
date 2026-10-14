import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../notifiers/trim_editor_state.dart';
import '../trim_edit_decision.dart';
import 'exclude_range_handles.dart';

class TrimActionBar extends StatelessWidget {
  const TrimActionBar({
    super.key,
    required this.state,
    required this.onCancel,
    required this.onSave,
    required this.onCancelRange,
    this.onConfirmRange,
  });

  final TrimEditorState state;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final VoidCallback onCancelRange;
  final VoidCallback? onConfirmRange;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final confirming = onConfirmRange != null;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(RadiusScale.r12),
    );
    const padding = EdgeInsets.symmetric(vertical: SpacingScale.s16);

    return Container(
      padding: const EdgeInsets.fromLTRB(
        SpacingScale.s16,
        SpacingScale.s12,
        SpacingScale.s16,
        SpacingScale.s16,
      ),
      decoration: BoxDecoration(
        color: colors.card,
        border: Border(
          top: BorderSide(color: colors.border.withValues(alpha: 0.15)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                key: confirming ? kExcludeRangeCancelKey : null,
                onPressed: confirming
                    ? onCancelRange
                    : (state.isSaving ? null : onCancel),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.foreground.withValues(
                    alpha: isDark ? 0.8 : 0.7,
                  ),
                  side: BorderSide(
                    color: colors.border.withValues(alpha: isDark ? 0.4 : 0.35),
                  ),
                  padding: padding,
                  shape: shape,
                ),
                child: Text(l10n.common_cancel),
              ),
            ),
            const SizedBox(width: SpacingScale.s12),
            Expanded(
              child: confirming
                  ? FilledButton(
                      key: kExcludeRangeConfirmKey,
                      onPressed: onConfirmRange,
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.accent,
                        foregroundColor: isDark
                            ? AppColors.black
                            : AppColors.white,
                        padding: padding,
                        shape: shape,
                      ),
                      child: Text(l10n.trim_excludeRange),
                    )
                  : _SaveButton(state: state, onSave: onSave),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.state, required this.onSave});

  final TrimEditorState state;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final boostOnly = state.decision.mode == TrimSaveMode.boostOnly;

    return ElevatedButton.icon(
      onPressed: (state.isSaving || !state.decision.canSave) ? null : onSave,
      icon: state.isSaving
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: isDark ? AppColors.black : AppColors.white,
              ),
            )
          : Icon(
              boostOnly ? LucideIcons.volume2 : LucideIcons.scissors,
              size: 16,
            ),
      label: Text(
        state.isSaving
            ? l10n.trim_splitting
            : boostOnly
            ? l10n.trim_applyBoost
            : l10n.trim_saveSegments(state.keptCount),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.accent,
        foregroundColor: isDark ? AppColors.black : AppColors.white,
        disabledBackgroundColor: colors.accent.withValues(alpha: 0.25),
        disabledForegroundColor: isDark
            ? AppColors.black.withValues(alpha: 0.3)
            : AppColors.white.withValues(alpha: 0.4),
        padding: const EdgeInsets.symmetric(vertical: SpacingScale.s16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusScale.r12),
        ),
        elevation: 0,
      ),
    );
  }
}
