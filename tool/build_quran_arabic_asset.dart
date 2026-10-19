// Writes assets/quran/indopak_nastaleeq.json, the Arabic ayah text bundled
// with the app, from api.quran.com's IndoPak Nastaleeq text: the script the
// bundled IndoPak Nastaleeq font is made for. The app never calls quran.com
// for Arabic; run this only to rebuild the asset:
//
//   dart run tool/build_quran_arabic_asset.dart
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

const _output = 'assets/quran/indopak_nastaleeq.json';
const _ayahCount = 6236;

Future<void> main() async {
  final client = http.Client();
  final surahs = <String, List<String>>{};
  try {
    for (var number = 1; number <= 114; number++) {
      surahs['$number'] = await _surah(client, number);
    }
  } finally {
    client.close();
  }
  final total = surahs.values.fold(0, (sum, s) => sum + s.length);
  if (total != _ayahCount) {
    stderr.writeln('Expected $_ayahCount ayahs, got $total');
    exit(1);
  }
  File(_output)
    ..createSync(recursive: true)
    ..writeAsStringSync(jsonEncode(surahs));
  stdout.writeln('Wrote $total ayahs to $_output');
}

/// Surah [number]'s ayahs in order, without their number circles.
Future<List<String>> _surah(http.Client client, int number) async {
  final uri = Uri.https(
    'api.quran.com',
    '/api/v4/quran/verses/indopak_nastaleeq',
    {'chapter_number': '$number'},
  );
  final response = await client.get(uri).timeout(const Duration(seconds: 30));
  if (response.statusCode != 200) {
    throw HttpException('Surah $number: HTTP ${response.statusCode}');
  }
  final verses =
      (jsonDecode(utf8.decode(response.bodyBytes)) as Map)['verses'] as List;
  final ayahs = [
    for (final (i, raw) in verses.indexed)
      if ((raw as Map)['verse_key'] == '$number:${i + 1}')
        withoutAyahNumber(raw['text_indopak_nastaleeq'] as String)
      else
        throw FormatException('Surah $number: ayah ${i + 1} out of order'),
  ];
  return ayahs;
}

/// The text ends with a space, a U+06DF carrier, the ayah-end waqf signs, an
/// optional private-use waqf glyph and the font's private-use ayah-number
/// circle (U+F500 + n - 1).
final _ayahEnd = RegExp(
  r'\s([\u0610-\u061A\u064B-\u065F\u06D6-\u06ED\uE000-\uF8FF]+)$',
);

/// [text] without the font's ayah-number circle, since the reader draws its
/// own (Bangla) number. The carrier goes too, and the waqf signs move onto
/// the last word, so they cannot wrap away from it or crowd the marker.
String withoutAyahNumber(String text) {
  final end = _ayahEnd.firstMatch(text);
  if (end == null) return text;
  final tail = end.group(1)!.runes;
  final marks = tail.where((c) => c < 0xE000 && c != 0x06DF);
  final glyphs = tail.where((c) => c >= 0xE000 && (c < 0xF500 || c > 0xF63F));
  return text.substring(0, end.start) +
      String.fromCharCodes(marks) +
      (glyphs.isEmpty ? '' : ' ${String.fromCharCodes(glyphs)}');
}
