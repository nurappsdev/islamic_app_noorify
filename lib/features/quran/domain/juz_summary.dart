class JuzSummary {
  const JuzSummary({
    required this.number,
    required this.versesCount,
    required this.startSurahNo,
    required this.startAyah,
  });

  final int number;
  final int versesCount;
  final int startSurahNo;
  final int startAyah;

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
