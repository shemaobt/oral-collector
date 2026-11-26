import 'dart:async';

import 'package:web/web.dart' as web;

Stream<bool> watchPrefersReducedMotion() async* {
  final query = web.window.matchMedia('(prefers-reduced-motion: reduce)');
  yield query.matches;
  yield* web.EventStreamProviders.changeEvent
      .forTarget(query)
      .map((_) => query.matches);
}
