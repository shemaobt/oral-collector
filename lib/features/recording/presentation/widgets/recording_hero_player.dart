import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/audio_player_widget.dart';
import 'package:lucide_icons/lucide_icons.dart';

class RecordingHeroPlayer extends StatelessWidget {
  const RecordingHeroPlayer({
    super.key,
    required this.recording,
    required this.colors,
    required this.theme,
  });

  final LocalRecording recording;
  final AppColorSet colors;
  final ThemeData theme;

  Future<Widget> _resolvePlayer() async {
    if (recording.localFilePath.isNotEmpty) {
      final exists = await File(recording.localFilePath).exists();
      if (exists) {
        return AudioPlayerWidget(filePath: recording.localFilePath);
      }
    }
    if (recording.gcsUrl != null) {
      return AudioPlayerWidget(url: recording.gcsUrl);
    }
    return Text(
      'No audio available',
      style: TextStyle(color: colors.secondary, fontSize: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colors.accent.withValues(alpha: 0.15), colors.background],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
          child: Column(
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
              FutureBuilder<Widget>(
                future: _resolvePlayer(),
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
                        'No audio available',
                        style: TextStyle(color: colors.secondary, fontSize: 14),
                      );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
