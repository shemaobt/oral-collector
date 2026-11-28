import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/context_tokens.dart';

class PressLook extends StatefulWidget {
  const PressLook({super.key, required this.down, required this.child});

  final bool down;
  final Widget child;

  @override
  State<PressLook> createState() => _PressLookState();
}

class _PressLookState extends State<PressLook>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController.unbounded(
    vsync: this,
  );
  final GlobalKey _childKey = GlobalKey();

  @override
  void didUpdateWidget(covariant PressLook oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.down == widget.down) return;
    final motion = context.motion;
    if (motion.still) {
      _press.value = widget.down ? 1 : 0;
    } else if (widget.down) {
      _press.animateTo(1, duration: motion.pressIn, curve: motion.enter);
    } else {
      _press.animateTo(0, duration: motion.pressOut, curve: motion.pressBack);
    }
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final motion = context.motion;
    final dip = 1 - motion.pressScale;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _press,
        child: KeyedSubtree(key: _childKey, child: widget.child),
        builder: (context, child) {
          final press = _press.value;
          final tint = 1 - dip * math.max(press, 0);
          return Transform.scale(
            scale: motion.still ? 1 : 1 - dip * press,
            child: tint == 1
                ? child
                : ColorFiltered(
                    colorFilter: ColorFilter.matrix(<double>[
                      tint, 0, 0, 0, 0, //
                      0, tint, 0, 0, 0, //
                      0, 0, tint, 0, 0, //
                      0, 0, 0, 1, 0,
                    ]),
                    child: child,
                  ),
          );
        },
      ),
    );
  }
}

Widget pressLookBackground(
  BuildContext context,
  Set<WidgetState> states,
  Widget? child,
) => PointerPress(
  builder: (context, down) => PressLook(
    down:
        (down || states.contains(WidgetState.pressed)) &&
        !states.contains(WidgetState.disabled),
    child: child!,
  ),
);

class PointerPress extends StatefulWidget {
  const PointerPress({super.key, required this.builder});

  final Widget Function(BuildContext context, bool down) builder;

  @override
  State<PointerPress> createState() => _PointerPressState();
}

class _PointerPressState extends State<PointerPress> {
  bool _down = false;
  Offset _origin = Offset.zero;

  void _setDown(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  void _onPointerDown(PointerDownEvent event) {
    if (event.buttons != kPrimaryButton) return;
    _origin = event.position;
    _setDown(true);
  }

  void _onPointerMove(PointerMoveEvent event) {
    if ((event.position - _origin).distance > kTouchSlop) _setDown(false);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: (_) => _setDown(false),
      onPointerCancel: (_) => _setDown(false),
      child: widget.builder(context, _down),
    );
  }
}

class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.customBorder,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final ShapeBorder? customBorder;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool get _enabled => widget.onTap != null || widget.onLongPress != null;

  @override
  Widget build(BuildContext context) {
    return PointerPress(
      builder: (context, down) => MergeSemantics(
        child: Semantics(
          button: true,
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              PressLook(down: down && _enabled, child: widget.child),
              Positioned.fill(
                child: Material(
                  color: AppColors.transparent,
                  child: InkWell(
                    onTap: widget.onTap,
                    onLongPress: widget.onLongPress,
                    customBorder: widget.customBorder,
                    enableFeedback: false,
                    highlightColor: AppColors.transparent,
                    overlayColor: widget.customBorder == null
                        ? const WidgetStatePropertyAll(AppColors.transparent)
                        : null,
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
