import 'dart:async';

import 'package:web/web.dart' as web;

final _query = web.window.matchMedia('(prefers-reduced-motion: reduce)');

bool prefersReducedMotion() => _query.matches;

Stream<bool> watchPrefersReducedMotion() => web.EventStreamProviders.changeEvent
    .forTarget(_query)
    .map((_) => _query.matches);
