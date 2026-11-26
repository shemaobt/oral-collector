import 'package:flutter/material.dart';

import '../../core/theme/context_tokens.dart';

class LeavingRow extends StatefulWidget {
  const LeavingRow({
    super.key,
    required this.gone,
    required this.child,
    this.gap = 0,
  });

  final bool gone;
  final Widget child;
  final double gap;

  @override
  State<LeavingRow> createState() => _LeavingRowState();
}

class _Track {
  _Track(TickerProvider vsync, double initial)
    : _from = initial,
      _to = initial,
      controller = AnimationController(vsync: vsync);

  final AnimationController controller;
  double _from;
  double _to;
  Curve _curve = Curves.linear;

  double get value =>
      _from + (_to - _from) * _curve.transform(controller.value);

  void run(double to, Duration duration, Curve curve) {
    final from = value;
    _from = from;
    _to = to;
    _curve = curve;
    controller.duration = duration * (to - from).abs();
    controller.forward(from: 0);
  }
}

class _LeavingRowState extends State<LeavingRow> with TickerProviderStateMixin {
  late final _Track _fade = _Track(this, widget.gone ? 0 : 1);
  late final _Track _size = _Track(this, widget.gone ? 0 : 1);
  bool _slides = true;

  @override
  void initState() {
    super.initState();
    _fade.controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && widget.gone) {
        final motion = context.motion;
        _size.run(0, motion.base, motion.enter);
      }
    });
    _size.controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && !widget.gone) {
        final motion = context.motion;
        _fadeTo(1, motion.base, motion.enter);
      }
    });
  }

  @override
  void didUpdateWidget(LeavingRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gone == widget.gone) return;
    final motion = context.motion;
    if (widget.gone) {
      _fadeTo(0, motion.fast, motion.leave);
    } else {
      _size.run(1, motion.base, motion.enter);
    }
  }

  void _fadeTo(double to, Duration duration, Curve curve) {
    if (!_fade.controller.isAnimating) _slides = to == 0;
    _fade.run(to, duration, curve);
  }

  @override
  void dispose() {
    _fade.controller.dispose();
    _size.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final motion = context.motion;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return AnimatedBuilder(
      animation: Listenable.merge([_fade.controller, _size.controller]),
      builder: (context, child) {
        final away = 1 - _fade.value;
        final offset = _slides
            ? Offset((rtl ? 1 : -1) * motion.slide * away, 0)
            : Offset(0, motion.rise * away);
        final whole = !widget.gone && _fade.value >= 1;
        return ClipRect(
          child: Align(
            alignment: AlignmentDirectional.topStart,
            heightFactor: _size.value,
            child: Padding(
              padding: EdgeInsets.only(bottom: widget.gap),
              child: IgnorePointer(
                ignoring: !whole,
                child: ExcludeFocus(
                  excluding: !whole,
                  child: ExcludeSemantics(
                    excluding: widget.gone,
                    child: Opacity(
                      opacity: _fade.value,
                      child: Transform.translate(offset: offset, child: child),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}
