import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/storyteller.dart';

class StorytellerTile extends StatelessWidget {
  final Storyteller storyteller;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool dense;

  const StorytellerTile({
    super.key,
    required this.storyteller,
    this.onTap,
    this.trailing,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final sexLabel = storyteller.sex == StorytellerSex.male
        ? l10n.storyteller_sexMale
        : l10n.storyteller_sexFemale;

    final parts = <String>[sexLabel];
    if (storyteller.age != null) {
      parts.add(l10n.storyteller_ageYearsShort(storyteller.age!));
    }
    final loc = (storyteller.location ?? '').trim();
    final dia = (storyteller.dialect ?? '').trim();
    if (loc.isNotEmpty) parts.add(loc);
    if (dia.isNotEmpty) parts.add(dia);

    final initial = storyteller.name.trim().isEmpty
        ? '?'
        : storyteller.name.trim().substring(0, 1).toUpperCase();

    return ListTile(
      dense: dense,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: colors.accent.withValues(alpha: 0.15),
        foregroundColor: colors.accent,
        child: Text(
          initial,
          style: theme.textTheme.titleMedium?.copyWith(
            color: colors.accent,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      title: Text(
        storyteller.name,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        parts.join(' · '),
        style: theme.textTheme.bodySmall?.copyWith(
          color: colors.foreground.withValues(alpha: 0.6),
        ),
      ),
      trailing:
          trailing ??
          (onTap != null
              ? Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: colors.foreground.withValues(alpha: 0.4),
                )
              : null),
      onTap: onTap,
    );
  }
}
