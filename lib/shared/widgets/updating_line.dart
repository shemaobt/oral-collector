import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/context_tokens.dart';
import '../../l10n/app_localizations.dart';

const double _height = 3;
const double _radius = 2;
const double _strokeShare = 0.38;
const double _startShare = -1.1;
const double _travelShare = 4;

class UpdatingLine extends StatefulWidget {
  const UpdatingLine({super.key, required this.checking, required this.child});

  final bool checking;
  final Widget child;

  @override
  State<UpdatingLine> createState() => _UpdatingLineState();
}

class _UpdatingLineState extends State<UpdatingLine>
    with TickerProviderStateMixin {
  late final AnimationController _wait =
      AnimationController(vsync: this, duration: MotionScale.checkWait)
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed) _appear();
        });
  late final AnimationController _fade = AnimationController(vsync: this)
    ..addStatusListener((status) {
      if (status == AnimationStatus.dismissed) _run.stop();
    });
  late final _opacity = CurvedAnimation(
    parent: _fade,
    curve: MotionScale.enter,
    reverseCurve: MotionScale.leave.flipped,
  );
  late final AnimationController _run = AnimationController(
    vsync: this,
    duration: MotionScale.checkRun,
  );

  @override
  void initState() {
    super.initState();
    if (widget.checking) _wait.forward();
  }

  @override
  void didUpdateWidget(UpdatingLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.checking == widget.checking) return;
    if (widget.checking) {
      _fade.isDismissed ? _wait.forward(from: 0) : _appear();
    } else {
      _wait.reset();
      if (!_fade.isDismissed) {
        _fade.duration = context.motion.fast;
        _fade.reverse();
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.checking && !_fade.isDismissed) _syncRun();
  }

  void _syncRun() => context.motion.still ? _run.stop() : _run.repeat();

  void _appear() {
    final announce = _fade.isDismissed;
    _fade.duration = context.motion.fast;
    _fade.forward();
    _syncRun();
    if (announce) {
      SemanticsService.sendAnnouncement(
        View.of(context),
        AppLocalizations.of(context).common_updating,
        Directionality.of(context),
      );
    }
  }

  @override
  void dispose() {
    _wait.dispose();
    _opacity.dispose();
    _fade.dispose();
    _run.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = context.motion.still;
    final color = AppColors.of(context).accent;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child,
        PositionedDirectional(
          top: MediaQuery.paddingOf(context).top,
          start: 0,
          end: 0,
          height: _height,
          child: ClipRect(
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_fade, _run]),
                  builder: (context, _) {
                    if (_fade.value == 0) return const SizedBox.shrink();
                    final at =
                        _startShare +
                        _travelShare * MotionScale.loop.transform(_run.value);
                    return FadeTransition(
                      opacity: _opacity,
                      child: FractionallySizedBox(
                        widthFactor: still ? 1 : _strokeShare,
                        alignment: AlignmentDirectional(
                          still
                              ? 0
                              : (2 * _strokeShare * at) / (1 - _strokeShare) -
                                    1,
                          0,
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(_radius),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
