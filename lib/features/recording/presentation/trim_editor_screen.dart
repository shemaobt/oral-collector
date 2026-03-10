import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart' show Value;
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../data/providers/local_recording_repository_provider.dart';

class TrimEditorScreen extends ConsumerStatefulWidget {
  const TrimEditorScreen({super.key, required this.recordingId});

  final String recordingId;

  @override
  ConsumerState<TrimEditorScreen> createState() => _TrimEditorScreenState();
}

class _TrimEditorScreenState extends ConsumerState<TrimEditorScreen> {
  LocalRecording? _recording;
  bool _isLoading = true;
  bool _isSaving = false;

  AudioPlayer? _player;
  Duration _totalDuration = Duration.zero;

  // Trim range as fraction 0.0–1.0
  double _startFraction = 0.0;
  double _endFraction = 1.0;

  // Generated waveform bars (deterministic from duration)
  List<double> _waveformBars = [];

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    Future.microtask(_loadRecording);
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  Future<void> _loadRecording() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(localRecordingRepositoryProvider);
      final recording = await repo.getRecordingById(widget.recordingId);
      if (recording == null || !mounted) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      await _player!.setFilePath(recording.localFilePath);
      final duration = _player!.duration ?? Duration.zero;

      // Generate deterministic waveform bars based on file path hash
      final rng = Random(recording.localFilePath.hashCode);
      final barCount = 60;
      final bars = List.generate(barCount, (_) => 0.2 + rng.nextDouble() * 0.8);

