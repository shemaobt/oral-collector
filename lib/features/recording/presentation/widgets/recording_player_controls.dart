import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/utils/format.dart';
import '../notifiers/recording_player_notifier.dart';
import 'playback_key_handler.dart';

class RecordingPlayerControls extends ConsumerWidget {
  const RecordingPlayerControls({super.key, required this.recordingId});

  final String recordingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(recordingPlayerProvider(recordingId).notifier);
    final player = notifier.player;

    return PlaybackKeyHandler(
      onSpace: notifier.togglePlay,
      child: SizedBox(
        height: 72.0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                _PlayPauseButton(player: player, onTap: notifier.togglePlay),
                const SizedBox(width: SpacingScale.s12),
                Expanded(
                  child: _SeekSlider(player: player, notifier: notifier),
                ),
              ],
            ),
            const SizedBox(height: SpacingScale.s4),
            Row(
              children: [
                const SizedBox(width: 60),
                _PositionLabel(player: player),
                const Spacer(),
                _DurationLabel(player: player),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  const _PlayPauseButton({required this.player, required this.onTap});

  final AudioPlayer player;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return StreamBuilder<PlayerState>(
      stream: player.playerStateStream,
      builder: (context, snapshot) {
        final playerState = snapshot.data;
        final processingState = playerState?.processingState;
        final playing = playerState?.playing ?? false;
        final showPlay = processingState == ProcessingState.completed
            ? true
            : !playing;
        return Semantics(
          label: showPlay ? l10n.a11y_playAudio : l10n.a11y_pauseAudio,
          button: true,
          child: Material(
            color: colors.accent,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: SpacingScale.s48,
                height: SpacingScale.s48,
                child: Center(
                  child: Icon(
                    showPlay ? LucideIcons.play : LucideIcons.pause,
                    color: AppColors.white,
                    size: 22.0,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SeekSlider extends StatelessWidget {
  const _SeekSlider({required this.player, required this.notifier});

  final AudioPlayer player;
  final RecordingPlayerNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return StreamBuilder<Duration>(
      stream: player.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final duration = player.duration ?? Duration.zero;
        final maxVal = duration.inMilliseconds.toDouble();
        return SliderTheme(
          data: SliderThemeData(
            trackHeight: 4.0,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7.0),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
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
            onChangeStart: (_) => player.pause(),
            onChanged: (value) {
              notifier.seek(Duration(milliseconds: value.toInt()));
            },
          ),
        );
      },
    );
  }
}

class _PositionLabel extends StatelessWidget {
  const _PositionLabel({required this.player});

  final AudioPlayer player;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return StreamBuilder<Duration>(
      stream: player.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        return Text(
          formatDurationFromDuration(position),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontSize: 12.0,
            color: colors.foreground,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        );
      },
    );
  }
}

class _DurationLabel extends StatelessWidget {
  const _DurationLabel({required this.player});

  final AudioPlayer player;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return StreamBuilder<Duration?>(
      stream: player.durationStream,
      builder: (context, snapshot) {
        final duration = snapshot.data ?? Duration.zero;
        return Text(
          formatDurationFromDuration(duration),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontSize: 12.0,
            color: colors.foreground.withValues(alpha: 0.6),
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        );
      },
    );
  }
}
