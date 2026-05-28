import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../notifiers/recording_player_notifier.dart';
import '../notifiers/recording_player_state.dart';
import 'recording_player_controls.dart';

class RecordingHeroPlayer extends ConsumerWidget {
  const RecordingHeroPlayer({
    super.key,
    required this.recording,
    required this.colors,
    required this.theme,
  });

  final LocalRecording recording;
  final AppColorSet colors;
  final ThemeData theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWide = MediaQuery.of(context).size.width >= 700;
    final state = ref.watch(recordingPlayerProvider(recording.id));

    return Container(
      decoration: isWide
          ? null
          : BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colors.accent.withValues(alpha: 0.15),
                  colors.background,
                ],
              ),
            ),
      child: SafeArea(
        bottom: false,
        top: !isWide,
        child: Padding(
          padding: isWide
              ? const EdgeInsets.symmetric(horizontal: 24, vertical: 12)
              : const EdgeInsets.fromLTRB(20, 60, 20, 20),
          child: isWide
              ? Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: colors.accent.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.activity,
                        size: 22,
                        color: colors.accent,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: _buildPlayer(context, state)),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: colors.accent.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.activity,
                        size: 32,
                        color: colors.accent,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildPlayer(context, state),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildPlayer(BuildContext context, RecordingPlayerState state) {
    if (state.isLoading) {
      return SizedBox(
        height: 72,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colors.primary,
            ),
          ),
        ),
      );
    }

    if (state.errorKind != null) {
      final l10n = AppLocalizations.of(context);
      final message = switch (state.errorKind!) {
        RecordingPlayerError.fileNotFound => l10n.recording_audioFileNotFound,
        RecordingPlayerError.loadFailed => l10n.recording_audioLoadFailed,
      };
      return SizedBox(
        height: 64,
        child: Center(
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.error,
              fontSize: 14.0,
            ),
          ),
        ),
      );
    }

    if (!state.hasAudio) {
      final l10n = AppLocalizations.of(context);
      return Text(
        l10n.recording_noAudioAvailable,
        style: TextStyle(color: colors.secondary, fontSize: 14),
      );
    }

    return RecordingPlayerControls(recordingId: recording.id);
  }
}
