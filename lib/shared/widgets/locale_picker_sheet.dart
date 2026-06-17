import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/l10n/locale_provider.dart';
import '../../core/l10n/supported_locales.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';

class LocalePickerSheet extends ConsumerWidget {
  const LocalePickerSheet({super.key});

  String _localizedSubName(AppLocalizations l10n, String code) {
    switch (code) {
      case 'en':
        return l10n.locale_englishSub;
      case 'pt':
        return l10n.locale_portugueseSub;
      case 'es':
        return l10n.locale_spanishSub;
      case 'fr':
        return l10n.locale_frenchSub;
      case 'id':
        return l10n.locale_bahasaSub;
      case 'hi':
        return l10n.locale_hindiSub;
      case 'sw':
        return l10n.locale_swahiliSub;
      case 'ar':
        return l10n.locale_arabicSub;
      case 'tpi':
        return l10n.locale_tokPisinSub;
      case 'ko':
        return l10n.locale_koreanSub;
      case 'zh':
        return l10n.locale_chineseSub;
      default:
        return code;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final currentLocale = ref.watch(localeProvider);
    final currentCode = currentLocale?.languageCode ?? 'en';

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(
                top: SpacingScale.s12,
                bottom: SpacingScale.s16,
              ),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colors.border.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: SpacingScale.s24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.locale_selectLanguage,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: SpacingScale.s4),
                Text(
                  l10n.locale_selectLanguageSubtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.secondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: SpacingScale.s16),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              children: supportedLocales.map((locale) {
                final code = locale.languageCode;
                final nativeName = localeNativeNames[code] ?? code;
                final subName = _localizedSubName(l10n, code);
                final isSelected = code == currentCode;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: SpacingScale.s24,
                  ),
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
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                  subtitle: code != currentCode
                      ? Text(
                          subName,
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
              }).toList(),
            ),
          ),
          const SizedBox(height: SpacingScale.s16),
        ],
      ),
    );
  }
}
