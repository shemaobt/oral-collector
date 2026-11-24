import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/tokens.dart';
import '../../../l10n/app_localizations.dart';
import 'tab_item.dart';

class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabTapped,
    required this.colors,
    required this.pendingInvites,
    required this.bottomPadding,
  });

  final List<TabItem> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabTapped;
  final AppColorSet colors;
  final int pendingInvites;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        SpacingScale.s16,
        SpacingScale.s8,
        SpacingScale.s16,
        bottomPadding > 16 ? bottomPadding - 16 : 2,
      ),
      child: Container(
        height: 70,
        padding: const EdgeInsets.all(SpacingScale.s8),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(RadiusScale.r32),
          border: Border.all(color: colors.border, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: isDark ? 0.30 : 0.10),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final totalWidth = constraints.maxWidth;
            const spacing = 4.0;
            final count = tabs.length;
            final totalSpacing = spacing * (count - 1);
            final usableWidth = totalWidth - totalSpacing;

            final unselectedWidth = usableWidth / (count + 1);
            final selectedWidth = unselectedWidth * 2;

            return Row(
              children: List.generate(count, (i) {
                final isSelected = i == selectedIndex;
                final tab = tabs[i];
                final hasBadge = tab.path == '/profile' && pendingInvites > 0;

                return Padding(
                  padding: EdgeInsets.only(right: i < count - 1 ? spacing : 0),
                  child: Semantics(
                    label: AppLocalizations.of(
                      context,
                    ).a11y_tabLabel(tab.label),
                    selected: isSelected,
                    child: Material(
                      color: AppColors.transparent,
                      child: InkWell(
                        onTap: () => onTabTapped(i),
                        borderRadius: BorderRadius.circular(RadiusScale.r24),
                        child: AnimatedContainer(
                          duration: DurationScale.ms300,
                          curve: Curves.easeInOut,
                          width: isSelected ? selectedWidth : unselectedWidth,
                          height: 54,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colors.surfaceAlt
                                : AppColors.transparent,
                            borderRadius: BorderRadius.circular(
                              RadiusScale.r24,
                            ),
                          ),
                          child: _NavItemContent(
                            icon: tab.icon,
                            label: tab.label,
                            isSelected: isSelected,
                            iconColor: colors.secondary,
                            selectedColor: colors.primary,
                            hasBadge: hasBadge,
                            badgeCount: pendingInvites,
                            accentColor: colors.accent,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}

class _NavItemContent extends StatelessWidget {
  const _NavItemContent({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.iconColor,
    required this.selectedColor,
    required this.hasBadge,
    required this.badgeCount,
    required this.accentColor,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final Color iconColor;
  final Color selectedColor;
  final bool hasBadge;
  final int badgeCount;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconWidget = Icon(
      icon,
      size: 20,
      color: isSelected ? selectedColor : iconColor,
    );

    final displayIcon = hasBadge
        ? Badge(
            label: Text(
              '$badgeCount',
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                color: theme.colorScheme.onPrimary,
              ),
            ),
            backgroundColor: accentColor,
            child: iconWidget,
          )
        : iconWidget;

    return AnimatedSwitcher(
      duration: DurationScale.ms200,
      switchInCurve: Curves.easeIn,
      switchOutCurve: Curves.easeOut,
      child: isSelected
          ? Row(
              key: const ValueKey(true),
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                displayIcon,
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: selectedColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            )
          : Center(key: const ValueKey(false), child: displayIcon),
    );
  }
}
