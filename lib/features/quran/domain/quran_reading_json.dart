/// Typed readers for the Quran reading API's JSON, shared by its models so
/// no `Map`/`dynamic` leaks past parsing. Missing or mistyped values fall back
/// to zero / empty, the way the rest of the Quran module parses responses.
library;

Map<String, dynamic> readMap(Object? value) =>
    value is Map<String, dynamic> ? value : const <String, dynamic>{};

/// [value] as a map, or null when it is absent (a nullable object field).
Map<String, dynamic>? readMapOrNull(Object? value) =>
    value is Map<String, dynamic> ? value : null;

List<Map<String, dynamic>> readMapList(Object? value) =>
    value is List ? value.whereType<Map<String, dynamic>>().toList() : const [];

int readInt(Object? value) => value is num ? value.toInt() : 0;

double readDouble(Object? value) => value is num ? value.toDouble() : 0;

bool readBool(Object? value) => value == true;

String readString(Object? value) => value is String ? value : '';

String? readStringOrNull(Object? value) =>
    value is String && value.isNotEmpty ? value : null;

/// A `YYYY-MM-DD` calendar day, as the API sends reading days, kept as that
/// same local calendar date (no time-zone shift); null when it isn't one.
DateTime? readDay(Object? value) {
  if (value is! String || value.length < 10) return null;
  final parsed = DateTime.tryParse(value.substring(0, 10));
  return parsed == null
      ? null
      : DateTime(parsed.year, parsed.month, parsed.day);
}

/// An ISO-8601 instant (UTC from the API); null when absent or invalid.
/// Call `toLocal()` where one is shown to the user.
DateTime? readInstant(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
