import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
