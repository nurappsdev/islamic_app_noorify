class JuzSummary {
  const JuzSummary({
    required this.number,
    required this.versesCount,
    required this.startSurahNo,
    required this.startAyah,
    this.nameBangla = '',
    this.endSurahNo = 0,
    this.endAyah = 0,
    this.surahs = const [],
  });

  final int number;
  final int versesCount;
  final int startSurahNo;
  final int startAyah;

  final String nameBangla;
  final int endSurahNo, endAyah;
  final List<ParaSurah> surahs;

  factory JuzSummary.fromInternalJson(Map<String, dynamic> json) {
    final start = json['start'] as Map<String, dynamic>;
    final end = json['end'] as Map<String, dynamic>;
    return JuzSummary(
      number: (json['number'] as num).toInt(),
      nameBangla: json['nameBangla'] as String? ?? '',
      versesCount: (json['ayahCount'] as num).toInt(),
      startSurahNo: (start['surah'] as num).toInt(),
      startAyah: (start['ayah'] as num).toInt(),
      endSurahNo: (end['surah'] as num).toInt(),
      endAyah: (end['ayah'] as num).toInt(),
      surahs: [
        for (final raw in json['surahs'] as List)
          ParaSurah(
            number: (raw['number'] as num).toInt(),
            name: raw['nameEnglish'] as String? ?? '',
            nameBangla: raw['nameBangla'] as String? ?? '',
          ),
      ],
    );
  }

  factory JuzSummary.fromJson(Map<String, dynamic> json) {
    final mapping = json['verse_mapping'] as Map<String, dynamic>? ?? const {};
    var startSurahNo = 0;
    var startAyah = 0;
    if (mapping.isNotEmpty) {
      final firstKey = mapping.keys.first;
      startSurahNo = int.tryParse(firstKey) ?? 0;
      final range = mapping[firstKey] as String? ?? '0-0';
      startAyah = int.tryParse(range.split('-').first) ?? 0;
    }
    return JuzSummary(
      number: (json['juz_number'] as num?)?.toInt() ?? 0,
      versesCount: (json['verses_count'] as num?)?.toInt() ?? 0,
      startSurahNo: startSurahNo,
      startAyah: startAyah,
    );
  }
}

class ParaSurah {
  const ParaSurah({
    required this.number,
    required this.name,
    required this.nameBangla,
  });
  final int number;
  final String name, nameBangla;
}
