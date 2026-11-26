import 'dart:async';

import 'package:flutter/widgets.dart';

import '../web/reduced_motion.dart';

class AppFrame extends StatefulWidget {
  const AppFrame({
    super.key,
    required this.child,
    this.browserReducedMotion = watchPrefersReducedMotion,
  });

  final Widget child;
  final Stream<bool> Function() browserReducedMotion;

  @override
  State<AppFrame> createState() => _AppFrameState();
}

class _AppFrameState extends State<AppFrame> with WidgetsBindingObserver {
  static const double _maxTextScale = 2.0;

  StreamSubscription<bool>? _browser;
  bool _browserReduces = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _browser = widget.browserReducedMotion().listen((reduces) {
      setState(() => _browserReduces = reduces);
    });
  }

  @override
  void didChangeAccessibilityFeatures() => setState(() {});

  @override
  void dispose() {
    _browser?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final phoneReduces = WidgetsBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .reduceMotion;
    return MediaQuery(
      data: media.copyWith(
        disableAnimations:
            media.disableAnimations || phoneReduces || _browserReduces,
      ),
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: _maxTextScale,
        child: widget.child,
      ),
    );
  }
}
