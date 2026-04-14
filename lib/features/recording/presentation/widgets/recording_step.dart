import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/format.dart';
import '../../../../shared/widgets/record_button.dart';
import '../../data/services/storage_guard.dart';
import '../notifiers/input_device_notifier.dart';
import '../notifiers/recording_session_notifier.dart';
import '../notifiers/recording_session_state.dart';
import 'control_button.dart';
import 'input_device_picker_sheet.dart';
import 'scrolling_waveform.dart';

class RecordingStep extends ConsumerStatefulWidget {
  const RecordingStep({
    super.key,
    required this.genreId,
    required this.subcategoryId,
    required this.genreName,
    required this.subcategoryName,
    this.registerName,
    required this.onRecordingComplete,
  });

  final String genreId;
  final String subcategoryId;
  final String? genreName;
  final String? subcategoryName;
  final String? registerName;
  final ValueChanged<RecordingResult> onRecordingComplete;

  @override
  ConsumerState<RecordingStep> createState() => _RecordingStepState();
}

class _RecordingStepState extends ConsumerState<RecordingStep>
    with WidgetsBindingObserver {
  AppLifecycleState? _lastLifecycleState;
  bool _showBackgroundResumeBanner = false;
  Timer? _backgroundBannerTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() {
      if (!mounted) return;
      ref.read(inputDeviceNotifierProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _backgroundBannerTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final previous = _lastLifecycleState;
    _lastLifecycleState = state;
    final isRecording = ref.read(recordingSessionNotifierProvider).isRecording;
    if (state == AppLifecycleState.resumed &&
        previous == AppLifecycleState.paused &&
        isRecording) {
      if (!mounted) return;
      setState(() => _showBackgroundResumeBanner = true);
      _backgroundBannerTimer?.cancel();
      _backgroundBannerTimer = Timer(const Duration(seconds: 3), () {
        if (!mounted) return;
        setState(() => _showBackgroundResumeBanner = false);
      });
    }
  }

  Future<void> _handleStop(RecordingSessionNotifier notifier) async {
    HapticFeedback.heavyImpact();
    final result = await notifier.stopRecording();
    if (!mounted) return;
    if (result != null) {
      widget.onRecordingComplete(result);
    }
  }

  Future<void> _handleRecordTap(
    RecordingSessionNotifier notifier,
    RecordingState recState,
  ) async {
    if (recState.isRecording || recState.isPaused) return;

    final check = await notifier.checkStorageBeforeStart();
    if (!mounted) return;

    if (check.severity == PreStartSeverity.refuse) {
      await _showRefuseDialog();
      return;
    }

    if (check.severity == PreStartSeverity.warn) {
      final proceed = await _showWarnDialog(check.estimatedSeconds);
      if (!mounted || proceed != true) return;
    }

    HapticFeedback.mediumImpact();
    await notifier.startRecording(widget.genreId, widget.subcategoryId);
  }

  Future<void> _showRefuseDialog() async {
    final l10n = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.recording_storageRefuseTitle),
        content: Text(l10n.recording_storageRefuseBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.recording_cancel),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showWarnDialog(int estimatedSeconds) async {
    final l10n = AppLocalizations.of(context);
    final minutes = (estimatedSeconds / 60).floor();
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.recording_storageLowWarnTitle),
        content: Text(l10n.recording_storageLowWarnBody(minutes)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.recording_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.recording_continue),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);
    final theme = Theme.of(context);
    final recState = ref.watch(recordingSessionNotifierProvider);
    final notifier = ref.read(recordingSessionNotifierProvider.notifier);

    ref.listen<RecordingState>(recordingSessionNotifierProvider, (prev, next) {
      final result = next.autoStoppedResult;
      if (result == null) return;
      if (prev?.autoStoppedResult == result) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        notifier.acknowledgeAutoStop();
        widget.onRecordingComplete(result);
      });
    });

    final isReady = !recState.isRecording && !recState.isPaused;
    final isActive = recState.isRecording;

    final tagParts = <String>[];
    if (widget.genreName != null) tagParts.add(widget.genreName!);
    if (widget.subcategoryName != null) tagParts.add(widget.subcategoryName!);
    if (widget.registerName != null) tagParts.add(widget.registerName!);
    final tagLabel = tagParts.join(' / ');

    return SizedBox.expand(
      child: ColoredBox(
        color: colors.background,
        child: SafeArea(
          child: Column(
            children: [
              if (isActive &&
                  recState.storageBannerSeverity ==
                      StorageBannerSeverity.critical)
                _StorageBanner(
                  message: l10n.recording_storageCriticalBanner(
                    ((recState.lastCheckpointAt?.inSeconds ?? 0) / 60).floor(),
                  ),
                ),
              if (isActive && _showBackgroundResumeBanner)
                _InfoBanner(message: l10n.recording_continuedInBackground),
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
                        recState.isPaused
                            ? l10n.recording_paused
                            : l10n.recording_recording,
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
                    : _buildRecordingContent(colors, recState, l10n),
              ),

              if (isActive) _buildBottomControls(colors, notifier, recState),

              if (isReady)
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Text(
                    l10n.recording_tapToRecord,
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
        _buildInputSourceRow(colors),
        const SizedBox(height: 12),
        _buildSensitivitySelector(colors, sensitivity),
        const SizedBox(height: 32),
        _buildRecordButtonWithRings(
          colors,
          () => _handleRecordTap(notifier, recState),
        ),
      ],
    );
  }

  Widget _buildInputSourceRow(AppColorSet colors) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final deviceState = ref.watch(inputDeviceNotifierProvider);
    final selected = deviceState.selectedDevice;
    final label = selected?.label.isNotEmpty == true
        ? selected!.label
        : l10n.recording_builtInMicrophone;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        showModalBottomSheet<void>(
          context: context,
          showDragHandle: false,
          builder: (_) => const InputDevicePickerSheet(),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.mic2, size: 14, color: colors.secondary),
            const SizedBox(width: 6),
            Text(
              l10n.recording_inputSource,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.secondary,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.foreground,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(LucideIcons.chevronDown, size: 14, color: colors.secondary),
          ],
        ),
      ),
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
          AppLocalizations.of(context).recording_sensitivity,
          style: theme.textTheme.labelSmall?.copyWith(color: colors.secondary),
        ),
        const SizedBox(width: 10),
        _sensitivityChip(
          colors,
          NoiseSensitivity.low,
          current,
          AppLocalizations.of(context).recording_sensitivityLow,
        ),
        const SizedBox(width: 4),
        _sensitivityChip(
          colors,
          NoiseSensitivity.medium,
          current,
          AppLocalizations.of(context).recording_sensitivityMed,
        ),
        const SizedBox(width: 4),
        _sensitivityChip(
          colors,
          NoiseSensitivity.high,
          current,
          AppLocalizations.of(context).recording_sensitivityHigh,
        ),
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

  Widget _buildRecordingContent(
    AppColorSet colors,
    RecordingState recState,
    AppLocalizations l10n,
  ) {
    final checkpoint = recState.lastCheckpointAt;
    return Stack(
      alignment: Alignment.center,
      children: [
        Center(
          child: ScrollingWaveform(
            amplitudeStream: recState.amplitudeStream,
            isPaused: recState.isPaused,
            height: 200,
            barColor: colors.foreground,
            cursorColor: colors.accent,
          ),
        ),
        if (checkpoint != null)
          Positioned(
            bottom: 16,
            child: AnimatedOpacity(
              opacity: recState.showCheckpointToast ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: _CheckpointChip(
                label: l10n.recording_savedAt(formatElapsed(checkpoint)),
              ),
            ),
          ),
      ],
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
            label: recState.isPaused
                ? AppLocalizations.of(context).recording_resume
                : AppLocalizations.of(context).recording_pause,
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
      label: AppLocalizations.of(context).recording_stopRecording,
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
              AppLocalizations.of(context).recording_stop,
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

class _StorageBanner extends StatelessWidget {
  const _StorageBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFFFFEDCC),
      child: Row(
        children: [
          const Icon(
            LucideIcons.alertTriangle,
            size: 16,
            color: Color(0xFF8A5A00),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF8A5A00),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: colors.surfaceAlt,
      child: Row(
        children: [
          Icon(LucideIcons.info, size: 16, color: colors.secondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colors.secondary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckpointChip extends StatelessWidget {
  const _CheckpointChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.foreground.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.checkCircle2, size: 12, color: colors.background),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: colors.background,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
