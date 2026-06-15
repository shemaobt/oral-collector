/// Returns [href] as a same-origin relative reference (path + query + fragment)
/// with every occurrence of [key] removed from the query string, or `null` when
/// [key] is absent so callers can skip rewriting the URL.
String? cleanedLocationWithout(String href, String key) {
  final uri = Uri.parse(href);
  if (!uri.queryParameters.containsKey(key)) return null;

  final remaining = Map<String, List<String>>.from(uri.queryParametersAll)
    ..remove(key);
  final query = remaining.isEmpty ? '' : Uri(queryParameters: remaining).query;

  final buffer = StringBuffer(uri.path);
  if (query.isNotEmpty) buffer.write('?$query');
  if (uri.hasFragment) buffer.write('#${uri.fragment}');
  return buffer.toString();
}
