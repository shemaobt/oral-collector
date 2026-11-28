import 'package:flutter/widgets.dart';

import '../../../core/router/tab_visits.dart';

class TabItem {
  const TabItem({required this.path, required this.label, required this.icon});

  final String path;
  final String label;
  final IconData icon;

  ShellTab get tab => ShellTab.values.byName(path.substring(1));
}
