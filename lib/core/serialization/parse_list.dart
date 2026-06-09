/// Element-isolating list parser (ENG-146, ADR-0008 page policy).
///
/// Maps [raw] element-by-element via [parse], **skipping and logging** any
/// element that fails so one malformed record cannot blank a whole page. The
/// catch is intentionally broad: today's `fromJson` factories still force-cast
/// (`json['x'] as String`), so a bad element surfaces as an `Error`, not an
/// `Exception` — this is the collection boundary that contains it. Single-object
/// reads stay fail-fast and must NOT use this.
///
/// A non-`List` [raw] is a broken container, not a bad row: it throws
/// [ParseException] (fail-fast), unlike the bad elements it tolerates.
library;

import 'dart:developer' as developer;

import '../errors/app_exception.dart';

typedef SkipCallback =
    void Function(Object error, StackTrace stackTrace, int index);

List<T> parseList<T>(
  Object? raw,
  T Function(Map<String, dynamic> json) parse, {
  String? context,
  SkipCallback? onSkip,
}) {
  if (raw is! List) {
    throw ParseException(
      field: context ?? '<root>',
      expected: 'List',
      cause: raw,
    );
  }
  final sink = onSkip ?? _logSkip(context);
  final result = <T>[];
  for (var index = 0; index < raw.length; index++) {
    try {
      result.add(parse(raw[index] as Map<String, dynamic>));
    } catch (error, stackTrace) {
      sink(error, stackTrace, index);
    }
  }
  return result;
}

SkipCallback _logSkip(String? context) =>
    (error, stackTrace, index) => developer.log(
      'parseList[${context ?? '?'}]: skipped element #$index',
      name: 'parseList',
      level: 900, // warning
      error: error,
      stackTrace: stackTrace,
    );
