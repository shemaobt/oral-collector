import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/context_tokens.dart';

const double _corner = 26;
const double _grabTop = 10;

Future<T?> showAppSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isDismissible = true,
  bool isScrollControlled = false,
  bool useSafeArea = false,
}) {
  final NavigatorState navigator = Navigator.of(context);
  return navigator.push(
    _AppSheetRoute<T>(
      builder: builder,
      motion: context.motion,
      themes: InheritedTheme.capture(from: context, to: navigator.context),
      barrierLabel: MaterialLocalizations.of(context).scrimLabel,
      isDismissible: isDismissible,
      isScrollControlled: isScrollControlled,
      useSafeArea: useSafeArea,
    ),
  );
}

class _AppSheetRoute<T> extends PopupRoute<T> {
  _AppSheetRoute({
    required this.builder,
    required this.motion,
    required this.themes,
    required this.barrierLabel,
    required this.isDismissible,
    required this.isScrollControlled,
    required this.useSafeArea,
  });

  final WidgetBuilder builder;
  final AppMotion motion;
  final CapturedThemes themes;
  final bool isDismissible;
  final bool isScrollControlled;
  final bool useSafeArea;

  @override
  final String barrierLabel;

  AnimationController get drag => controller!;

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => isDismissible;

  @override
  Duration get transitionDuration => motion.slow;

  @override
  Duration get reverseTransitionDuration => motion.base;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return themes.wrap(_AppSheetBody(route: this));
  }
}

class _AppSheetBody extends StatefulWidget {
  const _AppSheetBody({required this.route});

  final _AppSheetRoute<dynamic> route;

  @override
  State<_AppSheetBody> createState() => _AppSheetBodyState();
}

typedef _Run = ({Curve rise, Curve fade});

class _AppSheetBodyState extends State<_AppSheetBody> {
  _Run? _run;
  bool _dragging = false;

  _AppSheetRoute<dynamic> get _route => widget.route;

  late final _Run _enter = (
    rise: MotionScale.sheetRise,
    fade: _route.motion.enter,
  );
  late final _Run _leave = (
    rise: _route.motion.leave.flipped,
    fade: _route.motion.leave.flipped,
  );

  @override
  Widget build(BuildContext context) {
    final AppColorSet colors = AppColors.of(context);
    final AppMotion motion = _route.motion;
    final double ratio = _route.isScrollControlled ? 1 : 9 / 16;
    final Widget sheet = BottomSheet(
      animationController: _route.drag,
      onClosing: () {
        if (_route.isCurrent && _route.isDismissible) Navigator.pop(context);
      },
      enableDrag: _route.isDismissible,
      backgroundColor: colors.card,
      elevation: 0,
      showDragHandle: false,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(_corner)),
      ),
      onDragStart: (_) {
        final double shown = (_run ?? _enter).rise.transform(_route.drag.value);
        _dragging = true;
        _run = (rise: Curves.linear, fade: motion.enter);
        _route.drag.value = shown.clamp(0.0, 1.0);
      },
      onDragEnd: (_, {bool? isClosing}) {
        _dragging = false;
        _run = (
          rise: Split(_route.drag.value, endCurve: motion.enter),
          fade: isClosing == true ? _leave.fade : motion.enter,
        );
      },
      builder: (context) => Stack(
        children: [
          _route.builder(context),
          Positioned(
            top: _grabTop,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: colors.sand,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    final Widget sized = ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * ratio,
      ),
      child: SizedBox(width: double.infinity, child: sheet),
    );
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      child: AnimatedBuilder(
        animation: _route.animation!,
        child: sized,
        builder: (context, child) {
          final double v = _route.animation!.value;
          final AnimationStatus status = _route.animation!.status;
          _run = status.isAnimating || _dragging
              ? _run ?? (status == AnimationStatus.reverse ? _leave : _enter)
              : null;
          final _Run run = _run ?? _enter;
          return Stack(
            fit: StackFit.expand,
            children: [
              IgnorePointer(
                child: Opacity(
                  opacity: run.fade.transform(v),
                  child: const ColoredBox(color: MotionScale.scrim),
                ),
              ),
              MediaQuery.removePadding(
                context: context,
                removeTop: !_route.useSafeArea,
                child: SafeArea(
                  top: _route.useSafeArea,
                  bottom: false,
                  left: _route.useSafeArea,
                  right: _route.useSafeArea,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionalTranslation(
                      translation: Offset(0, 1 - run.rise.transform(v)),
                      child: child,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
