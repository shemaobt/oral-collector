import 'package:flutter/foundation.dart' show kReleaseMode;

import 'url_policy.dart';

abstract class Env {
  static const _productionUrl = 'https://tripod-backend.shemaywam.com';
  // Debug/profile override via `--dart-define=BACKEND_URL=...` or
  // `--dart-define-from-file=.env`; release stays pinned to production.
  static const _override = String.fromEnvironment('BACKEND_URL');

  static String get backendUrl {
    if (kReleaseMode) return _productionUrl;
    final override = _override.trim();
    final url = override.isEmpty ? _productionUrl : override;
    assertHttpsUrl(url);
    return url;
  }
}
