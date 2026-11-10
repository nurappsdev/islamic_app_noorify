// Writes assets/quran/quran_meta.json, the surah metadata and per-ayah
// page, para and sajdah numbers bundled with the app, from our server, so a
// surah never opened before still reads offline. Only reads the server; run
// it to rebuild the asset after the server's metadata changes:
//
//   dart run tool/build_quran_meta_asset.dart
//
// Format: {"surahs": [surah, ...], "ayahs": {"<surah>": [[page, para,
// sajdah or null], ...]}}, each surah as the server's ayahs response
// describes it (with its pages), ayahs in order.
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

const _server = 'server-tuhfatulmuslim.ilmifygroup.com';
const _output = 'assets/quran/quran_meta.json';
const _ayahCount = 6236;

Future<void> main() async {
  final client = http.Client();
  final surahs = <Map<String, dynamic>>[];
  final ayahs = <String, List<List<int?>>>{};
  var index = 0;
  try {
    final list = (await _get(client, 'surahs')) as List;
    if (list.length != 114) throw FormatException('${list.length} surahs');
    for (final raw in list.cast<Map<String, dynamic>>()) {
      final number = (raw['number'] as num).toInt();
      final count = (raw['ayahCount'] as num).toInt();
      final data =
          await _get(client, 'surahs/$number/ayahs', {
                'from': '1',
                'to': '$count',
                'limit': '300',
                'page': '1',
              })
              as Map<String, dynamic>;
      final surah = Map<String, dynamic>.of(raw)
        ..['pages'] = (data['surah'] as Map)['pages'];
      surahs.add(surah..remove('_id'));
      final rows = (data['ayahs'] as List).cast<Map<String, dynamic>>();
      if (rows.length != count) {
        throw FormatException('Surah $number: ${rows.length}/$count ayahs');
      }
      ayahs['$number'] = [
        for (final (i, row) in rows.indexed)
          if (row['verseKey'] == '$number:${i + 1}' &&
              row['ayahIndex'] == ++index)
            [
              (row['pageNumber'] as num).toInt(),
              (row['paraNumber'] as num).toInt(),
              (row['sajdahNumber'] as num?)?.toInt(),
            ]
          else
            throw FormatException('Surah $number: ayah ${i + 1} out of order'),
      ];
    }
  } finally {
    client.close();
  }
  if (index != _ayahCount) {
    stderr.writeln('Expected $_ayahCount ayahs, got $index');
    exit(1);
  }
  File(_output)
    ..createSync(recursive: true)
    ..writeAsStringSync(jsonEncode({'surahs': surahs, 'ayahs': ayahs}));
  stdout.writeln('Wrote ${surahs.length} surahs, $index ayahs to $_output');
}

Future<Object?> _get(
  http.Client client,
  String path, [
  Map<String, String>? query,
]) async {
  final uri = Uri.https(_server, '/api/v1/quran/$path', query);
  final response = await client.get(uri).timeout(const Duration(seconds: 60));
  final body = jsonDecode(utf8.decode(response.bodyBytes));
  if (response.statusCode != 200 || body is! Map || body['success'] != true) {
    throw HttpException('$path: HTTP ${response.statusCode}');
  }
  return body['data'];
}
