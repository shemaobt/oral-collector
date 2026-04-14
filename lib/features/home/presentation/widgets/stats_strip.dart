import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/format.dart';
import '../../../../../l10n/app_localizations.dart';

class StatsStrip extends StatelessWidget {
  const StatsStrip({
    super.key,
    required this.totalRecordings,
    required this.totalDuration,
    required this.memberCount,
    required this.colors,
    this.storytellerCount = 0,
    this.unclassifiedCount = 0,
  });

  final int totalRecordings;
  final double totalDuration;
  final int memberCount;
  final AppColorSet colors;
  final int storytellerCount;
  final int unclassifiedCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final tiles = <_StatTileData>[
      _StatTileData(
        value: '$totalRecordings',
        label: l10n.stats_recordings,
        icon: LucideIcons.mic,
        color: colors.accent,
      ),
      _StatTileData(
        value: formatDurationCompact(totalDuration),
        label: l10n.stats_recorded,
        icon: LucideIcons.clock,
        color: colors.success,
      ),
      _StatTileData(
        value: '$memberCount',
        label: l10n.stats_members,
        icon: LucideIcons.users,
        color: colors.info,
      ),
      _StatTileData(
        value: '$storytellerCount',
        label: l10n.storyteller_title,
        icon: LucideIcons.userCheck,
        color: colors.secondary,
      ),
      if (unclassifiedCount > 0)
        _StatTileData(
          value: '$unclassifiedCount',
          label: l10n.filter_unclassified,
          icon: LucideIcons.tag,
          color: Colors.amber.shade700,
        ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const spacing = 10.0;
          final width = constraints.maxWidth;
          final columns = width < 420 ? 3 : (width < 640 ? 4 : 5);
          final tileWidth = (width - spacing * (columns - 1)) / columns;
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: tiles
                .map(
                  (t) => SizedBox(
                    width: tileWidth,
                    child: _StatTile(data: t, isDark: isDark, colors: colors),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}

class _StatTileData {
  const _StatTileData({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.data,
    required this.isDark,
    required this.colors,
  });

  final _StatTileData data;
  final bool isDark;
  final AppColorSet colors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: isDark
            ? colors.foreground.withValues(alpha: 0.05)
            : colors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: isDark
            ? null
            : Border.all(color: colors.border.withValues(alpha: 0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(data.icon, size: 16, color: data.color),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              data.value,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: data.color,
                height: 1.1,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.secondary,
              fontWeight: FontWeight.w500,
              fontSize: 11,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
