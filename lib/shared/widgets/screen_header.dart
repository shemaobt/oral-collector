import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class ScreenHeader extends StatelessWidget implements PreferredSizeWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.actions,
    this.showBackButton = false,
    this.bottom,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget>? actions;
  final bool showBackButton;
  final PreferredSizeWidget? bottom;

  static const double _toolbarHeight = 96;

  @override
  Size get preferredSize =>
      Size.fromHeight(_toolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppBar(
      toolbarHeight: _toolbarHeight,
      automaticallyImplyLeading: showBackButton,
      leading: showBackButton ? const BackButton() : null,
      centerTitle: false,
      titleSpacing: showBackButton ? 0 : 20,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      shape: const RoundedRectangleBorder(),
      title: _HeaderTitle(title: title, subtitle: subtitle),
      actions: [if (actions != null) ...actions!, const SizedBox(width: 8)],
      bottom: bottom,
      flexibleSpace: _HeaderBackground(
        icon: icon,
        colors: colors,
        isDark: isDark,
      ),
    );
  }
}

class ScreenHeaderSliver extends StatelessWidget {
  const ScreenHeaderSliver({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.actions,
    this.showBackButton = false,
    this.bottom,
    this.floating = true,
    this.snap = true,
    this.pinned = true,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget>? actions;
  final bool showBackButton;
  final PreferredSizeWidget? bottom;
  final bool floating;
  final bool snap;
  final bool pinned;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SliverAppBar(
      toolbarHeight: 96,
      floating: floating,
      snap: snap,
      pinned: pinned,
      centerTitle: false,
      automaticallyImplyLeading: showBackButton,
      leading: showBackButton ? const BackButton() : null,
      titleSpacing: showBackButton ? 0 : 20,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      shape: const RoundedRectangleBorder(),
      title: _HeaderTitle(title: title, subtitle: subtitle),
      actions: [if (actions != null) ...actions!, const SizedBox(width: 8)],
      bottom: bottom,
      flexibleSpace: _HeaderBackground(
        icon: icon,
        colors: colors,
        isDark: isDark,
      ),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(color: colors.secondary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _HeaderBackground extends StatelessWidget {
  const _HeaderBackground({
    required this.icon,
    required this.colors,
    required this.isDark,
  });

  final IconData icon;
  final AppColorSet colors;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final tinted = Color.lerp(
      colors.card,
      colors.accent,
      isDark ? 0.14 : 0.08,
    )!;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.65, 1.0],
          colors: [tinted, colors.card, colors.card],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            right: -6,
            bottom: 12,
            child: Icon(
              icon,
              size: 88,
              color: colors.accent.withValues(alpha: isDark ? 0.09 : 0.07),
            ),
          ),
        ],
      ),
    );
  }
}
