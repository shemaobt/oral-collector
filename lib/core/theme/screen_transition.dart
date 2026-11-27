import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_motion.dart';
import 'context_tokens.dart';

abstract final class ScreenTransition {
  static const _apple = {TargetPlatform.iOS, TargetPlatform.macOS};

  static final PageTransitionsTheme phone = PageTransitionsTheme(
    builders: {
      for (final platform in TargetPlatform.values)
        platform: _apple.contains(platform)
            ? const CupertinoPageTransitionsBuilder()
            : const ScreenSlideTransitionsBuilder(),
    },
  );

  static final PageTransitionsTheme web = PageTransitionsTheme(
    builders: {
      for (final platform in TargetPlatform.values)
        platform: const ScreenFadeTransitionsBuilder(),
    },
  );

  static ThemeData pick(ThemeData theme, {required bool isWeb}) =>
      isWeb ? theme.copyWith(pageTransitionsTheme: web) : theme;
}

class ScreenSlideTransitionsBuilder extends _ScreenTransitionsBuilder {
  const ScreenSlideTransitionsBuilder() : super(slides: true);
}

class ScreenFadeTransitionsBuilder extends _ScreenTransitionsBuilder {
  const ScreenFadeTransitionsBuilder() : super(slides: false);
}

/// One controller of [MotionScale.base] serves both screens: what leaves takes
/// the first [MotionScale.fast] of the run, what arrives takes all of it.
abstract class _ScreenTransitionsBuilder extends PageTransitionsBuilder {
  const _ScreenTransitionsBuilder({required this.slides});

  final bool slides;

  @override
  Duration get transitionDuration => MotionScale.base;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return _Step(
      run: animation,
      isTop: true,
      slides: slides,
      child: ColoredBox(
        color: AppColors.of(context).background,
        child: _Step(
          run: secondaryAnimation,
          isTop: false,
          slides: slides,
          child: child,
        ),
      ),
    );
  }
}

class _Step extends StatefulWidget {
  const _Step({
    required this.run,
    required this.isTop,
    required this.slides,
    required this.child,
  });

  final Animation<double> run;
  final bool isTop;
  final bool slides;
  final Widget child;

  @override
  State<_Step> createState() => _StepState();
}

class _StepState extends State<_Step> {
  static final _leaveShare =
      MotionScale.fast.inMicroseconds / MotionScale.base.inMicroseconds;

  AnimationStatus? _direction;

  @override
  void initState() {
    super.initState();
    _latch(widget.run.status);
    widget.run.addStatusListener(_latch);
  }

  @override
  void didUpdateWidget(_Step oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.run == widget.run) return;
    oldWidget.run.removeStatusListener(_latch);
    _direction = null;
    _latch(widget.run.status);
    widget.run.addStatusListener(_latch);
  }

  @override
  void dispose() {
    widget.run.removeStatusListener(_latch);
    super.dispose();
  }

  void _latch(AnimationStatus status) {
    if (status.isCompleted || status.isDismissed) {
      _direction = null;
    } else {
      _direction ??= status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final still = context.motion.still;
    final side = Directionality.of(context) == TextDirection.rtl ? -1 : 1;
    final isTop = widget.isTop;
    return AnimatedBuilder(
      animation: widget.run,
      child: widget.child,
      builder: (context, child) {
        final backwards =
            (_direction ?? widget.run.status) == AnimationStatus.reverse;
        if (still) return isTop && backwards ? const SizedBox.shrink() : child!;
        final elapsed = backwards ? 1 - widget.run.value : widget.run.value;
        final shown = isTop != backwards
            ? MotionScale.enter.transform(elapsed)
            : 1 -
                  MotionScale.leave.transform(
                    math.min(elapsed / _leaveShare, 1),
                  );
        final away = widget.slides
            ? (isTop ? 1 : -1) * side * MotionScale.slide
            : 0.0;
        return Opacity(
          opacity: shown,
          child: Transform.translate(
            offset: Offset(away * (1 - shown), 0),
            child: child,
          ),
        );
      },
    );
  }
}
