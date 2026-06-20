import 'dart:convert';

import '../../../l10n/app_localizations.dart';
import '../../core/errors/app_exception.dart';

String friendlyErrorMessage(String raw, AppLocalizations l10n) {
  final lower = raw.toLowerCase();

  final message = raw
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
  if (lower.contains('not authenticated') ||
      lower.contains('session expired') ||
      lower.contains('unauthorized')) {
    return l10n.error_notAuthenticated;
  }
  if (lower.contains('permission') || lower.contains('forbidden')) {
    return l10n.error_noPermission;
  }

  if (lower.contains('has no bytes') ||
      lower.contains('file is empty') ||
      lower.contains('file not found')) {
    return l10n.error_importNoBytes;
  }

  if (lower.contains('ffmpeg failed') ||
      lower.contains('concatenation failed') ||
      lower.contains('audio processing')) {
    return l10n.error_ffmpegProcessingFailed;
  }

  if (lower.contains('download failed')) {
    return l10n.error_downloadFailed;
  }

  if (lower.contains('upload failed')) {
    return l10n.error_serverFailure;
  }

  if (lower.startsWith('failed to list') ||
      lower.startsWith('failed to fetch') ||
      lower.startsWith('failed to load') ||
      lower.startsWith('failed to create') ||
      lower.startsWith('failed to recreate') ||
      lower.startsWith('failed to update') ||
      lower.startsWith('failed to delete') ||
      lower.startsWith('failed to remove') ||
      lower.startsWith('failed to send invite') ||
      lower.startsWith('failed to accept invite') ||
      lower.startsWith('failed to decline invite') ||
      lower.startsWith('failed to trigger cleaning') ||
      lower.startsWith('failed to clear') ||
      lower.startsWith('password reset failed') ||
      lower.startsWith('reset password failed') ||
      lower.contains('client error') ||
      lower.contains('server error') ||
      lower.contains('auth error') ||
      RegExp(r'\bfailed\s*\(\d{3}\)').hasMatch(lower)) {
    return l10n.error_serverFailure;
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
