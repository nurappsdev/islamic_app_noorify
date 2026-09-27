/// Display formatting shared by the quiz screens. Values are formatted as the
/// server sent them; nothing here derives a score.
library;

/// Replaces each `{name}` in [template] with its value from [values].
String fillTemplate(String template, Map<String, Object> values) {
  var text = template;
  values.forEach((name, value) => text = text.replaceAll('{$name}', '$value'));
  return text;
}

/// [seconds] as `mm : ss`, e.g. `07 : 03`. Never negative.
String formatClock(int seconds) {
  final safe = seconds < 0 ? 0 : seconds;
  final minutes = (safe ~/ 60).toString().padLeft(2, '0');
  final rest = (safe % 60).toString().padLeft(2, '0');
  return '$minutes : $rest';
}

/// A point value without trailing zeros: `2.5`, `2.3`, `0`.
String formatPoints(num value) {
  if (value % 1 == 0) return value.toInt().toString();
  return value
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

/// A percentage as sent, e.g. `92%`.
String formatPercent(num value) => '${formatPoints(value)}%';

/// A number the server may leave `null`, or `—` when it did.
String formatOptional(num? value, String Function(num) format) =>
    value == null ? '—' : format(value);

/// [value] (local time) as e.g. `26 September 2026, 14:05`, with the app's
/// month names.
String formatQuizDateTime(DateTime value, List<String> monthNames) {
  final local = value.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.day} ${monthNames[local.month - 1]} ${local.year}, '
      '$hour:$minute';
}

/// [value]'s local calendar day as e.g. `26 September 2026`, with the app's
/// month names.
String formatQuizDay(DateTime value, List<String> monthNames) {
  final local = value.toLocal();
  return '${local.day} ${monthNames[local.month - 1]} ${local.year}';
}
