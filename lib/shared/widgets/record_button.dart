import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';

enum RecordButtonState { ready, recording, paused }

class RecordButton extends StatefulWidget {
  const RecordButton({
    super.key,
    this.state = RecordButtonState.ready,
    this.onTap,
    this.onLongPress,
  });

  final RecordButtonState state;
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
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
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
    if (widget.state == RecordButtonState.recording) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double size = 80.0;

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
        child: _buildButton(size),
      ),
    );
  }

  Widget _buildButton(double size) {
    final colors = AppColors.of(context);
    final isRecording = widget.state == RecordButtonState.recording;
    final isPaused = widget.state == RecordButtonState.paused;

    final buttonColor = colors.accent;

    final String semanticLabel;
    if (isRecording) {
      semanticLabel = 'Recording in progress, tap to pause';
    } else if (isPaused) {
      semanticLabel = 'Recording paused, tap to resume';
    } else {
      semanticLabel = 'Start recording';
    }

    return Semantics(
      label: semanticLabel,
      button: true,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          customBorder: const CircleBorder(),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: buttonColor,
              border: isRecording
                  ? Border.all(color: colors.error, width: 3.0)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: buttonColor.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: isPaused
                  ? const Icon(LucideIcons.pause, color: Colors.white, size: 34)
                  : const Icon(LucideIcons.mic, color: Colors.white, size: 34),
            ),
          ),
        ),
      ),
    );
  }
}
