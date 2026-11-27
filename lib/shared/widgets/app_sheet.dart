import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/context_tokens.dart';

const double _corner = 26;
const double _grabTop = 10;
const Size _grab = Size(36, 5);

Future<T?> showAppSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isDismissible = true,
  bool isScrollControlled = false,
  bool useSafeArea = false,
  bool useRootNavigator = false,
  BoxConstraints? constraints,
}) {
  final NavigatorState navigator = Navigator.of(
    context,
    rootNavigator: useRootNavigator,
  );
  return navigator.push(
    _AppSheetRoute<T>(
      builder: builder,
      motion: context.motion,
      themes: InheritedTheme.capture(from: context, to: navigator.context),
      barrierLabel: MaterialLocalizations.of(context).scrimLabel,
      isDismissible: isDismissible,
      isScrollControlled: isScrollControlled,
      useSafeArea: useSafeArea,
      constraints: constraints,
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
    required this.constraints,
  });

  final WidgetBuilder builder;
  final AppMotion motion;
  final CapturedThemes themes;
  final bool isDismissible;
  final bool isScrollControlled;
  final bool useSafeArea;
  final BoxConstraints? constraints;

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
    return themes.wrap(
      _AppSheetBody(
        route: this,
        child: Builder(builder: builder),
      ),
    );
  }
}

class _AppSheetBody extends StatefulWidget {
  const _AppSheetBody({required this.route, required this.child});

  final _AppSheetRoute<dynamic> route;
  final Widget child;

  @override
  State<_AppSheetBody> createState() => _AppSheetBodyState();
}

class _AppSheetBodyState extends State<_AppSheetBody> {
  Curve? _held;

  _AppSheetRoute<dynamic> get _route => widget.route;

  bool get _leaving => _route.animation!.status == AnimationStatus.reverse;

  @override
  Widget build(BuildContext context) {
    final AppColorSet colors = AppColors.of(context);
    final AppMotion motion = _route.motion;
    final double ratio = _route.isScrollControlled ? 1 : 9 / 16;
    final Widget sheet = BottomSheet(
      animationController: _route.drag,
      onClosing: () {
        if (_route.isCurrent) Navigator.pop(context);
      },
      enableDrag: _route.isDismissible,
      backgroundColor: colors.card,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      constraints: _route.constraints,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(_corner)),
      ),
      onDragStart: (_) => _held = Curves.linear,
      onDragEnd: (_, {bool? isClosing}) =>
          _held = Split(_route.animation!.value, endCurve: motion.enter),
      builder: (context) => Stack(
        children: [
          _route.builder(context),
          Positioned(
            top: _grabTop,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox.fromSize(
                size: _grab,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.sand,
                    borderRadius: BorderRadius.circular(3),
                  ),
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
          final Curve rise =
              _held ??
              (_leaving ? motion.leave.flipped : MotionScale.sheetRise);
          final Curve fade = _leaving ? motion.leave.flipped : motion.enter;
          return Stack(
            fit: StackFit.expand,
            children: [
              IgnorePointer(
                child: Opacity(
                  opacity: fade.transform(v),
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
                      translation: Offset(0, 1 - rise.transform(v)),
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
