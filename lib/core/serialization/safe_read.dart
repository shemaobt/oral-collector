/// Typed safe-readers (ENG-147, ADR-0008): pull fields out of an already-decoded
/// `Map<String, dynamic>`, throwing a catchable [ParseException] instead of the
/// uncatchable `TypeError`/`NoSuchMethodError` a raw cast would.
///
/// `readXOrNull` returns null for an absent/null key but still throws on a present
/// value of the wrong type — a malformed value is a contract violation, not an
/// optional miss. Numerics accept any `num` and convert, matching the existing
/// `(x as num).toInt()/.toDouble()` call sites.
library;

import '../errors/app_exception.dart';

const String _dateLabel = 'ISO-8601 date string';

String readString(Map<String, dynamic> json, String key) =>
    _asType<String>(json, key, 'String');

String? readStringOrNull(Map<String, dynamic> json, String key) =>
    _asTypeOrNull<String>(json, key, 'String');

int readInt(Map<String, dynamic> json, String key) =>
    _toInt(_asNum(json, key, 'int'), key);

int? readIntOrNull(Map<String, dynamic> json, String key) {
  final value = _asNumOrNull(json, key, 'int');
  return value == null ? null : _toInt(value, key);
}

double readDouble(Map<String, dynamic> json, String key) =>
    _asNum(json, key, 'double').toDouble();

double? readDoubleOrNull(Map<String, dynamic> json, String key) =>
    _asNumOrNull(json, key, 'double')?.toDouble();

bool readBool(Map<String, dynamic> json, String key) =>
    _asType<bool>(json, key, 'bool');

bool? readBoolOrNull(Map<String, dynamic> json, String key) =>
    _asTypeOrNull<bool>(json, key, 'bool');

Map<String, dynamic> readMap(Map<String, dynamic> json, String key) =>
    _asType<Map<String, dynamic>>(json, key, 'Map<String, dynamic>');

Map<String, dynamic>? readMapOrNull(Map<String, dynamic> json, String key) =>
    _asTypeOrNull<Map<String, dynamic>>(json, key, 'Map<String, dynamic>');

DateTime readDate(Map<String, dynamic> json, String key) =>
    _parseDate(_asType<String>(json, key, _dateLabel), key);

DateTime? readDateOrNull(Map<String, dynamic> json, String key) {
  final value = _asTypeOrNull<String>(json, key, _dateLabel);
  return value == null ? null : _parseDate(value, key);
}

T _asType<T>(Map<String, dynamic> json, String key, String expected) {
  final value = json[key];
  if (value is T) return value;
  throw ParseException(field: key, expected: expected, cause: value);
}

T? _asTypeOrNull<T>(Map<String, dynamic> json, String key, String expected) {
  final value = json[key];
  if (value == null) return null;
  if (value is T) return value;
  throw ParseException(field: key, expected: expected, cause: value);
}

num _asNum(Map<String, dynamic> json, String key, String expected) {
  final value = json[key];
  if (value is num) return value;
  throw ParseException(field: key, expected: expected, cause: value);
}

num? _asNumOrNull(Map<String, dynamic> json, String key, String expected) {
  final value = json[key];
  if (value == null) return null;
  if (value is num) return value;
  throw ParseException(field: key, expected: expected, cause: value);
}

int _toInt(num value, String key) {
  // toInt() throws an uncatchable UnsupportedError on NaN/Infinity; convert it.
  if (!value.isFinite) {
    throw ParseException(field: key, expected: 'int', cause: value);
  }
  return value.toInt();
}

DateTime _parseDate(String value, String key) {
  try {
    return DateTime.parse(value);
  } on FormatException catch (e) {
    throw ParseException(field: key, expected: _dateLabel, cause: e);
  }
}
