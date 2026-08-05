import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../project/presentation/notifiers/member_notifier.dart';
import '../../../storyteller/domain/entities/storyteller.dart';
import '../../../user/data/user_lookup_provider.dart';

class RecordingStorytellerSection extends ConsumerWidget {
  final String? storytellerId;
  final String? userId;
  final Storyteller? resolvedStoryteller;
  final bool canEdit;

  /// Opens the storyteller picker. Owned by the screen so the guided completion
  /// flow can assign a storyteller without going through this section.
  final VoidCallback? onEditStoryteller;

  const RecordingStorytellerSection({
    super.key,
    required this.storytellerId,
    required this.userId,
    required this.resolvedStoryteller,
    required this.canEdit,
    required this.onEditStoryteller,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);
    final theme = Theme.of(context);

    final memberState = ref.watch(memberNotifierProvider);
    final author = userId == null
        ? null
        : memberState.members.where((m) => m.userId == userId).firstOrNull;

    final lookupAsync = (userId != null && author == null)
        ? ref.watch(userLookupProvider(userId!))
        : null;
    final fallbackLookup = lookupAsync?.asData?.value;

    final authorLabel = userId == null
        ? l10n.recording_unknownUser
        : author != null
        ? (author.displayName ?? author.email)
        : fallbackLookup?.label ?? l10n.recording_unknownUser;

    Widget buildStorytellerBody() {
      if (storytellerId == null) {
        return Row(
          children: [
            Icon(LucideIcons.userMinus, size: 18, color: colors.secondary),
            const SizedBox(width: SpacingScale.s8),
            Expanded(
              child: Text(
                l10n.storyteller_noneAssigned,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.secondary,
                ),
              ),
            ),
            if (canEdit)
              TextButton(
                onPressed: onEditStoryteller,
                child: Text(l10n.storyteller_assign),
              ),
          ],
        );
      }

      if (resolvedStoryteller == null) {
        return Row(
          children: [
            Icon(LucideIcons.userX, size: 18, color: colors.error),
            const SizedBox(width: SpacingScale.s8),
            Expanded(
              child: Text(
                l10n.storyteller_unknown,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.error,
                ),
              ),
            ),
            if (canEdit)
              TextButton(
                onPressed: onEditStoryteller,
                child: Text(l10n.storyteller_reassign),
              ),
          ],
        );
      }

      final st = resolvedStoryteller!;
      final sexLabel = switch (st.sex) {
        StorytellerSex.male => l10n.storyteller_sexMale,
        StorytellerSex.female => l10n.storyteller_sexFemale,
        StorytellerSex.unknown => '—',
      };
      final parts = <String>[sexLabel];
      if (st.age != null) parts.add(l10n.storyteller_ageYearsShort(st.age!));
      final loc = (st.location ?? '').trim();
      final dia = (st.dialect ?? '').trim();
      if (loc.isNotEmpty) parts.add(loc);
      if (dia.isNotEmpty) parts.add(dia);

      return InkWell(
        onTap: canEdit ? onEditStoryteller : null,
        borderRadius: BorderRadius.circular(RadiusScale.r8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: SpacingScale.s4),
          child: Row(
            children: [
              Icon(LucideIcons.user, size: 18, color: colors.accent),
              const SizedBox(width: SpacingScale.s8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      st.name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      parts.join(' · '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.foreground.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (canEdit)
                Icon(
                  LucideIcons.edit2,
                  size: 16,
                  color: colors.foreground.withValues(alpha: 0.4),
                ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(SpacingScale.s16),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(RadiusScale.r12),
        border: Border.all(color: colors.border.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.detail_storyteller,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.foreground.withValues(alpha: 0.6),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: SpacingScale.s8),
          buildStorytellerBody(),
          const SizedBox(height: SpacingScale.s16),
          Divider(height: 1, color: colors.border.withValues(alpha: 0.35)),
          const SizedBox(height: SpacingScale.s16),
          Text(
            l10n.detail_recordedBy,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.foreground.withValues(alpha: 0.6),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: SpacingScale.s8),
          Row(
            children: [
              Icon(LucideIcons.mic, size: 18, color: colors.secondary),
              const SizedBox(width: SpacingScale.s8),
              Expanded(
                child: Text(
                  authorLabel,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
