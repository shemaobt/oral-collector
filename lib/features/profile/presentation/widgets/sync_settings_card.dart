import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/format.dart';
import '../../../../shared/widgets/icon_box.dart';
import '../../../sync/presentation/notifiers/sync_notifier.dart';
import '../../../sync/presentation/notifiers/sync_state.dart';

final _storageSnapshotProvider =
    FutureProvider.autoDispose<
      ({int usedBytes, int freeBytes, int totalBytes})
    >((ref) => ref.read(syncNotifierProvider.notifier).getStorageSnapshot());

class SyncSettingsCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          ListTile(
            leading: IconBox(
              icon: syncState.isOnline ? LucideIcons.wifi : LucideIcons.wifiOff,
              color: syncState.isOnline ? colors.success : colors.error,
            ),
            title: Text(
              syncState.isOnline ? l10n.profile_online : l10n.profile_offline,
            ),
            subtitle: syncState.lastSyncAt != null
                ? Text(
                    l10n.profile_lastSync(
                      formatTimeAgo(syncState.lastSyncAt!, l10n),
                    ),
                  )
                : Text(l10n.profile_neverSynced),
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
                      l10n.profile_pendingCount(syncState.pendingCount),
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
                  ? l10n.profile_syncingProgress(syncState.syncProgress)
                  : l10n.profile_syncNow,
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
            title: Text(l10n.profile_wifiOnly),
            subtitle: Text(l10n.profile_wifiOnlySubtitle),
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
            title: Text(l10n.profile_autoRemove),
            subtitle: Text(l10n.profile_autoRemoveSubtitle),
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
              l10n.profile_clearCache,
              style: theme.textTheme.bodyLarge?.copyWith(color: colors.error),
            ),
            subtitle: Text(l10n.profile_clearCacheSubtitle),
            onTap: onClearCache,
          ),
          if (!kIsWeb) ...[
            const Divider(height: 1),
            _DeviceStorageTile(theme: theme, colors: colors),
          ],
        ],
      ),
    );
  }
}

class _DeviceStorageTile extends ConsumerWidget {
  const _DeviceStorageTile({required this.theme, required this.colors});

  final ThemeData theme;
  final AppColorSet colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final snapshot = ref.watch(_storageSnapshotProvider);
    return ListTile(
      leading: IconBox(
        icon: LucideIcons.hardDrive,
        color: colors.secondary,
        alpha: 0.1,
      ),
      title: Text(l10n.settings_deviceStorageTitle),
      subtitle: snapshot.when(
        data: (data) {
          final used = formatFileSize(data.usedBytes);
          final free = formatFileSize(data.freeBytes);
          final fillRatio = data.totalBytes > 0
              ? ((data.totalBytes - data.freeBytes) / data.totalBytes).clamp(
                  0.0,
                  1.0,
                )
              : 0.0;
          return Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.settings_deviceStorageSubtitle(used, free)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: fillRatio,
                    backgroundColor: colors.border.withValues(alpha: 0.2),
                    color: colors.accent,
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.only(top: 6),
          child: SizedBox(height: 4, child: LinearProgressIndicator()),
        ),
        error: (_, _) => Text(
          '\u2014',
          style: theme.textTheme.bodySmall?.copyWith(color: colors.secondary),
        ),
      ),
    );
  }
}
