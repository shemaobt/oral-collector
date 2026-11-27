import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import 'brush_sign.dart';
import 'hand_cut_rect.dart';

const double _lift = 10;
const double _minHeight = 52;
const double _signGap = 10;
const double _actionHeight = 44;
const double _actionEnd = 6;

enum QuickNoticeTone { calm, failed }

final _live = Expando<OverlayEntry>('quickNotice');

void showQuickNotice(
  BuildContext context,
  String sentence, {
  QuickNoticeTone tone = QuickNoticeTone.calm,
  Sign? sign,
  VoidCallback? onUndo,
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  final colors = AppColors.of(context);
  final motion = context.motion;
  final failed = tone == QuickNoticeTone.failed;
  final dark = Theme.of(context).brightness == Brightness.dark;
  final actionInk = dark
      ? colors.pale
      : failed
      ? colors.onPrimary
      : colors.sand;
  final undoWord = onUndo == null
      ? null
      : AppLocalizations.of(context).common_undo;
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _QuickNotice(
      sentence: sentence,
      sign: sign ?? (failed ? Sign.info : Sign.check),
      fill: failed ? colors.error : colors.primary,
      ink: colors.onPrimary,
      actionInk: actionInk,
      undoWord: undoWord,
      onUndo: onUndo,
      motion: motion,
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

class _QuickNotice extends StatefulWidget {
  const _QuickNotice({
    required this.sentence,
    required this.sign,
    required this.fill,
    required this.ink,
    required this.actionInk,
    required this.undoWord,
    required this.onUndo,
    required this.motion,
    required this.onGone,
  });

  final String sentence;
  final Sign sign;
  final Color fill;
  final Color ink;
  final Color actionInk;
  final String? undoWord;
  final VoidCallback? onUndo;
  final AppMotion motion;
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

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener(_onStatus);
    _controller.forward();
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _stay = Timer(
        widget.onUndo == null
            ? MotionScale.noticeStay
            : MotionScale.noticeStayUndo,
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

  void _undo() {
    if (_leaving) return;
    _leave();
    widget.onUndo!();
  }

  @override
  void dispose() {
    _stay?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom + _lift;
    final style = Theme.of(
      context,
    ).textTheme.bodyMedium!.copyWith(fontSize: 15, color: widget.ink);

    return Positioned(
      left: SpacingScale.s16,
      right: SpacingScale.s16,
      bottom: bottom,
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
          onVerticalDragEnd: (details) {
            if ((details.primaryVelocity ?? 0) > 0) _leave();
          },
          child: CustomPaint(
            painter: HandCutRectPainter(
              fill: widget.fill,
              radius: RadiusScale.r16,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: _minHeight),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  SpacingScale.s16,
                  SpacingScale.s12,
                  widget.undoWord == null ? SpacingScale.s16 : _actionEnd,
                  SpacingScale.s12,
                ),
                child: Row(
                  children: [
                    BrushSign(widget.sign, size: 18, color: widget.ink),
                    const SizedBox(width: _signGap),
                    Expanded(
                      child: Semantics(
                        liveRegion: true,
                        label: widget.sentence,
                        excludeSemantics: true,
                        child: Text(widget.sentence, style: style),
                      ),
                    ),
                    if (widget.undoWord case final word?)
                      _Action(
                        word: word,
                        style: style.copyWith(
                          color: widget.actionInk,
                          fontWeight: FontWeight.w600,
                        ),
                        onTap: _undo,
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
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: _actionHeight),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: SpacingScale.s12),
          child: Center(child: Text(word, style: style)),
        ),
      ),
    ),
  );
}
