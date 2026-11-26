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

class _LeavingRowState extends State<LeavingRow> with TickerProviderStateMixin {
  late final AnimationController _fadeController = AnimationController(
    vsync: this,
    value: widget.gone ? 0 : 1,
  );
  late final AnimationController _sizeController = AnimationController(
    vsync: this,
    value: widget.gone ? 0 : 1,
  );

  CurvedAnimation? _fade;
  CurvedAnimation? _size;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final motion = context.motion;
    _fade?.dispose();
    _size?.dispose();
    _fade = CurvedAnimation(
      parent: _fadeController,
      curve: motion.enter,
      reverseCurve: motion.leave.flipped,
    );
    _size = CurvedAnimation(
      parent: _sizeController,
      curve: motion.enter,
      reverseCurve: motion.enter.flipped,
    );
  }

  @override
  void didUpdateWidget(LeavingRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gone != widget.gone) _play();
  }

  Future<void> _play() async {
    final motion = context.motion;
    if (widget.gone) {
      _fadeController.duration = motion.fast;
      await _fadeController.reverse();
      if (!mounted || !widget.gone) return;
      _sizeController.duration = motion.base;
      await _sizeController.reverse();
    } else {
      _sizeController.duration = motion.base;
      await _sizeController.forward();
      if (!mounted || widget.gone) return;
      _fadeController.duration = motion.base;
      await _fadeController.forward();
    }
  }

  @override
  void dispose() {
    _fade?.dispose();
    _size?.dispose();
    _fadeController.dispose();
    _sizeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final motion = context.motion;
    final fade = _fade!;
    final size = _size!;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return AnimatedBuilder(
      animation: Listenable.merge([fade, size]),
      builder: (context, child) {
        if (_fadeController.isDismissed && _sizeController.isDismissed) {
          return const SizedBox.shrink();
        }
        final away = 1 - fade.value;
        final offset = widget.gone
            ? Offset((rtl ? 1 : -1) * motion.slide * away, 0)
            : Offset(0, motion.rise * away);
        return ClipRect(
          child: Align(
            alignment: AlignmentDirectional.topStart,
            heightFactor: size.value,
            child: Padding(
              padding: EdgeInsets.only(bottom: widget.gap),
              child: IgnorePointer(
                ignoring: widget.gone,
                child: ExcludeSemantics(
                  excluding: widget.gone,
                  child: Opacity(
                    opacity: fade.value,
                    child: Transform.translate(offset: offset, child: child),
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
