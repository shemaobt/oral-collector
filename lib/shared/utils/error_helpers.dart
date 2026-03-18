import 'dart:convert';

/// Converts raw technical error strings into user-friendly messages.
String friendlyErrorMessage(String raw) {
  final lower = raw.toLowerCase();

  // Strip common prefixes
  var message = raw
      .replaceFirst(RegExp(r'^Exception:\s*', caseSensitive: false), '')
      .replaceFirst(
        RegExp(r'^ClientException[^:]*:\s*', caseSensitive: false),
        '',
      )
      .trim();

  // Network / connectivity errors
  if (lower.contains('socketexception') ||
      lower.contains('socket') && lower.contains('failed') ||
      lower.contains('host lookup') ||
      lower.contains('connection refused') ||
      lower.contains('connection reset') ||
      lower.contains('network is unreachable') ||
      lower.contains('no address associated') ||
      lower.contains('errno')) {
    return 'Unable to reach the server. Please check your internet connection and try again.';
  }

  if (lower.contains('handshakeexception') ||
      lower.contains('certificate') ||
      lower.contains('ssl') ||
      lower.contains('tls')) {
    return 'A secure connection could not be established. Please try again later.';
  }

  if (lower.contains('timeout') || lower.contains('timed out')) {
    return 'The request timed out. Please check your connection and try again.';
  }

  // Auth-related: try to parse JSON body from "Login failed: {...}" style
  final jsonMatch = RegExp(
    r'(?:Login|Signup|Token refresh|failed)[^{]*(\{.+\})',
  ).firstMatch(message);
  if (jsonMatch != null) {
    try {
      final body = jsonDecode(jsonMatch.group(1)!) as Map<String, dynamic>;
      final detail = body['detail'] ?? body['message'] ?? body['error'];
      if (detail is String) {
        return _humanizeDetail(detail);
      }
    } on FormatException {
      // not valid JSON, fall through
    }
  }

  // Specific known error prefixes
  if (lower.contains('login failed')) {
    return 'Invalid email or password. Please try again.';
  }
  if (lower.contains('signup failed')) {
    return 'Could not create your account. Please check your details and try again.';
  }
  if (lower.contains('token refresh failed')) {
    return 'Your session has expired. Please sign in again.';
  }
  if (lower.contains('failed to get user')) {
    return 'Could not load your profile. Please try again.';
  }
  if (lower.contains('failed to update profile')) {
    return 'Could not update your profile. Please try again.';
  }
  if (lower.contains('failed to upload image')) {
    return 'Could not upload the image. Please try again.';
  }
  if (lower.contains('not authenticated')) {
    return 'You are not signed in. Please log in and try again.';
  }
  if (lower.contains('permission') || lower.contains('forbidden')) {
    return 'You don\'t have permission to perform this action.';
  }

  // If it's still a raw-looking technical message, return a generic one
  if (message.contains('Exception') ||
      message.contains('uri=') ||
      message.contains('errno') ||
      message.length > 120) {
    return 'Something went wrong. Please try again later.';
  }

  // Otherwise return the cleaned message as-is (it's likely already readable)
  return message;
}

String _humanizeDetail(String detail) {
  final lower = detail.toLowerCase();
  if (lower.contains('invalid credentials')) {
    return 'Invalid email or password. Please try again.';
  }
  if (lower.contains('user not found')) {
    return 'No account found with that email address.';
  }
  if (lower.contains('already exists') || lower.contains('duplicate')) {
    return 'An account with this email already exists.';
  }
  if (lower.contains('email') && lower.contains('required')) {
    return 'Please enter your email address.';
  }
  if (lower.contains('password') && lower.contains('required')) {
    return 'Please enter your password.';
  }
  // Return the server detail as-is if it looks human-readable
  if (detail.length < 100 && !detail.contains('{')) {
    return detail;
  }
  return 'Something went wrong. Please try again later.';
}
