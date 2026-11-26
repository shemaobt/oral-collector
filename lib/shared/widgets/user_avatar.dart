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
    final diameter = radius * 2;

    return Container(
      width: diameter,
      height: diameter,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.wood,
        image: _isRasterUrl
            ? DecorationImage(
                image: NetworkImage(avatarUrl!),
                fit: BoxFit.cover,
                onError: (_, _) {},
              )
            : null,
        boxShadow: [
          BoxShadow(color: colors.wood, spreadRadius: 4.5),
          BoxShadow(color: colors.background, spreadRadius: 3),
        ],
      ),
      child: _isRasterUrl
          ? null
          : Text(
              _initials,
              style: TextStyle(
                fontFamily: 'CaveatBrush',
                fontSize: diameter * 0.41,
                color: colors.primary,
              ),
            ),
    );
  }
}
