import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/tokens.dart';

const double _headerHeight = 96;
const double _maxHeaderTextScale = 1.3;

class ScreenHeader extends StatelessWidget implements PreferredSizeWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.actions,
    this.showBackButton = false,
    this.bottom,
  });

  final String title;
  final String subtitle;
  final List<Widget>? actions;
  final bool showBackButton;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize =>
      Size.fromHeight(_headerHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: _headerHeight,
      automaticallyImplyLeading: showBackButton,
      leading: showBackButton ? const BackButton() : null,
      titleSpacing: showBackButton ? 0 : SpacingScale.s16,
      title: _HeaderTitle(title: title, subtitle: subtitle),
      actions: [
        if (actions != null) ...actions!,
        const SizedBox(width: SpacingScale.s8),
      ],
      bottom: bottom,
    );
  }
}

class ScreenHeaderSliver extends StatelessWidget {
  const ScreenHeaderSliver({
    super.key,
    required this.title,
    required this.subtitle,
    this.actions,
    this.showBackButton = false,
    this.bottom,
    this.floating = true,
    this.snap = true,
    this.pinned = true,
  });

  final String title;
  final String subtitle;
  final List<Widget>? actions;
  final bool showBackButton;
  final PreferredSizeWidget? bottom;
  final bool floating;
  final bool snap;
  final bool pinned;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      toolbarHeight: _headerHeight,
      floating: floating,
      snap: snap,
      pinned: pinned,
      automaticallyImplyLeading: showBackButton,
      leading: showBackButton ? const BackButton() : null,
      titleSpacing: showBackButton ? 0 : SpacingScale.s16,
      title: _HeaderTitle(title: title, subtitle: subtitle),
      actions: [
        if (actions != null) ...actions!,
        const SizedBox(width: SpacingScale.s8),
      ],
      bottom: bottom,
    );
  }
}

class _HeaderTitle extends StatelessWidget {
  const _HeaderTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: _maxHeaderTextScale,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: theme.textTheme.displayMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: SpacingScale.s8),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.secondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
