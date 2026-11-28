import 'package:flutter/widgets.dart';

enum ShellTab { home, record, recordings, projects, profile, admin }

class TabVisits extends InheritedWidget {
  const TabVisits({
    super.key,
    required this.counts,
    required this.arrivals,
    required super.child,
  });

  final Map<ShellTab, int> counts;
  final Map<ShellTab, int> arrivals;

  static TabVisits? _of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TabVisits>();

  static int of(BuildContext context, ShellTab tab) =>
      _of(context)?.counts[tab] ?? 0;

  static int arrivalsOf(BuildContext context, ShellTab tab) =>
      _of(context)?.arrivals[tab] ?? 0;

  @override
  bool updateShouldNotify(TabVisits oldWidget) =>
      oldWidget.counts != counts || oldWidget.arrivals != arrivals;
}

mixin RefreshOnReturn<T extends StatefulWidget> on State<T> {
  ShellTab get tab;

  void refreshOnReturn();

  void onArrival() {}

  int? _seenVisits;
  int? _seenArrivals;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visits = TabVisits.of(context, tab);
    final arrivals = TabVisits.arrivalsOf(context, tab);
    final returned = _seenVisits != null && visits > _seenVisits!;
    final arrived = _seenArrivals != null && arrivals > _seenArrivals!;
    _seenVisits = visits;
    _seenArrivals = arrivals;
    if (!returned) return;
    Future.microtask(() {
      if (!mounted) return;
      if (arrived) onArrival();
      refreshOnReturn();
    });
  }
}
