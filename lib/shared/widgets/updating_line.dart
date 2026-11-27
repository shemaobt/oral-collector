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
  late final AnimationController _wait = AnimationController(
    vsync: this,
    duration: MotionScale.checkWait,
  )..addStatusListener(_onWaited);
  late final AnimationController _fade = AnimationController(vsync: this)
    ..addStatusListener(_onFaded);
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
      _fade.value > 0 ? _appear() : _wait.forward(from: 0);
    } else {
      _wait.reset();
      if (_fade.value > 0) {
        _fade.duration = context.motion.fast;
        _fade.reverse();
      }
    }
  }

  void _onWaited(AnimationStatus status) {
    if (status == AnimationStatus.completed) _appear();
  }

  void _onFaded(AnimationStatus status) {
    if (status == AnimationStatus.dismissed) _run.stop();
  }

  void _appear() {
    final announce = _fade.value == 0;
    _fade.duration = context.motion.fast;
    _fade.forward();
    if (!context.motion.still) _run.repeat();
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
    _fade.dispose();
    _run.dispose();
    super.dispose();
  }

  double get _opacity {
    final motion = context.motion;
    return _fade.status == AnimationStatus.reverse
        ? 1 - motion.leave.transform(1 - _fade.value)
        : motion.enter.transform(_fade.value);
  }

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final still = context.motion.still;
    final color = AppColors.of(context).accent;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child,
        PositionedDirectional(
          top: 0,
          start: 0,
          end: 0,
          height: _height,
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: AnimatedBuilder(
                animation: Listenable.merge([_fade, _run]),
                builder: (context, _) {
                  if (_fade.value == 0) return const SizedBox.shrink();
                  return LayoutBuilder(
                    builder: (context, box) {
                      final stroke = still
                          ? box.maxWidth
                          : box.maxWidth * _strokeShare;
                      final travel = still
                          ? 0.0
                          : stroke *
                                (_startShare +
                                    _travelShare *
                                        MotionScale.loop.transform(_run.value));
                      return Opacity(
                        opacity: _opacity,
                        child: Align(
                          alignment: AlignmentDirectional.topStart,
                          child: Transform.translate(
                            offset: Offset(rtl ? -travel : travel, 0),
                            child: SizedBox(
                              width: stroke,
                              height: _height,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(_radius),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
