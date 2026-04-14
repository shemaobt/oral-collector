import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../notifiers/input_device_notifier.dart';

class InputDevicePickerSheet extends ConsumerStatefulWidget {
  const InputDevicePickerSheet({super.key});

  @override
  ConsumerState<InputDevicePickerSheet> createState() =>
      _InputDevicePickerSheetState();
}

class _InputDevicePickerSheetState
    extends ConsumerState<InputDevicePickerSheet> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(inputDeviceNotifierProvider.notifier).refresh(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(inputDeviceNotifierProvider);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colors.border.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
            child: Row(
              children: [
                Icon(LucideIcons.mic, size: 20, color: colors.foreground),
                const SizedBox(width: 10),
                Text(
                  l10n.recording_selectMicrophone,
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
          ),
          if (state.isEnumerating)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: CircularProgressIndicator(),
            )
          else ...[
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: [
                  _DeviceRow(
                    label: l10n.recording_builtInMicrophone,
                    isSelected: state.selectedDeviceId == null,
                    onTap: () async {
                      await ref
                          .read(inputDeviceNotifierProvider.notifier)
                          .setSelected(null);
                      if (!mounted) return;
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    colors: colors,
                    theme: theme,
                  ),
                  for (final device in state.availableDevices)
                    if (device.label.isNotEmpty)
                      _DeviceRow(
                        label: device.label,
                        isSelected: device.id == state.selectedDeviceId,
                        onTap: () async {
                          await ref
                              .read(inputDeviceNotifierProvider.notifier)
                              .setSelected(device.id);
                          if (!mounted) return;
                          if (context.mounted) Navigator.of(context).pop();
                        },
                        colors: colors,
                        theme: theme,
                      ),
                  if (state.permissionNotYetGranted)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.recording_micPermissionNeeded,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.secondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          FilledButton(
                            onPressed: () {
                              ref
                                  .read(inputDeviceNotifierProvider.notifier)
                                  .requestPermissionThenRefresh();
                            },
                            child: Text(l10n.recording_micPermissionButton),
                          ),
                        ],
                      ),
                    ),
                  if (state.permissionDenied)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                      child: Text(
                        l10n.recording_micPermissionDenied,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.error,
                        ),
                      ),
                    )
                  else if (state.availableDevices
                          .where((d) => d.label.isNotEmpty)
                          .isEmpty &&
                      !state.permissionNotYetGranted)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        l10n.recording_noDevicesFound,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.secondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

class _DeviceRow extends StatelessWidget {
  const _DeviceRow({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.colors,
    required this.theme,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final AppColorSet colors;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (isSelected)
                Icon(LucideIcons.check, size: 18, color: colors.accent),
            ],
          ),
        ),
      ),
    );
  }
}
