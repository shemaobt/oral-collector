import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/theme/app_colors.dart';
import '../utils/format.dart';

class AudioPlayerWidget extends StatefulWidget {
  const AudioPlayerWidget({
    super.key,
    this.filePath,
    this.url,
    this.compact = false,
  }) : assert(
         filePath != null || url != null,
         'Either filePath or url must be provided',
       );

  final String? filePath;
  final String? url;
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

  Future<String?> _resolveFilePath(String storedPath) async {
    final file = File(storedPath);
    if (await file.exists()) return storedPath;

    final docsDir = await getApplicationDocumentsDirectory();
    final fileName = p.basename(storedPath);
    final resolved = '${docsDir.path}/$fileName';
    if (await File(resolved).exists()) return resolved;

    final inSubdir = '${docsDir.path}/recordings/$fileName';
    if (await File(inSubdir).exists()) return inSubdir;

    return null;
  }

  Future<void> _loadAudio() async {
    try {
      if (widget.filePath != null) {
        final resolvedPath = await _resolveFilePath(widget.filePath!);
        if (resolvedPath == null) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _error = 'Audio file not found';
            });
          }
          return;
        }
        await _player.setFilePath(resolvedPath);
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
    if (oldWidget.filePath != widget.filePath || oldWidget.url != widget.url) {
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
    final colors = AppColors.of(context);
    final size = widget.compact ? 16.0 : 24.0;
    return SizedBox(
      height: widget.compact ? 36.0 : 64.0,
      child: Center(
        child: SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: colors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    final colors = AppColors.of(context);
    return SizedBox(
      height: widget.compact ? 36.0 : 64.0,
      child: Center(
        child: Text(
          _error!,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colors.error,
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
      height: 72.0,
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
              const SizedBox(width: 60),
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
    final colors = AppColors.of(context);
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

        return Semantics(
          label: showPlay ? 'Play audio' : 'Pause audio',
          button: true,
          child: Material(
            color: colors.accent,
            shape: const CircleBorder(),
            child: InkWell(
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
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: size,
                height: size,
                child: Center(
                  child: Icon(
                    showPlay ? LucideIcons.play : LucideIcons.pause,
                    color: Colors.white,
                    size: iconSize,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSeekSlider({required bool compact}) {
    final colors = AppColors.of(context);
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
            activeTrackColor: colors.primary,
            inactiveTrackColor: colors.border,
            thumbColor: colors.primary,
            overlayColor: colors.primary.withValues(alpha: 0.2),
          ),
          child: Slider(
            min: 0,
            max: maxVal > 0 ? maxVal : 1.0,
            value: position.inMilliseconds.toDouble().clamp(
              0,
              maxVal > 0 ? maxVal : 1.0,
            ),
            onChanged: (value) {
              _player.seek(Duration(milliseconds: value.toInt()));
            },
          ),
        );
      },
    );
  }

  Widget _buildPositionLabel({required double fontSize}) {
    final colors = AppColors.of(context);
    return StreamBuilder<Duration>(
      stream: _player.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        return Text(
          formatDurationFromDuration(position),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontSize: fontSize,
            color: colors.foreground,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        );
      },
    );
  }

  Widget _buildDurationLabel({required double fontSize}) {
    final colors = AppColors.of(context);
    return StreamBuilder<Duration?>(
      stream: _player.durationStream,
      builder: (context, snapshot) {
        final duration = snapshot.data ?? Duration.zero;
        return Text(
          formatDurationFromDuration(duration),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontSize: fontSize,
            color: colors.foreground.withValues(alpha: 0.6),
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        );
      },
    );
  }
}
