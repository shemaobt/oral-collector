import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'brush_sign.dart';
import 'round_button.dart';

const double _maxHeaderTextScale = 1.3;
const double _air = 6;
const double _rowHeight = 48;
const double _edge = 20;
const double _discInset = 2;
const double _actionsGap = 10;
const double _titleGap = 10;

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
  Size get preferredSize =>
      Size.fromHeight(_height(_platformScaler(), onBack != null));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: _height(_platformScaler(), onBack != null),
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
      toolbarHeight: _height(MediaQuery.textScalerOf(context), onBack != null),
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

TextScaler _platformScaler() => TextScaler.linear(
  WidgetsBinding.instance.platformDispatcher.textScaleFactor,
);

double _titleLine(TextScaler scaler) {
  const line = AppTheme.titleSize * AppTheme.titleHeight;
  return math.min(scaler.scale(line), line * _maxHeaderTextScale);
}

double _height(TextScaler scaler, bool back) {
  final line = _titleLine(scaler);
  return _air +
      (back ? _rowHeight + _titleGap + line : math.max(_rowHeight, line));
}

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
        Semantics(container: true, child: action),
      ],
    ];

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: _maxHeaderTextScale,
      child: Padding(
        padding: const EdgeInsets.only(top: _air),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: _rowHeight),
              child: Padding(
                padding: EdgeInsetsDirectional.only(
                  start: back == null ? _edge : _edge - _discInset,
                  end: _edge,
                ),
                child: Row(
                  children: [
                    if (back == null)
                      Expanded(child: titleText)
                    else ...[
                      Semantics(
                        container: true,
                        child: RoundButton.sign(
                          sign: Sign.back,
                          semanticLabel: MaterialLocalizations.of(
                            context,
                          ).backButtonTooltip,
                          onPressed: back,
                          size: RoundButtonSize.small,
                          tone: RoundButtonTone.resting,
                        ),
                      ),
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
                child: titleText,
              ),
            ],
          ],
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
    return Text(
      title,
      style: Theme.of(context).textTheme.displayMedium?.copyWith(
        color: AppColors.of(context).foreground,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
