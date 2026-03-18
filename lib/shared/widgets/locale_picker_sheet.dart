import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/l10n/locale_provider.dart';
import '../../core/l10n/supported_locales.dart';
import '../../core/theme/app_colors.dart';

class LocalePickerSheet extends ConsumerWidget {
  const LocalePickerSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final currentLocale = ref.watch(localeProvider);
    final currentCode = currentLocale?.languageCode ?? 'en';

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colors.border.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Choose Your Language', style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  'You can change this later in your profile settings.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.secondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...supportedLocales.map((locale) {
            final code = locale.languageCode;
            final nativeName = localeNativeNames[code] ?? code;
            final englishName = localeEnglishNames[code] ?? code;
            final isSelected = code == currentCode;

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.accent.withValues(alpha: 0.12)
                      : colors.surfaceAlt,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    code.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isSelected ? colors.accent : colors.secondary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
              title: Text(
                nativeName,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              subtitle: code != 'en'
                  ? Text(
                      englishName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.secondary,
                      ),
                    )
                  : null,
              trailing: isSelected
                  ? Icon(LucideIcons.check, size: 18, color: colors.accent)
                  : null,
              onTap: () {
                ref.read(localeProvider.notifier).setLocale(locale);
                Navigator.of(context).pop();
              },
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
