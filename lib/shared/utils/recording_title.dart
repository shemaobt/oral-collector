import 'package:intl/intl.dart' as intl;

String defaultRecordingTitle({String? locale}) {
  final now = DateTime.now();
  final day = intl.DateFormat.EEEE(locale).format(now);
  final h = now.hour.toString().padLeft(2, '0');
  final m = now.minute.toString().padLeft(2, '0');
  final s = now.second.toString().padLeft(2, '0');
  return '$day $h:$m:$s';
}

String resolveRecordingTitle(String? input, {String? locale}) {
  final trimmed = input?.trim() ?? '';
  if (trimmed.isEmpty) return defaultRecordingTitle(locale: locale);
  return trimmed;
}
