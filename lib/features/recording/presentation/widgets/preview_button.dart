import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';

class PreviewButton extends StatefulWidget {
  const PreviewButton({
    super.key,
    required this.player,
    required this.onPlay,
    required this.onStop,
  });

  final AudioPlayer player;
  final VoidCallback onPlay;
  final VoidCallback onStop;

  @override
  State<PreviewButton> createState() => _PreviewButtonState();
}

class _PreviewButtonState extends State<PreviewButton> {
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
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _isPlaying ? widget.onStop : widget.onPlay,
        icon: Icon(
          _isPlaying ? LucideIcons.square : LucideIcons.play,
          size: 18,
        ),
        label: Text(_isPlaying ? 'Stop Preview' : 'Preview Selection'),
        style: FilledButton.styleFrom(
          backgroundColor: colors.accent.withValues(alpha: isDark ? 0.18 : 0.1),
          foregroundColor: colors.accent,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
