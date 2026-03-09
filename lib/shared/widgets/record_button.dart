import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';

/// Visual state of the record button.
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
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
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
    const double size = 72.0;

    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          final isRecording = widget.state == RecordButtonState.recording;
          final scale = isRecording ? _pulseAnimation.value : 1.0;

          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: _buildButton(size),
      ),
    );
  }

  Widget _buildButton(double size) {
    final isRecording = widget.state == RecordButtonState.recording;
    final isPaused = widget.state == RecordButtonState.paused;

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary,
          border: isRecording
              ? Border.all(color: AppColors.error, width: 3.0)
              : null,
          boxShadow: [
            BoxShadow(
              color: AppColors.foreground.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: isPaused
              ? const Icon(LucideIcons.pause, color: Colors.white, size: 32)
              : const Icon(LucideIcons.mic, color: Colors.white, size: 32),
        ),
      ),
    );
  }
}
