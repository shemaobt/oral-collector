import 'dart:convert';

import '../../../l10n/app_localizations.dart';
import '../../core/errors/app_exception.dart';

final _exceptionPrefixRe = RegExp(r'^Exception:\s*', caseSensitive: false);
final _clientExceptionPrefixRe = RegExp(
  r'^ClientException[^:]*:\s*',
  caseSensitive: false,
);
final _jsonDetailRe = RegExp(
  r'(?:Login|Signup|Token refresh|failed)[^{]*(\{.+\})',
);
final _failedCodeRe = RegExp(r'\bfailed\s*\(\d{3}\)');

String friendlyErrorMessage(String raw, AppLocalizations l10n) {
  final probe = _Probe(raw);
  for (final matcher in _matchers) {
    final hit = matcher(probe, l10n);
    if (hit != null) return hit;
  }
  return probe.cleaned;
}

/// Normalized views of a raw error string. Branch matchers test [lower] (the
/// un-stripped original, lowercased); the JSON regex, the generic fallback and
/// the verbatim return use [cleaned] (the `Exception:`/`ClientException...:`
/// prefix stripped + trimmed). Keeping both is load-bearing — see ENG-184.
class _Probe {
  _Probe(String raw)
    : lower = raw.toLowerCase(),
      cleaned = raw
          .replaceFirst(_exceptionPrefixRe, '')
          .replaceFirst(_clientExceptionPrefixRe, '')
          .trim();

  final String lower;
  final String cleaned;
}

typedef _Matcher = String? Function(_Probe probe, AppLocalizations l10n);

_Matcher _containsAny(
  List<String> tokens,
  String Function(AppLocalizations) message,
) =>
    (probe, l10n) => tokens.any(probe.lower.contains) ? message(l10n) : null;

_Matcher _containsAll(
  List<String> tokens,
  String Function(AppLocalizations) message,
) =>
    (probe, l10n) => tokens.every(probe.lower.contains) ? message(l10n) : null;

/// Ordered, first-match-wins rules. Order is load-bearing: JSON-detail before
/// the plain login/signup branches; import-no-bytes before upload (ENG-184);
/// network before secure/timeout; specific `... failed` before the server
/// bucket. Do not reorder or dedupe tokens.
final List<_Matcher> _matchers = <_Matcher>[
  _containsAny([
    'socketexception',
    'host lookup',
    'connection refused',
    'connection reset',
    'network is unreachable',
    'no address associated',
    'errno',
  ], (l10n) => l10n.error_network),
  _containsAll(['socket', 'failed'], (l10n) => l10n.error_network),
  _containsAny([
    'handshakeexception',
    'certificate',
    'ssl',
    'tls',
  ], (l10n) => l10n.error_secureConnection),
  _containsAny(['timeout', 'timed out'], (l10n) => l10n.error_timeout),
  _matchJsonDetail,
  _containsAny(['login failed'], (l10n) => l10n.error_invalidCredentials),
  _containsAny(['signup failed'], (l10n) => l10n.error_signupFailed),
  _containsAny(['token refresh failed'], (l10n) => l10n.error_sessionExpired),
  _containsAny(['failed to get user'], (l10n) => l10n.error_profileLoadFailed),
  _containsAny([
    'failed to update profile',
  ], (l10n) => l10n.error_profileUpdateFailed),
  _containsAny([
    'failed to upload image',
  ], (l10n) => l10n.error_imageUploadFailed),
  _containsAny([
    'not authenticated',
    'session expired',
    'unauthorized',
  ], (l10n) => l10n.error_notAuthenticated),
  _containsAny(['permission', 'forbidden'], (l10n) => l10n.error_noPermission),
  _containsAny([
    'has no bytes',
    'file is empty',
    'file not found',
  ], (l10n) => l10n.error_importNoBytes),
  _containsAny([
    'ffmpeg failed',
    'concatenation failed',
    'audio processing',
  ], (l10n) => l10n.error_ffmpegProcessingFailed),
  _containsAny(['download failed'], (l10n) => l10n.error_downloadFailed),
  _containsAny(['upload failed'], (l10n) => l10n.error_serverFailure),
  _matchServerFailure,
  _matchGeneric,
];

String? _matchJsonDetail(_Probe probe, AppLocalizations l10n) {
  final match = _jsonDetailRe.firstMatch(probe.cleaned);
  if (match == null) return null;
  try {
    final body = jsonDecode(match.group(1)!) as Map<String, dynamic>;
    final detail = body['detail'] ?? body['message'] ?? body['error'];
    if (detail is String) return _humanizeDetail(detail, l10n);
  } on FormatException {
    // not valid JSON, fall through
  }
  return null;
}

String? _matchServerFailure(_Probe probe, AppLocalizations l10n) {
  const prefixes = [
    'failed to list',
    'failed to fetch',
    'failed to load',
    'failed to create',
    'failed to recreate',
    'failed to update',
    'failed to delete',
    'failed to remove',
    'failed to send invite',
    'failed to accept invite',
    'failed to decline invite',
    'failed to trigger cleaning',
    'failed to clear',
    'password reset failed',
    'reset password failed',
  ];
  const substrings = ['client error', 'server error', 'auth error'];
  final lower = probe.lower;
  if (prefixes.any(lower.startsWith) ||
      substrings.any(lower.contains) ||
      _failedCodeRe.hasMatch(lower)) {
    return l10n.error_serverFailure;
  }
  return null;
}

String? _matchGeneric(_Probe probe, AppLocalizations l10n) {
  final message = probe.cleaned;
  if (message.contains('Exception') ||
      message.contains('uri=') ||
      message.contains('errno') ||
      message.length > 120) {
    return l10n.error_generic;
  }
  return null;
}

String _humanizeDetail(String detail, AppLocalizations l10n) {
  final lower = detail.toLowerCase();
  if (lower.contains('invalid credentials')) {
    return l10n.error_invalidCredentials;
  }
  if (lower.contains('user not found')) {
    return l10n.error_userNotFound;
  }
  if (lower.contains('already exists') || lower.contains('duplicate')) {
    return l10n.error_accountExists;
  }
  if (lower.contains('email') && lower.contains('required')) {
    return l10n.error_emailRequired;
  }
  if (lower.contains('password') && lower.contains('required')) {
    return l10n.error_passwordRequired;
  }
  if (detail.length < 100 && !detail.contains('{')) {
    return detail;
  }
  return l10n.error_generic;
}

/// Localizes any error for display: typed AppException first, then the legacy
/// string-matching fallback for untyped errors.
String friendlyErrorFor(Object error, AppLocalizations l10n) {
  if (error is AppException) return messageForException(error, l10n);
  return friendlyErrorMessage(error.toString(), l10n);
}

/// Exhaustive map from a domain exception to a localized message. Adding a leaf
/// to AppException (e.g. ENG-147 ParseException) breaks compilation here until a
/// case is added.
String messageForException(AppException e, AppLocalizations l10n) {
  return switch (e) {
    NetworkException() => l10n.error_network,
    TimeoutException() => l10n.error_timeout,
    UnauthorizedException() => l10n.error_notAuthenticated,
    ForbiddenException() => l10n.error_noPermission,
    ConflictException() => l10n.error_serverFailure,
    ValidationException() => l10n.error_generic,
    ParseException() => l10n.error_generic,
    ServerException() => l10n.error_serverFailure,
  };
}
