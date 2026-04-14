import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/icon_box.dart';
import '../../../recording/presentation/notifiers/input_device_notifier.dart';
import '../../../recording/presentation/widgets/input_device_picker_sheet.dart';

class RecordingSettingsCard extends ConsumerStatefulWidget {
  const RecordingSettingsCard({
    super.key,
    required this.theme,
    required this.colors,
  });

  final ThemeData theme;
  final AppColorSet colors;

  @override
  ConsumerState<RecordingSettingsCard> createState() =>
      _RecordingSettingsCardState();
}

class _RecordingSettingsCardState extends ConsumerState<RecordingSettingsCard> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      ref.read(inputDeviceNotifierProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(inputDeviceNotifierProvider);
    final selected = state.selectedDevice;
    final subtitle = selected?.label.isNotEmpty == true
        ? selected!.label
        : l10n.profile_systemDefault;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: IconBox(
          icon: LucideIcons.mic,
          color: widget.colors.secondary,
          alpha: 0.1,
        ),
        title: Text(l10n.profile_defaultMicrophone),
        subtitle: Text(subtitle),
        trailing: Icon(
          LucideIcons.chevronRight,
          size: 18,
          color: widget.colors.secondary,
        ),
        onTap: () {
          showModalBottomSheet<void>(
            context: context,
            builder: (_) => const InputDevicePickerSheet(),
          );
        },
      ),
    );
  }
}
