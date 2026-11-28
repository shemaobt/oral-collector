import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'hand_cut_disc.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.radius,
    this.avatarUrl,
    this.displayName,
    this.email,
  });

  final double radius;
  final String? avatarUrl;
  final String? displayName;
  final String? email;

  String get _initials {
    if (displayName != null && displayName!.isNotEmpty) {
      final parts = displayName!.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
      }
      return parts.first[0].toUpperCase();
    }
    if (email != null && email!.isNotEmpty) {
      return email![0].toUpperCase();
    }
    return '?';
  }

  bool get _isRasterUrl {
    if (avatarUrl == null || avatarUrl!.isEmpty) return false;

    if (avatarUrl!.toLowerCase().endsWith('.svg')) return false;
    return true;
  }

  static double _initialsSize(double diameter) {
    if (diameter <= 32) return 13;
    if (diameter <= 44) return 15;
    if (diameter <= 56) return 17;
    return 24;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final diameter = radius * 2;

    return SizedBox.square(
      dimension: diameter,
      child: CustomPaint(
        painter: HandCutDiscPainter(fill: colors.pale),
        child: _isRasterUrl
            ? ClipPath(
                clipper: const HandCutDiscClipper(),
                child: Image.network(
                  avatarUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              )
            : Center(
                child: Text(
                  _initials,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.02 * _initialsSize(diameter),
                    fontSize: _initialsSize(diameter),
                    color: colors.foreground,
                  ),
                ),
              ),
      ),
    );
  }
}
