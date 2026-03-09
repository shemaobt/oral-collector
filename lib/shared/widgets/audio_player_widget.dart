import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';

/// Audio playback widget with play/pause, seek slider, and duration display.
///
/// Accepts either a local [filePath] or a remote [url] for the audio source.
/// Set [compact] to true for inline use in recording cards (smaller controls).
class AudioPlayerWidget extends StatefulWidget {
  const AudioPlayerWidget({
    super.key,
    this.filePath,
    this.url,
    this.compact = false,
  }) : assert(filePath != null || url != null,
            'Either filePath or url must be provided');

  /// Local file path for audio playback.
  final String? filePath;

  /// Remote URL for audio playback.
  final String? url;

  /// When true, renders smaller controls suitable for inline card use.
  final bool compact;

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late final AudioPlayer _player;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _loadAudio();
  }

  Future<void> _loadAudio() async {
    try {
      if (widget.filePath != null) {
        await _player.setFilePath(widget.filePath!);
      } else if (widget.url != null) {
        await _player.setUrl(widget.url!);
      }
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load audio';
        });
      }
    }
  }

  @override
  void didUpdateWidget(covariant AudioPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filePath != widget.filePath ||
        oldWidget.url != widget.url) {
      _isLoading = true;
      _error = null;
      _player.stop();
      _loadAudio();
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (duration.inHours > 0) {
      final hours = duration.inHours.toString();
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _buildError();
    }

    if (_isLoading) {
      return _buildLoading();
    }

    return widget.compact ? _buildCompact() : _buildFull();
  }

  Widget _buildLoading() {
    final size = widget.compact ? 16.0 : 24.0;
    return SizedBox(
      height: widget.compact ? 36.0 : 64.0,
      child: Center(
        child: SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return SizedBox(
      height: widget.compact ? 36.0 : 64.0,
      child: Center(
        child: Text(
          _error!,
          style: TextStyle(
            color: AppColors.error,
            fontSize: widget.compact ? 12.0 : 14.0,
          ),
        ),
      ),
    );
  }

  Widget _buildCompact() {
    return SizedBox(
      height: 36.0,
      child: Row(
        children: [
          _buildPlayPauseButton(size: 28.0, iconSize: 14.0),
          const SizedBox(width: 8),
          Expanded(child: _buildSeekSlider(compact: true)),
          const SizedBox(width: 4),
          _buildPositionLabel(fontSize: 11.0),
        ],
      ),
    );
  }

  Widget _buildFull() {
    return SizedBox(
      height: 64.0,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              _buildPlayPauseButton(size: 48.0, iconSize: 22.0),
              const SizedBox(width: 12),
              Expanded(child: _buildSeekSlider(compact: false)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const SizedBox(width: 60), // offset for play button
              _buildPositionLabel(fontSize: 12.0),
              const Spacer(),
              _buildDurationLabel(fontSize: 12.0),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayPauseButton({
    required double size,
    required double iconSize,
  }) {
    return StreamBuilder<PlayerState>(
      stream: _player.playerStateStream,
      builder: (context, snapshot) {
        final playerState = snapshot.data;
        final processingState = playerState?.processingState;
        final playing = playerState?.playing ?? false;

        final bool showPlay;
        if (processingState == ProcessingState.completed) {
          showPlay = true;
        } else {
          showPlay = !playing;
        }

        return GestureDetector(
          onTap: () {
            if (processingState == ProcessingState.completed) {
              _player.seek(Duration.zero);
              _player.play();
            } else if (playing) {
              _player.pause();
            } else {
              _player.play();
            }
          },
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
            ),
            child: Center(
              child: Icon(
                showPlay ? LucideIcons.play : LucideIcons.pause,
                color: Colors.white,
                size: iconSize,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSeekSlider({required bool compact}) {
    return StreamBuilder<Duration>(
      stream: _player.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final duration = _player.duration ?? Duration.zero;
        final maxVal = duration.inMilliseconds.toDouble();

        return SliderTheme(
          data: SliderThemeData(
            trackHeight: compact ? 2.0 : 4.0,
            thumbShape: RoundSliderThumbShape(
              enabledThumbRadius: compact ? 5.0 : 7.0,
            ),
            overlayShape: RoundSliderOverlayShape(
              overlayRadius: compact ? 10.0 : 14.0,
            ),
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.border,
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withValues(alpha: 0.2),
          ),
          child: Slider(
            min: 0,
            max: maxVal > 0 ? maxVal : 1.0,
            value: position.inMilliseconds
                .toDouble()
                .clamp(0, maxVal > 0 ? maxVal : 1.0),
            onChanged: (value) {
              _player.seek(Duration(milliseconds: value.toInt()));
            },
          ),
        );
      },
    );
  }

  Widget _buildPositionLabel({required double fontSize}) {
    return StreamBuilder<Duration>(
      stream: _player.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        return Text(
          _formatDuration(position),
          style: TextStyle(
            fontSize: fontSize,
            color: AppColors.foreground,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        );
      },
    );
  }

  Widget _buildDurationLabel({required double fontSize}) {
    return StreamBuilder<Duration?>(
      stream: _player.durationStream,
      builder: (context, snapshot) {
        final duration = snapshot.data ?? Duration.zero;
        return Text(
          _formatDuration(duration),
          style: TextStyle(
            fontSize: fontSize,
            color: AppColors.foreground.withValues(alpha: 0.6),
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        );
      },
    );
  }
}
