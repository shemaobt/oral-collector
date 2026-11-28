import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/utils/format.dart';
import '../../../../shared/widgets/app_tile.dart';
import '../../../../shared/widgets/brush_sign.dart';
import '../../../../shared/widgets/round_button.dart';
import '../notifiers/recording_player_notifier.dart';
import 'playback_key_handler.dart';
import 'seek_wave.dart';

const _barHeight = 64.0;
const _gap = 14.0;
const _minWaveWidth = 72.0;
final _discSlack =
    (RoundButton.minTouchTarget - RoundButtonSize.small.diameter) / 2;

class RecordingPlayerControls extends ConsumerWidget {
  const RecordingPlayerControls({super.key, required this.recordingId});

  final String recordingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(recordingPlayerProvider(recordingId).notifier);
    final player = notifier.audioPlayer();

    return PlaybackKeyHandler(
      onSpace: notifier.togglePlay,
      child: AppTile(
        radius: 18,
        padding: EdgeInsetsDirectional.only(start: 10 - _discSlack, end: 18),
        child: SizedBox(
          height: _barHeight,
          child: Row(
            children: [
              _PlayPauseDisc(player: player, onTap: notifier.togglePlay),
              SizedBox(width: _gap - _discSlack),
              Expanded(
                child: _WaveAndTime(
                  player: player,
                  onSeek: (position) {
                    player.pause();
                    notifier.seek(position);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayPauseDisc extends StatelessWidget {
  const _PlayPauseDisc({required this.player, required this.onTap});

  final AudioPlayer player;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return StreamBuilder<PlayerState>(
      stream: player.playerStateStream,
      builder: (context, snapshot) {
        final playerState = snapshot.data;
        final showPlay =
            playerState?.processingState == ProcessingState.completed ||
            !(playerState?.playing ?? false);
        return RoundButton.sign(
          sign: showPlay ? Sign.play : Sign.pause,
          semanticLabel: showPlay ? l10n.a11y_playAudio : l10n.a11y_pauseAudio,
          size: RoundButtonSize.small,
          onPressed: onTap,
        );
      },
    );
  }
}

class _WaveAndTime extends StatelessWidget {
  const _WaveAndTime({required this.player, required this.onSeek});

  final AudioPlayer player;
  final ValueChanged<Duration> onSeek;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.w600,
      color: AppColors.of(context).primary,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return StreamBuilder<Duration?>(
      stream: player.durationStream,
      builder: (context, durationSnapshot) {
        final duration = durationSnapshot.data ?? Duration.zero;
        return StreamBuilder<Duration>(
          stream: player.positionStream,
          builder: (context, positionSnapshot) {
            final position = positionSnapshot.data ?? Duration.zero;
            final widest =
                '${formatClock(duration)} / ${formatClock(duration)}';
            final current =
                '${formatClock(position)} / ${formatClock(duration)}';
            return LayoutBuilder(
              builder: (context, constraints) => Row(
                children: [
                  Expanded(
                    child: SeekWave(
                      position: position,
                      duration: duration,
                      onSeek: onSeek,
                    ),
                  ),
                  const SizedBox(width: _gap),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: (constraints.maxWidth - _gap - _minWaveWidth)
                          .clamp(0.0, double.infinity),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Stack(
                        children: [
                          ExcludeSemantics(
                            child: Opacity(
                              opacity: 0,
                              child: Text(widest, style: style, maxLines: 1),
                            ),
                          ),
                          Text(current, style: style, maxLines: 1),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
