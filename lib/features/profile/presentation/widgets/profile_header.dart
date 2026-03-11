import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/format.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../../auth/domain/entities/user.dart';
import 'info_badge.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.user,
    required this.isUploadingAvatar,
    required this.colors,
    required this.theme,
    required this.onPickAvatar,
    required this.onEditName,
  });

  final User? user;
  final bool isUploadingAvatar;
  final AppColorSet colors;
  final ThemeData theme;
  final VoidCallback onPickAvatar;
  final VoidCallback onEditName;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: isUploadingAvatar ? null : onPickAvatar,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colors.accent,
                      colors.accent.withValues(alpha: 0.6),
                      colors.primary,
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(3),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.background,
                  ),
                  padding: const EdgeInsets.all(3),
                  child: UserAvatar(
                    radius: 50,
                    avatarUrl: user?.avatarUrl,
                    displayName: user?.displayName,
                    email: user?.email,
                  ),
                ),
              ),

              if (isUploadingAvatar)
                Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

              if (!isUploadingAvatar)
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.accent,
                      border: Border.all(color: colors.background, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: colors.accent.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        LucideIcons.camera,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        GestureDetector(
          onTap: onEditName,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                user?.displayName ?? 'Set your name',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: user?.displayName != null ? null : colors.secondary,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                LucideIcons.pencil,
                size: 16,
                color: colors.secondary.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),

        const SizedBox(height: 4),

        if (user?.email != null)
          Text(
            user!.email,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.secondary,
            ),
          ),

        const SizedBox(height: 8),

        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InfoBadge(
              icon: LucideIcons.calendar,
              label: formatMemberSince(user?.createdAt),
              colors: colors,
              theme: theme,
            ),
            if (user?.role == 'admin') ...[
              const SizedBox(width: 8),
              InfoBadge(
                icon: LucideIcons.shield,
                label: 'Admin',
                colors: colors,
                theme: theme,
                accentColor: colors.accent,
              ),
            ],
          ],
        ),
      ],
    );
  }
}
