import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import 'app_disc.dart';
import 'brush_sign.dart';
import 'call_ring.dart';
import 'pressable.dart';
import 'sound_strokes.dart';

enum RecordButtonState { ready, recording, paused }

class RecordButton extends StatefulWidget {
  const RecordButton({
    super.key,
    this.state = RecordButtonState.ready,
    this.size = DiscSize.huge,
    this.calling = false,
    this.onTap,
    this.onLongPress,
  });

  final RecordButtonState state;
  final DiscSize size;
  final bool calling;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  State<RecordButton> createState() => _RecordButtonState();
}

class _RecordButtonState extends State<RecordButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: MotionScale.recordPulse,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: MotionScale.loop),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant RecordButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _syncAnimation();
    }
  }

  void _syncAnimation() {
    _pulseController.loopUnless(
      still:
          widget.state != RecordButtonState.recording || context.motion.still,
      reverse: true,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size.diameter;

    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          final isRecording = widget.state == RecordButtonState.recording;
          final scale = isRecording ? _pulseAnimation.value : 1.0;

          return Transform.scale(scale: scale, child: child);
        },
        child: _buildButton(),
      ),
    );
  }

  Widget _buildButton() {
    final isRecording = widget.state == RecordButtonState.recording;
    final isPaused = widget.state == RecordButtonState.paused;

    final l10n = AppLocalizations.of(context);
    final String semanticLabel;
    if (isRecording) {
      semanticLabel = l10n.a11y_recordingInProgress;
    } else if (isPaused) {
      semanticLabel = l10n.a11y_recordingPaused;
    } else {
      semanticLabel = l10n.a11y_startRecording;
    }

    final colors = AppColors.of(context);
    final diameter = widget.size.diameter;

    return CallRing(
      diameter: diameter,
      color: colors.accent,
      calling: widget.calling && widget.state == RecordButtonState.ready,
      child: SoundStrokes(
        diameter: diameter,
        color: colors.mic,
        sounding: isRecording,
        child: Pressable(
          label: semanticLabel,
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          customBorder: const CircleBorder(),
          child: AppDisc(
            size: widget.size,
            tone: DiscTone.record,
            pressable: true,
            child: BrushSign(
              isRecording ? Sign.stop : Sign.mic,
              size: diameter * 0.46,
            ),
          ),
        ),
      ),
    );
  }
}
