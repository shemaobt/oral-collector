import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';

enum RecordButtonState { ready, recording, paused }

class RecordButton extends StatefulWidget {
  const RecordButton({
    super.key,
    this.state = RecordButtonState.ready,
    this.onTap,
    this.onLongPress,
  });

  static const double diameter = 88;

  final RecordButtonState state;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  State<RecordButton> createState() => _RecordButtonState();
}

class _RecordButtonState extends State<RecordButton>
    with SingleTickerProviderStateMixin {
  static const double _gap = 6;
  static const double _ring = 3;
  static const double _icon = 34;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: DurationScale.ms1200,
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
    const double size = RecordButton.diameter;

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dropShadow = isDark
        ? ShadowTints.dark.slab
        : colors.error.withValues(alpha: 0.75);

    final l10n = AppLocalizations.of(context);
    final String semanticLabel;
    if (isRecording) {
      semanticLabel = l10n.a11y_recordingInProgress;
    } else if (isPaused) {
      semanticLabel = l10n.a11y_recordingPaused;
    } else {
      semanticLabel = l10n.a11y_startRecording;
    }

    return Semantics(
      label: semanticLabel,
      button: true,
      child: Material(
        color: AppColors.transparent,
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
              color: colors.error,
              boxShadow: [
                BoxShadow(
                  color: dropShadow,
                  blurRadius: 34,
                  spreadRadius: -14,
                  offset: const Offset(0, 20),
                ),
                BoxShadow(color: colors.error, spreadRadius: _gap + _ring),
                BoxShadow(color: colors.background, spreadRadius: _gap),
              ],
            ),
            child: Center(
              child: isPaused
                  ? Icon(
                      LucideIcons.pause,
                      color: colors.onPrimary,
                      size: _icon,
                    )
                  : Icon(LucideIcons.mic, color: colors.onPrimary, size: _icon),
            ),
          ),
        ),
      ),
    );
  }
}
