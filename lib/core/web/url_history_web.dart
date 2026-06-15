import 'package:web/web.dart' as web;

import 'url_query.dart';

/// Removes [key] from the current address-bar URL via `history.replaceState`, so
/// a sensitive value (e.g. a password-reset token) is not retained in browser
/// history / back-forward navigation or leaked via the Referer header on later
/// navigations.
void stripUrlQueryParam(String key) {
  final cleaned = cleanedLocationWithout(web.window.location.href, key);
  if (cleaned == null) return;
  web.window.history.replaceState(web.window.history.state, '', cleaned);
}
