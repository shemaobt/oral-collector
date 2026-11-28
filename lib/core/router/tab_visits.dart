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

mixin RefreshOnReturn<T extends StatefulWidget> on State<T> {
  ShellTab get tab;

  void refreshOnReturn();

  int? _seenVisits;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visits = TabVisits.of(context, tab);
    final seen = _seenVisits;
    _seenVisits = visits;
    if (seen == null || visits <= seen) return;
    Future.microtask(() {
      if (mounted) refreshOnReturn();
    });
  }
}
