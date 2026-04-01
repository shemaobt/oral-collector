import 'dart:convert';

import '../../../l10n/app_localizations.dart';

String friendlyErrorMessage(String raw, AppLocalizations l10n) {
  final lower = raw.toLowerCase();

  var message = raw
      .replaceFirst(RegExp(r'^Exception:\s*', caseSensitive: false), '')
      .replaceFirst(
        RegExp(r'^ClientException[^:]*:\s*', caseSensitive: false),
        '',
      )
      .trim();

  if (lower.contains('socketexception') ||
      lower.contains('socket') && lower.contains('failed') ||
      lower.contains('host lookup') ||
      lower.contains('connection refused') ||
      lower.contains('connection reset') ||
      lower.contains('network is unreachable') ||
      lower.contains('no address associated') ||
      lower.contains('errno')) {
    return l10n.error_network;
  }

  if (lower.contains('handshakeexception') ||
      lower.contains('certificate') ||
      lower.contains('ssl') ||
      lower.contains('tls')) {
    return l10n.error_secureConnection;
  }

  if (lower.contains('timeout') || lower.contains('timed out')) {
    return l10n.error_timeout;
  }

  final jsonMatch = RegExp(
    r'(?:Login|Signup|Token refresh|failed)[^{]*(\{.+\})',
  ).firstMatch(message);
  if (jsonMatch != null) {
    try {
      final body = jsonDecode(jsonMatch.group(1)!) as Map<String, dynamic>;
      final detail = body['detail'] ?? body['message'] ?? body['error'];
      if (detail is String) {
        return _humanizeDetail(detail, l10n);
      }
    } on FormatException {
      // not valid JSON, fall through
    }
  }

  if (lower.contains('login failed')) {
    return l10n.error_invalidCredentials;
  }
  if (lower.contains('signup failed')) {
    return l10n.error_signupFailed;
  }
  if (lower.contains('token refresh failed')) {
    return l10n.error_sessionExpired;
  }
  if (lower.contains('failed to get user')) {
    return l10n.error_profileLoadFailed;
  }
  if (lower.contains('failed to update profile')) {
    return l10n.error_profileUpdateFailed;
  }
  if (lower.contains('failed to upload image')) {
    return l10n.error_imageUploadFailed;
  }
  if (lower.contains('not authenticated')) {
    return l10n.error_notAuthenticated;
  }
  if (lower.contains('permission') || lower.contains('forbidden')) {
    return l10n.error_noPermission;
  }

  if (message.contains('Exception') ||
      message.contains('uri=') ||
      message.contains('errno') ||
      message.length > 120) {
    return l10n.error_generic;
  }

  return message;
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
