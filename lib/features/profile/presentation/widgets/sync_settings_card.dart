import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/format.dart';
import '../../../../shared/widgets/icon_box.dart';
import '../../../sync/presentation/notifiers/sync_state.dart';

class SyncSettingsCard extends StatelessWidget {
  const SyncSettingsCard({
    super.key,
    required this.syncState,
    required this.theme,
    required this.colors,
    required this.onSyncNow,
    required this.onWifiOnlyChanged,
    required this.onAutoRemoveChanged,
    required this.onClearCache,
  });

  final SyncState syncState;
  final ThemeData theme;
  final AppColorSet colors;
  final VoidCallback onSyncNow;
  final ValueChanged<bool> onWifiOnlyChanged;
  final ValueChanged<bool> onAutoRemoveChanged;
  final VoidCallback onClearCache;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          ListTile(
            leading: IconBox(
              icon: syncState.isOnline ? LucideIcons.wifi : LucideIcons.wifiOff,
              color: syncState.isOnline ? colors.success : colors.error,
            ),
            title: Text(syncState.isOnline ? 'Online' : 'Offline'),
            subtitle: syncState.lastSyncAt != null
                ? Text('Last sync: ${formatTimeAgo(syncState.lastSyncAt!)}')
                : const Text('Never synced'),
            trailing: syncState.pendingCount > 0
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${syncState.pendingCount} pending',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                : null,
          ),
          const Divider(height: 1),

          ListTile(
            leading: syncState.uploadingId != null
                ? Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.accent,
                        ),
                      ),
                    ),
                  )
                : IconBox(icon: LucideIcons.refreshCw, color: colors.accent),
            title: Text(
              syncState.uploadingId != null
                  ? 'Syncing... ${syncState.syncProgress}%'
                  : 'Sync Now',
            ),
            subtitle: syncState.uploadingId != null
                ? Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: syncState.syncProgress / 100,
                        backgroundColor: colors.border.withValues(alpha: 0.2),
                        color: colors.accent,
                        minHeight: 4,
                      ),
                    ),
                  )
                : null,
            enabled:
                syncState.isOnline &&
                syncState.uploadingId == null &&
                syncState.pendingCount > 0,
            onTap: onSyncNow,
          ),
          const Divider(height: 1),

          SwitchListTile(
            secondary: IconBox(
              icon: LucideIcons.signal,
              color: colors.secondary,
              alpha: 0.1,
            ),
            title: const Text('Upload on Wi-Fi only'),
            subtitle: const Text('Prevent uploads over cellular data'),
            value: syncState.autoUploadWifiOnly,
            onChanged: onWifiOnlyChanged,
          ),
          const Divider(height: 1),

          SwitchListTile(
            secondary: IconBox(
              icon: LucideIcons.trash2,
              color: colors.secondary,
              alpha: 0.1,
            ),
            title: const Text('Auto-remove after upload'),
            subtitle: const Text('Delete local files after successful upload'),
            value: syncState.autoRemoveAfterUpload,
            onChanged: onAutoRemoveChanged,
          ),
          const Divider(height: 1),

          ListTile(
            leading: IconBox(
              icon: LucideIcons.eraser,
              color: colors.error,
              alpha: 0.1,
            ),
            title: Text(
              'Clear local cache',
              style: theme.textTheme.bodyLarge?.copyWith(color: colors.error),
            ),
            subtitle: const Text('Delete all locally stored recordings'),
            onTap: onClearCache,
          ),
        ],
      ),
    );
  }
}
