import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

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

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    if (_isRasterUrl) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(avatarUrl!),
        backgroundColor: colors.accent.withValues(alpha: 0.15),
        onBackgroundImageError: (_, _) {},
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: colors.accent.withValues(alpha: 0.15),
      child: Text(
        _initials,
        style: TextStyle(
          fontSize: radius * 0.65,
          fontWeight: FontWeight.w800,
          color: colors.accent,
        ),
      ),
    );
  }
}
