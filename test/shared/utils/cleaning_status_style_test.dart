import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:oral_collector/core/theme/app_colors.dart';
import 'package:oral_collector/l10n/app_localizations.dart';
import 'package:oral_collector/l10n/app_localizations_en.dart';
import 'package:oral_collector/shared/utils/cleaning_status_style.dart';

const _testColors = AppColorSet(
  primary: Color(0xFF000000),
  accent: Color(0xFFBE4A01),
  background: Color(0xFFFFFFFF),
  foreground: Color(0xFF222222),
  card: Color(0xFFEEEEEE),
  surfaceAlt: Color(0xFFDDDDDD),
  secondary: Color(0xFF333333),
  info: Color(0xFF444444),
  infoText: Color(0xFF555555),
  success: Color(0xFF008800),
  successText: Color(0xFF005500),
  onPrimary: Color(0xFFFFFFFF),
  chipSurface: Color(0xFFFFFFFF),
  border: Color(0xFFCCCCCC),
  error: Color(0xFFAA0000),
  warning: Color(0xFFFFAA00),
);

void main() {
  final AppLocalizations l10n = AppLocalizationsEn();

  group('CleaningStatusStyle.forStatus', () {
    test('needs_cleaning maps to the warning token', () {
      final style = CleaningStatusStyle.forStatus(
        'needs_cleaning',
        _testColors,
        l10n,
      );

      expect(style.icon, LucideIcons.alertCircle);
      expect(style.color, _testColors.warning);
      expect(style.label, l10n.cleaning_needsCleaning);
      expect(style.isFlagged, isTrue);
    });

    test('cleaning maps to the info token with the loader glyph', () {
      final style = CleaningStatusStyle.forStatus(
        'cleaning',
        _testColors,
        l10n,
      );

      expect(style.icon, LucideIcons.loader);
      expect(style.color, _testColors.info);
      expect(style.label, l10n.cleaning_cleaning);
      expect(style.isFlagged, isTrue);
    });

    test('cleaned maps to the success token', () {
      final style = CleaningStatusStyle.forStatus('cleaned', _testColors, l10n);

      expect(style.icon, LucideIcons.sparkles);
      expect(style.color, _testColors.success);
      expect(style.label, l10n.cleaning_cleaned);
      expect(style.isFlagged, isTrue);
    });

    test('failed maps to the error token', () {
      final style = CleaningStatusStyle.forStatus('failed', _testColors, l10n);

      expect(style.icon, LucideIcons.alertTriangle);
      expect(style.color, _testColors.error);
      expect(style.label, l10n.cleaning_cleanFailed);
      expect(style.isFlagged, isTrue);
    });

    test('none is not flagged and uses the neutral presentation', () {
      final style = CleaningStatusStyle.forStatus('none', _testColors, l10n);

      expect(style.icon, LucideIcons.minus);
      expect(style.color, _testColors.secondary);
      expect(style.label, l10n.detail_notFlagged);
      expect(style.isFlagged, isFalse);
    });

    test('an unknown status resolves identically to none', () {
      final unknown = CleaningStatusStyle.forStatus('bogus', _testColors, l10n);
      final none = CleaningStatusStyle.forStatus('none', _testColors, l10n);

      expect(unknown.icon, none.icon);
      expect(unknown.color, none.color);
      expect(unknown.label, none.label);
      expect(unknown.isFlagged, isFalse);
    });
  });
}
