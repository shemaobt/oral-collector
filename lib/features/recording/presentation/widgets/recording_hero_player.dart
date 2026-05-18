import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/platform/file_ops.dart' as file_ops;
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/audio_player_widget.dart';

class RecordingHeroPlayer extends StatefulWidget {
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
  State<RecordingHeroPlayer> createState() => _RecordingHeroPlayerState();
}

class _RecordingHeroPlayerState extends State<RecordingHeroPlayer> {
  late Future<Widget> _playerFuture;
  late String _cacheKey;
  String _noAudioLabel = '';

  String _keyFor(LocalRecording r) => '${r.localFilePath}|${r.gcsUrl ?? ''}';

  Future<Widget> _resolvePlayer() async {
    final recording = widget.recording;
    final effectiveGcsUrl =
        (recording.gcsUrl != null && recording.gcsUrl!.isNotEmpty)
        ? recording.gcsUrl
        : null;

    if (!kIsWeb && recording.localFilePath.isNotEmpty) {
      final exists = await file_ops.fileExists(recording.localFilePath);
      if (exists) {
        return AudioPlayerWidget(
          filePath: recording.localFilePath,
          url: effectiveGcsUrl,
        );
      }
    }
    if (effectiveGcsUrl != null) {
      return AudioPlayerWidget(url: effectiveGcsUrl);
    }
    return Text(
      _noAudioLabel,
      style: TextStyle(color: widget.colors.secondary, fontSize: 14),
    );
  }

  @override
  void initState() {
    super.initState();
    _cacheKey = _keyFor(widget.recording);
    _playerFuture = _resolvePlayer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _noAudioLabel = AppLocalizations.of(context).recording_noAudioAvailable;
  }

  @override
  void didUpdateWidget(covariant RecordingHeroPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextKey = _keyFor(widget.recording);
    if (nextKey != _cacheKey) {
      _cacheKey = nextKey;
      _playerFuture = _resolvePlayer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 700;
    final colors = widget.colors;

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
                    Expanded(child: _buildPlayer()),
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
                    _buildPlayer(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildPlayer() {
    final colors = widget.colors;
    return FutureBuilder<Widget>(
      future: _playerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
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
        return snapshot.data ??
            Text(
              _noAudioLabel,
              style: TextStyle(color: colors.secondary, fontSize: 14),
            );
      },
    );
  }
}
