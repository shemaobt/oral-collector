import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/format.dart';
import '../../../../shared/widgets/record_button.dart';
import '../notifiers/recording_session_notifier.dart';
import '../notifiers/recording_session_state.dart';
import 'control_button.dart';
import 'scrolling_waveform.dart';

class RecordingStep extends ConsumerStatefulWidget {
  const RecordingStep({
    super.key,
    required this.genreId,
    required this.subcategoryId,
    required this.genreName,
    required this.subcategoryName,
    required this.onRecordingComplete,
  });

  final String genreId;
  final String subcategoryId;
  final String? genreName;
  final String? subcategoryName;
  final ValueChanged<RecordingResult> onRecordingComplete;

  @override
  ConsumerState<RecordingStep> createState() => _RecordingStepState();
}

class _RecordingStepState extends ConsumerState<RecordingStep> {
  Future<void> _handleStop(RecordingSessionNotifier notifier) async {
    HapticFeedback.heavyImpact();
    final result = await notifier.stopRecording();
    if (result != null) {
      widget.onRecordingComplete(result);
    }
  }

  void _handleRecordTap(
    RecordingSessionNotifier notifier,
    RecordingState recState,
  ) {
    if (!recState.isRecording && !recState.isPaused) {
      HapticFeedback.mediumImpact();
      notifier.startRecording(widget.genreId, widget.subcategoryId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final theme = Theme.of(context);
    final recState = ref.watch(recordingSessionNotifierProvider);
    final notifier = ref.read(recordingSessionNotifierProvider.notifier);

    final isReady = !recState.isRecording && !recState.isPaused;
    final isActive = recState.isRecording;

    final tagParts = <String>[];
    if (widget.genreName != null) tagParts.add(widget.genreName!);
    if (widget.subcategoryName != null) tagParts.add(widget.subcategoryName!);
    final tagLabel = tagParts.join(' / ');

    return SizedBox.expand(
      child: ColoredBox(
        color: colors.background,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Text(
                  formatElapsed(recState.elapsed),
                  style: theme.textTheme.displayLarge?.copyWith(
                    color: colors.foreground,
                    fontWeight: FontWeight.w200,
                    fontSize: 56,
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
                ),
              ),

              if (isActive)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!recState.isPaused)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _PulsingDot(color: colors.accent),
                        ),
                      Text(
                        recState.isPaused ? 'Paused' : 'Recording',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.secondary,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),

              if (!isActive && tagLabel.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceAlt,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      tagLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.secondary,
                      ),
                    ),
                  ),
                ),

              Expanded(
                child: isReady
                    ? _buildReadyContent(colors, notifier, recState)
                    : _buildRecordingContent(colors, recState),
              ),

              if (isActive) _buildBottomControls(colors, notifier, recState),

              if (isReady)
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Text(
                    'Tap to Record',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.secondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadyContent(
    AppColorSet colors,
    RecordingSessionNotifier notifier,
    RecordingState recState,
  ) {
    final sensitivity = ref.watch(noiseSensitivityProvider);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSensitivitySelector(colors, sensitivity),
        const SizedBox(height: 32),
        _buildRecordButtonWithRings(
          colors,
          () => _handleRecordTap(notifier, recState),
        ),
      ],
    );
  }

  Widget _buildRecordButtonWithRings(AppColorSet colors, VoidCallback onTap) {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _buildRing(200, 44, colors.border.withValues(alpha: 0.12)),
          _buildRing(160, 36, colors.border.withValues(alpha: 0.22)),
          _buildRing(120, 28, colors.border.withValues(alpha: 0.38)),
          RecordButton(state: RecordButtonState.ready, onTap: onTap),
        ],
      ),
    );
  }

  Widget _buildRing(double size, double radius, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: color, width: 1.5),
      ),
    );
  }

  Widget _buildSensitivitySelector(
    AppColorSet colors,
    NoiseSensitivity current,
  ) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(LucideIcons.mic, size: 14, color: colors.secondary),
        const SizedBox(width: 6),
        Text(
          'Sensitivity',
          style: theme.textTheme.labelSmall?.copyWith(color: colors.secondary),
        ),
        const SizedBox(width: 10),
        _sensitivityChip(colors, NoiseSensitivity.low, current, 'Low'),
        const SizedBox(width: 4),
        _sensitivityChip(colors, NoiseSensitivity.medium, current, 'Med'),
        const SizedBox(width: 4),
        _sensitivityChip(colors, NoiseSensitivity.high, current, 'High'),
      ],
    );
  }

  Widget _sensitivityChip(
    AppColorSet colors,
    NoiseSensitivity value,
    NoiseSensitivity current,
    String label,
  ) {
    final isSelected = value == current;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        ref.read(noiseSensitivityProvider.notifier).state = value;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? colors.foreground : colors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: isSelected ? colors.background : colors.secondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingContent(AppColorSet colors, RecordingState recState) {
    return Center(
      child: ScrollingWaveform(
        amplitudeStream: recState.amplitudeStream,
        isPaused: recState.isPaused,
        height: 200,
        barColor: colors.foreground,
        cursorColor: colors.accent,
      ),
    );
  }

  Widget _buildBottomControls(
    AppColorSet colors,
    RecordingSessionNotifier notifier,
    RecordingState recState,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ControlButton(
            icon: recState.isPaused ? LucideIcons.play : LucideIcons.pause,
            label: recState.isPaused ? 'Resume' : 'Pause',
            onTap: () => recState.isPaused
                ? notifier.resumeRecording()
                : notifier.pauseRecording(),
          ),
          const SizedBox(width: 48),

          _buildStopButton(colors, () => _handleStop(notifier)),
        ],
      ),
    );
  }

  Widget _buildStopButton(AppColorSet colors, VoidCallback onTap) {
    return Semantics(
      label: 'Stop recording',
      button: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.heavyImpact();
          onTap();
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: colors.accent,
                boxShadow: [
                  BoxShadow(
                    color: colors.accent.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Stop',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.secondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color});

  final Color color;
  final double size = 8;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withValues(
            alpha: (0.3 + 0.7 * _controller.value).clamp(0.0, 1.0),
          ),
        ),
      ),
    );
  }
}
