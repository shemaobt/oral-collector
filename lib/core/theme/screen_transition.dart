import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_motion.dart';

/// How a screen arrives and leaves: the phone's map and the web's map.
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

class _Step extends StatelessWidget {
  const _Step({
    required this.run,
    required this.isTop,
    required this.slides,
    required this.child,
  });

  static final _leaveShare =
      MotionScale.fast.inMicroseconds / MotionScale.base.inMicroseconds;

  final Animation<double> run;
  final bool isTop;
  final bool slides;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    final side = Directionality.of(context) == TextDirection.rtl ? -1 : 1;
    return AnimatedBuilder(
      animation: run,
      child: child,
      builder: (context, child) {
        final backwards = run.status == AnimationStatus.reverse;
        if (still) return isTop && backwards ? const SizedBox.shrink() : child!;
        final elapsed = backwards ? 1 - run.value : run.value;
        final shown = isTop != backwards
            ? MotionScale.enter.transform(elapsed)
            : 1 -
                  MotionScale.leave.transform(
                    math.min(elapsed / _leaveShare, 1),
                  );
        final away = slides ? (isTop ? 1 : -1) * side * MotionScale.slide : 0.0;
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
