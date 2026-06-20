import 'package:flutter/foundation.dart' show kReleaseMode;

/// Guards Dart-side networking against cleartext. `package:http` rides Dart's
/// `HttpClient`, which the platform cleartext policies (Android
/// network-security-config, iOS ATS) do not cover, so the scheme check lives
/// here. https is always allowed; outside release, http is allowed only for a
/// loopback or RFC1918 private-network host (local dev backends). (ENG-132)
bool isHttpsUrl(String url) {
  final uri = Uri.tryParse(url);
  return uri != null && _isAllowed(uri);
}

/// Throws [ArgumentError] when [url] is rejected by [isHttpsUrl]. The thrown
/// value is redacted to `scheme://host` (or `<unparseable>`) so a signed URL's
/// query/signature never reaches logs or crash reports.
void assertHttpsUrl(String url) {
  if (isHttpsUrl(url)) return;
  final uri = Uri.tryParse(url);
  final redacted = uri == null
      ? '<unparseable>'
      : '${uri.scheme}://${uri.host}';
  throw ArgumentError.value(redacted, 'url', 'must be https');
}

bool _isAllowed(Uri uri) {
  if (uri.scheme == 'https') return true;
  if (kReleaseMode || uri.scheme != 'http') return false;
  return _isLoopbackOrPrivateHost(uri.host);
}

bool _isLoopbackOrPrivateHost(String host) {
  if (host == 'localhost') return true;
  final parts = host.split('.');
  if (parts.length != 4) return false;
  final octets = <int>[];
  for (final part in parts) {
    final value = int.tryParse(part);
    if (value == null || value < 0 || value > 255) return false;
    octets.add(value);
  }
  final a = octets[0];
  final b = octets[1];
  return a == 127 || // loopback 127.0.0.0/8
      a == 10 || // 10.0.0.0/8
      (a == 172 && b >= 16 && b <= 31) || // 172.16.0.0/12
      (a == 192 && b == 168); // 192.168.0.0/16
}
