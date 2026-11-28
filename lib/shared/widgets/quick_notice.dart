import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import 'brush_sign.dart';
import 'hand_cut_rect.dart';
import 'pressable.dart';

const double _lift = 10;
const double _minHeight = 52;
const double _signGap = 10;
const double _actionHeight = 44;
const double _actionEnd = 6;

enum QuickNoticeTone { calm, failed }

class QuickNoticeAction {
  const QuickNoticeAction(String this.word, this.onTap);
  const QuickNoticeAction.undo(this.onTap) : word = null;

  final String? word;
  final VoidCallback onTap;
}

final _live = Expando<OverlayEntry>('quickNotice');
final _floors = Expando<ValueNotifier<double>>('quickNoticeFloor');

ValueNotifier<double> _floorOf(OverlayState overlay) =>
    _floors[overlay] ??= ValueNotifier(0);

void showQuickNotice(
  BuildContext context,
  String sentence, {
  QuickNoticeTone tone = QuickNoticeTone.calm,
  Sign? sign,
  QuickNoticeAction? action,
}) => quickNoticeOf(
  context,
).show(sentence, tone: tone, sign: sign, action: action);

QuickNotice quickNoticeOf(BuildContext context) =>
    QuickNotice._(Overlay.of(context, rootOverlay: true));

class QuickNotice {
  const QuickNotice._(this._overlay);

  final OverlayState _overlay;

  void show(
    String sentence, {
    QuickNoticeTone tone = QuickNoticeTone.calm,
    Sign? sign,
    QuickNoticeAction? action,
  }) => _show(_overlay, sentence, tone, sign, action);
}

void _show(
  OverlayState overlay,
  String sentence,
  QuickNoticeTone tone,
  Sign? sign,
  QuickNoticeAction? action,
) {
  final context = overlay.context;
  final colors = AppColors.of(context);
  final motion = context.motion;
  final failed = tone == QuickNoticeTone.failed;
  final dark = Theme.of(context).brightness == Brightness.dark;
  final actionInk = dark
      ? colors.pale
      : failed
      ? colors.onPrimary
      : colors.sand;
  final word = action == null
      ? null
      : action.word ?? AppLocalizations.of(context).common_undo;
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _QuickNotice(
      sentence: sentence,
      sign: sign ?? (failed ? Sign.info : Sign.check),
      fill: failed ? colors.error : colors.primary,
      ink: colors.onPrimary,
      actionInk: actionInk,
      word: word,
      onAct: action?.onTap,
      motion: motion,
      floor: _floorOf(overlay),
      onGone: () {
        if (_live[overlay] != entry) return;
        _live[overlay] = null;
        entry.remove();
        entry.dispose();
      },
    ),
  );
  _live[overlay]
    ?..remove()
    ..dispose();
  _live[overlay] = entry;
  overlay.insert(entry);
}

class QuickNoticeFloor extends StatefulWidget {
  const QuickNoticeFloor({super.key, required this.child});

  final Widget child;

  @override
  State<QuickNoticeFloor> createState() => _QuickNoticeFloorState();
}

class _QuickNoticeFloorState extends State<QuickNoticeFloor> {
  late ValueNotifier<double> _floor;

  void _set(double height) => WidgetsBinding.instance.addPostFrameCallback(
    (_) => _floor.value = height,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _floor = _floorOf(Overlay.of(context, rootOverlay: true));
    _set(
      ModalRoute.isCurrentOf(context) ?? true
          ? MediaQuery.paddingOf(context).bottom
          : 0,
    );
  }

  @override
  void dispose() {
    _set(0);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _QuickNotice extends StatefulWidget {
  const _QuickNotice({
    required this.sentence,
    required this.sign,
    required this.fill,
    required this.ink,
    required this.actionInk,
    required this.word,
    required this.onAct,
    required this.motion,
    required this.floor,
    required this.onGone,
  });

  final String sentence;
  final Sign sign;
  final Color fill;
  final Color ink;
  final Color actionInk;
  final String? word;
  final VoidCallback? onAct;
  final AppMotion motion;
  final ValueListenable<double> floor;
  final VoidCallback onGone;

  @override
  State<_QuickNotice> createState() => _QuickNoticeState();
}

class _QuickNoticeState extends State<_QuickNotice>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.motion.base,
    reverseDuration: widget.motion.fast,
  );
  Timer? _stay;
  bool _leaving = false;
  double _drag = 0;

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener(_onStatus);
    _controller.forward();
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _stay = Timer(
        widget.onAct == null
            ? MotionScale.noticeStay
            : MotionScale.noticeStayAction,
        _leave,
      );
    } else if (status == AnimationStatus.dismissed) {
      widget.onGone();
    }
  }

  void _leave() {
    if (_leaving) return;
    _leaving = true;
    _stay?.cancel();
    _controller.reverse();
  }

  void _act() {
    if (_leaving) return;
    _leave();
    widget.onAct!();
  }

  @override
  void dispose() {
    _stay?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(
      context,
    ).textTheme.bodyMedium!.copyWith(fontSize: 15, color: widget.ink);

    return ValueListenableBuilder(
      valueListenable: widget.floor,
      builder: (context, floor, child) => Positioned(
        left: SpacingScale.s16,
        right: SpacingScale.s16,
        bottom:
            [
              floor,
              MediaQuery.paddingOf(context).bottom,
              MediaQuery.viewInsetsOf(context).bottom,
            ].reduce(math.max) +
            _lift,
        child: child!,
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final double dy, opacity;
          if (_leaving) {
            final eased = widget.motion.leave.transform(1 - _controller.value);
            dy = widget.motion.rise * eased;
            opacity = 1 - eased;
          } else {
            final eased = MotionScale.noticeJump.transform(_controller.value);
            dy = MotionScale.noticeDrop * (1 - eased);
            opacity = eased;
          }
          return Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.translate(offset: Offset(0, dy), child: child),
          );
        },
        child: GestureDetector(
          onVerticalDragStart: (_) => _drag = 0,
          onVerticalDragUpdate: (details) => _drag += details.delta.dy,
          onVerticalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0;
            if (velocity > 0 || (velocity == 0 && _drag > 0)) _leave();
          },
          child: CustomPaint(
            painter: HandCutRectPainter(
              fill: widget.fill,
              radius: RadiusScale.r16,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: _minHeight),
              child: Padding(
                padding: EdgeInsetsDirectional.only(
                  start: SpacingScale.s16,
                  end: widget.word == null ? SpacingScale.s16 : _actionEnd,
                ),
                child: Row(
                  children: [
                    BrushSign(widget.sign, size: 18, color: widget.ink),
                    const SizedBox(width: _signGap),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: SpacingScale.s12,
                        ),
                        child: Semantics(
                          liveRegion: true,
                          label: widget.sentence,
                          excludeSemantics: true,
                          child: Text(widget.sentence, style: style),
                        ),
                      ),
                    ),
                    if (widget.word case final word?)
                      _Action(
                        word: word,
                        style: style.copyWith(
                          color: widget.actionInk,
                          fontWeight: FontWeight.w600,
                        ),
                        onTap: _act,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({required this.word, required this.style, required this.onTap});

  final String word;
  final TextStyle style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _actionHeight),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: SpacingScale.s12),
        child: Center(child: Text(word, style: style)),
      ),
    ),
  );
}