      if (mounted) {
        setState(() {
          _recording = recording;
          _totalDuration = duration;
          _waveformBars = bars;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Duration get _startTime =>
      Duration(milliseconds: (_startFraction * _totalDuration.inMilliseconds).round());

  Duration get _endTime =>
      Duration(milliseconds: (_endFraction * _totalDuration.inMilliseconds).round());

  Duration get _newDuration => _endTime - _startTime;

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (duration.inHours > 0) {
      final hours = duration.inHours.toString();
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  String _formatDurationPrecise(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final millis = (duration.inMilliseconds.remainder(1000) ~/ 10)
        .toString()
        .padLeft(2, '0');
    return '$minutes:$seconds.$millis';
  }

  Future<void> _previewSelectedRegion() async {
    if (_player == null) return;
    await _player!.seek(_startTime);
    await _player!.play();

    // Stop at end time
    _player!.positionStream.listen((position) {
      if (position >= _endTime) {
        _player!.pause();
      }
    });
  }

  Future<void> _stopPreview() async {
    await _player?.pause();
  }

  Future<void> _saveTrimmedAudio() async {
    final recording = _recording;
    if (recording == null) return;

    setState(() => _isSaving = true);

    try {
      // Stop any playback
      await _player?.stop();

      final startSeconds = _startTime.inMilliseconds / 1000.0;
      final endSeconds = _endTime.inMilliseconds / 1000.0;

      // Create temporary output file
      final dir = await getApplicationDocumentsDirectory();
      final outputPath =
          '${dir.path}/trimmed_${DateTime.now().millisecondsSinceEpoch}.m4a';

      // FFmpeg command to trim audio
      final command =
          '-i "${recording.localFilePath}" -ss $startSeconds -to $endSeconds -c copy "$outputPath"';

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (!ReturnCode.isSuccess(returnCode)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to trim audio')),
          );
          setState(() => _isSaving = false);
        }
        return;
      }

      // Replace original file with trimmed version
      final originalFile = File(recording.localFilePath);
      final trimmedFile = File(outputPath);

      await originalFile.delete();
      await trimmedFile.rename(recording.localFilePath);

      // Get new file size
      final newFile = File(recording.localFilePath);
      final newSize = await newFile.length();
      final newDurationSeconds = _newDuration.inMilliseconds / 1000.0;

      // Update local DB
      final repo = ref.read(localRecordingRepositoryProvider);
      await repo.updateRecording(
        widget.recordingId,
        LocalRecordingsCompanion(
          durationSeconds: Value(newDurationSeconds),
          fileSizeBytes: Value(newSize),
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recording trimmed successfully')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error trimming audio: $e')),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: const Text('Trim Recording'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_recording == null) {
      return Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: const Text('Trim Recording'),
        ),
        body: const Center(child: Text('Recording not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Trim Recording'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.foreground.withValues(alpha: 0.6)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Waveform with trim handles
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Drag handles to select region',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.foreground.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _TrimWaveform(
                            bars: _waveformBars,
                            startFraction: _startFraction,
                            endFraction: _endFraction,
                            onStartChanged: (v) =>
                                setState(() => _startFraction = v),
                            onEndChanged: (v) =>
                                setState(() => _endFraction = v),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Time labels
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildTimeRow(
                            theme,
                            label: 'Start',
                            value: _formatDurationPrecise(_startTime),
                            icon: LucideIcons.skipBack,
                          ),
                          const SizedBox(height: 12),
                          _buildTimeRow(
                            theme,
                            label: 'End',
                            value: _formatDurationPrecise(_endTime),
                            icon: LucideIcons.skipForward,
                          ),
                          const Divider(height: 24),
                          _buildTimeRow(
                            theme,
                            label: 'New Duration',
                            value: _formatDuration(_newDuration),
                            icon: LucideIcons.clock,
                            bold: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Preview button
                  _PreviewButton(
                    player: _player!,
                    onPlay: _previewSelectedRegion,
                    onStop: _stopPreview,
                  ),
                ],
              ),
            ),
          ),

          // Bottom save/cancel bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              border: Border(
                top: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isSaving ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.foreground,
                        side: BorderSide(
                          color: AppColors.border.withValues(alpha: 0.5),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveTrimmedAudio,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Save'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRow(
    ThemeData theme, {
    required String label,
    required String value,
    required IconData icon,
    bool bold = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.border),
        const SizedBox(width: 12),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.foreground.withValues(alpha: 0.6),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Preview button with play/stop state
// ---------------------------------------------------------------------------

class _PreviewButton extends StatefulWidget {
  const _PreviewButton({
    required this.player,
    required this.onPlay,
    required this.onStop,
  });

  final AudioPlayer player;
  final VoidCallback onPlay;
  final VoidCallback onStop;

  @override
  State<_PreviewButton> createState() => _PreviewButtonState();
}

class _PreviewButtonState extends State<_PreviewButton> {
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    widget.player.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        _isPlaying = state.playing;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isPlaying ? widget.onStop : widget.onPlay,
        icon: Icon(
          _isPlaying ? LucideIcons.square : LucideIcons.play,
          size: 18,
        ),
        label: Text(_isPlaying ? 'Stop Preview' : 'Preview Selection'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Trim waveform with draggable start/end handles
// ---------------------------------------------------------------------------

class _TrimWaveform extends StatefulWidget {
  const _TrimWaveform({
    required this.bars,
    required this.startFraction,
    required this.endFraction,
    required this.onStartChanged,
    required this.onEndChanged,
  });

  final List<double> bars;
  final double startFraction;
  final double endFraction;
  final ValueChanged<double> onStartChanged;
  final ValueChanged<double> onEndChanged;

  @override
  State<_TrimWaveform> createState() => _TrimWaveformState();
}

class _TrimWaveformState extends State<_TrimWaveform> {
  static const double _handleWidth = 16.0;
  static const double _waveformHeight = 120.0;
  static const double _minSelectionFraction = 0.02; // minimum 2% selection

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;

        return SizedBox(
          height: _waveformHeight + 24, // extra for handle knobs
          child: Stack(
            children: [
              // Waveform bars
              Positioned(
                left: 0,
                right: 0,
                top: 12,
                height: _waveformHeight,
                child: CustomPaint(
                  size: Size(totalWidth, _waveformHeight),
                  painter: _TrimWaveformPainter(
                    bars: widget.bars,
                    startFraction: widget.startFraction,
                    endFraction: widget.endFraction,
                  ),
                ),
              ),

              // Start handle
              Positioned(
                left: widget.startFraction * totalWidth - _handleWidth / 2,
                top: 0,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    final newPos =
                        (widget.startFraction * totalWidth + details.delta.dx) /
                            totalWidth;
                    final clamped = newPos.clamp(
                      0.0,
                      widget.endFraction - _minSelectionFraction,
                    );
                    widget.onStartChanged(clamped);
                  },
                  child: _buildHandle(isStart: true),
                ),
              ),

              // End handle
              Positioned(
                left: widget.endFraction * totalWidth - _handleWidth / 2,
                top: 0,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    final newPos =
                        (widget.endFraction * totalWidth + details.delta.dx) /
                            totalWidth;
                    final clamped = newPos.clamp(
                      widget.startFraction + _minSelectionFraction,
                      1.0,
                    );
                    widget.onEndChanged(clamped);
                  },
                  child: _buildHandle(isStart: false),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHandle({required bool isStart}) {
    return SizedBox(
      width: _handleWidth,
      height: _waveformHeight + 24,
      child: Column(
        children: [
          // Top knob
          Container(
            width: _handleWidth,
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(
                top: const Radius.circular(4),
              ),
            ),
          ),
          // Vertical line
          Expanded(
            child: Center(
              child: Container(
                width: 2,
                color: AppColors.primary,
              ),
            ),
          ),
          // Bottom knob
          Container(
            width: _handleWidth,
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(
                bottom: const Radius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Custom painter for the waveform with highlighted selection region
// ---------------------------------------------------------------------------

class _TrimWaveformPainter extends CustomPainter {
  _TrimWaveformPainter({
    required this.bars,
    required this.startFraction,
    required this.endFraction,
  });

  final List<double> bars;
  final double startFraction;
  final double endFraction;

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty) return;

    final barCount = bars.length;
    final barWidth = size.width / barCount * 0.7;
    final barSpacing = size.width / barCount * 0.3;
    final stepWidth = barWidth + barSpacing;
    final centerY = size.height / 2;
    const minBarHeight = 2.0;

    // Draw selection highlight
    final selectionPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    final selStartX = startFraction * size.width;
    final selEndX = endFraction * size.width;
    canvas.drawRect(
      Rect.fromLTRB(selStartX, 0, selEndX, size.height),
      selectionPaint,
    );

    // Draw bars
    final selectedBarPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    final unselectedBarPaint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.fill;

    for (var i = 0; i < barCount; i++) {
      final amplitude = bars[i].clamp(0.0, 1.0);
      final barHeight =
          minBarHeight + amplitude * (size.height - minBarHeight);
      final x = i * stepWidth;
      final top = centerY - barHeight / 2;

      final barCenter = (x + barWidth / 2) / size.width;
      final isSelected =
          barCenter >= startFraction && barCenter <= endFraction;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, top, barWidth, barHeight),
        Radius.circular(barWidth / 2),
      );
      canvas.drawRRect(rect, isSelected ? selectedBarPaint : unselectedBarPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TrimWaveformPainter oldDelegate) {
    return oldDelegate.bars != bars ||
        oldDelegate.startFraction != startFraction ||
        oldDelegate.endFraction != endFraction;
  }
}
