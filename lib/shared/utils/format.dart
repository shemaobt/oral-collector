import 'package:intl/intl.dart' as intl;

import '../../l10n/app_localizations.dart';

String formatDurationHMS(double totalSeconds) {
  final seconds = totalSeconds.round();
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  final mm = m.toString().padLeft(2, '0');
  final ss = s.toString().padLeft(2, '0');
  if (h > 0) return '$h:$mm:$ss';
  return '$mm:$ss';
}

String formatDurationCompact(double totalSeconds) {
  final sec = totalSeconds.round();
  final h = sec ~/ 3600;
  final m = (sec % 3600) ~/ 60;
  if (h > 0) return '${h}h ${m}m';
  return '${m}m';
}

String formatDurationLong(double totalSeconds) {
  final seconds = totalSeconds.round();
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  if (h > 0) return '${h}h ${m}m ${s}s';
  return '${m}m ${s}s';
}

String formatElapsed(Duration d) {
  final hours = d.inHours.toString().padLeft(2, '0');
  final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$hours:$minutes:$seconds';
}

String formatDurationFromDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (duration.inHours > 0) {
    final hours = duration.inHours.toString();
    return '$hours:$minutes:$seconds';
  }
  return '$minutes:$seconds';
}

String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}

String formatDateISO(DateTime? date) {
  if (date == null) return '\u2014';
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

String formatDateFull(DateTime date, {String locale = 'en'}) {
  final df = intl.DateFormat.yMMMd(locale);
  final tf = intl.DateFormat.Hm(locale);
  return '${df.format(date)} ${tf.format(date)}';
}

String formatMemberSince(
  DateTime? date,
  AppLocalizations l10n, {
  String locale = 'en',
}) {
  if (date == null) return l10n.format_member;
  final df = intl.DateFormat.yMMM(locale);
  return l10n.format_memberSince(df.format(date));
}

String formatRecordingDate(
  DateTime date,
  String locale, {
  AppLocalizations? l10n,
}) {
  final now = DateTime.now();
  final isToday =
      now.year == date.year && now.month == date.month && now.day == date.day;
  if (isToday && l10n != null) {
    final diff = now.difference(date);
    if (diff.inSeconds < 60) return l10n.format_justNow;
    if (diff.inMinutes < 60) return l10n.format_minutesAgo(diff.inMinutes);
    return l10n.format_hoursAgo(diff.inHours);
  }
  if (isToday) return intl.DateFormat.Hm(locale).format(date);
  if (now.year == date.year) return intl.DateFormat.MMMd(locale).format(date);
  return intl.DateFormat.yMMMd(locale).format(date);
}

String formatTimeAgo(DateTime time, AppLocalizations l10n) {
  final now = DateTime.now();
  final diff = now.difference(time);

  if (diff.inSeconds < 60) return l10n.format_justNow;
  if (diff.inMinutes < 60) return l10n.format_minutesAgo(diff.inMinutes);
  if (diff.inHours < 24) return l10n.format_hoursAgo(diff.inHours);
  if (diff.inDays < 7) return l10n.format_daysAgo(diff.inDays);
  if (diff.inDays < 30) return l10n.format_weeksAgo(diff.inDays ~/ 7);
  return l10n.format_monthsAgo(diff.inDays ~/ 30);
}

String formatDurationMinSec(double totalSeconds) {
  final dur = Duration(milliseconds: (totalSeconds * 1000).round());
  final h = dur.inHours;
  final m = dur.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = dur.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (h > 0) return '${h.toString().padLeft(2, '0')}:$m:$s';
  return '$m:$s';
}

String formatPositionMS(Duration d) {
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$m:$s';
}
