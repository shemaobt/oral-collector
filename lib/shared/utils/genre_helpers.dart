import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';

IconData mapGenreIcon(String? iconName) {
  switch (iconName) {
    case 'book-open':
      return LucideIcons.bookOpen;
    case 'message-circle':
      return LucideIcons.messageCircle;
    case 'music':
      return LucideIcons.music;
    case 'users':
      return LucideIcons.users;
    case 'list-ordered':
      return LucideIcons.listOrdered;
    case 'heart':
      return LucideIcons.heart;
    case 'file-text':
      return LucideIcons.fileText;
    case 'megaphone':
      return LucideIcons.megaphone;
    case 'clipboard-list':
      return LucideIcons.clipboardList;
    case 'lightbulb':
      return LucideIcons.lightbulb;
    case 'mic':
      return LucideIcons.mic;
    default:
      return LucideIcons.layoutGrid;
  }
}

Color parseHexColor(String? hex, [Color fallback = AppColors.primary]) {
  if (hex == null || hex.length < 7) return fallback;
  try {
    final hexValue = hex.replaceFirst('#', '');
    return Color(int.parse('FF$hexValue', radix: 16));
  } catch (_) {
    return fallback;
  }
}
