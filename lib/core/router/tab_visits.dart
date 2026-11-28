import 'package:flutter/widgets.dart';

enum ShellTab { home, record, recordings, projects, profile, admin }

class TabVisits extends InheritedWidget {
  const TabVisits({super.key, required this.counts, required super.child});

  final Map<ShellTab, int> counts;

  static int of(BuildContext context, ShellTab tab) =>
      context.dependOnInheritedWidgetOfExactType<TabVisits>()?.counts[tab] ?? 0;

  @override
  bool updateShouldNotify(TabVisits oldWidget) => oldWidget.counts != counts;
}
