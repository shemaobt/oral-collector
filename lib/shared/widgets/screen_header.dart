import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'app_disc.dart';
import 'brush_sign.dart';
import 'pressable.dart';

const double _maxHeaderTextScale = 1.3;
const double _air = 6;
const double _rowHeight = 48;
const double _edge = 20;
const double _actionsGap = 10;
const double _titleGap = 10;
const double _titleLine = 40;
const double _backSign = 18;

class ScreenHeader extends StatelessWidget implements PreferredSizeWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.actions,
    this.onBack,
  });

  final String title;
  final List<Widget>? actions;
  final VoidCallback? onBack;

  @override
  Size get preferredSize => Size.fromHeight(_height(onBack != null));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: _height(onBack != null),
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      shape: const Border(),
      title: _ScreenTop(title: title, actions: actions, onBack: onBack),
    );
  }
}

class ScreenHeaderSliver extends StatelessWidget {
  const ScreenHeaderSliver({
    super.key,
    required this.title,
    this.actions,
    this.onBack,
    this.floating = true,
    this.snap = true,
    this.pinned = true,
  });

  final String title;
  final List<Widget>? actions;
  final VoidCallback? onBack;
  final bool floating;
  final bool snap;
  final bool pinned;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      toolbarHeight: _height(onBack != null),
      floating: floating,
      snap: snap,
      pinned: pinned,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      shape: const Border(),
      title: _ScreenTop(title: title, actions: actions, onBack: onBack),
    );
  }
}

double _height(bool back) =>
    _air + _rowHeight + (back ? _titleGap + _titleLine : 0);

class _ScreenTop extends StatelessWidget {
  const _ScreenTop({required this.title, this.actions, this.onBack});

  final String title;
  final List<Widget>? actions;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final back = onBack;
    final titleText = _HeaderTitle(title: title);
    final trailing = [
      for (final (i, action) in (actions ?? const <Widget>[]).indexed) ...[
        if (i > 0) const SizedBox(width: _actionsGap),
        action,
      ],
    ];

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: _maxHeaderTextScale,
      child: Padding(
        padding: const EdgeInsets.only(top: _air),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: _rowHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: _edge),
                child: Row(
                  children: [
                    if (back == null)
                      Expanded(child: titleText)
                    else ...[
                      _BackDisc(onTap: back),
                      const Spacer(),
                    ],
                    ...trailing,
                  ],
                ),
              ),
            ),
            if (back != null) ...[
              const SizedBox(height: _titleGap),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: _edge),
                child: SizedBox(height: _titleLine, child: titleText),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BackDisc extends StatelessWidget {
  const _BackDisc({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: MaterialLocalizations.of(context).backButtonTooltip,
      button: true,
      excludeSemantics: true,
      onTap: onTap,
      child: SizedBox.square(
        dimension: _rowHeight,
        child: Pressable(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: const Center(
            child: AppDisc(
              pressable: true,
              child: BrushSign(Sign.back, size: _backSign),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderTitle extends StatelessWidget {
  const _HeaderTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          title,
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            color: AppColors.of(context).foreground,
          ),
          maxLines: 1,
        ),
      ),
    );
  }
}
