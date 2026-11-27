import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import 'app_disc.dart';

enum RecordButtonState { ready, recording, paused }

class RecordButton extends StatefulWidget {
  const RecordButton({
    super.key,
    this.state = RecordButtonState.ready,
    this.size = DiscSize.huge,
    this.onTap,
    this.onLongPress,
  });

  final RecordButtonState state;
  final DiscSize size;
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

    return Semantics(
      label: semanticLabel,
      button: true,
      child: Stack(
        children: [
          AppDisc(
            size: widget.size,
            tone: DiscTone.record,
            pressable: true,
            child: Icon(isPaused ? LucideIcons.pause : LucideIcons.mic),
          ),
          Positioned.fill(
            child: Material(
              color: AppColors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                onLongPress: widget.onLongPress,
                customBorder: const CircleBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
