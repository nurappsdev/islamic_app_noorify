class SurahSummary {
  const SurahSummary({
    required this.number,
    required this.name,
    required this.nameArabic,
    required this.translation,
    required this.revelationPlace,
    required this.totalAyah,
  });

  final int number;
  final String name;
  final String nameArabic;
  final String translation;
  final String revelationPlace;
  final int totalAyah;

  factory SurahSummary.fromInternalJson(Map<String, dynamic> json) =>
      SurahSummary(
        number: ((json['number'] ?? json['surahNumber']) as num).toInt(),
        name: (json['nameSimple'] ?? json['nameEnglish']) as String? ?? '',
        nameArabic: json['nameArabic'] as String? ?? '',
        translation: json['nameBangla'] as String? ?? '',
        revelationPlace:
            (json['revelationType'] ?? json['revelationPlace']) as String? ??
            '',
        totalAyah: (json['ayahCount'] as num?)?.toInt() ?? 0,
      );

  factory SurahSummary.fromJson(int number, Map<String, dynamic> json) {
    return SurahSummary(
      number: number,
      name: json['surahName'] as String? ?? '',
      nameArabic: json['surahNameArabic'] as String? ?? '',
      translation: json['surahNameTranslation'] as String? ?? '',
      revelationPlace: json['revelationPlace'] as String? ?? '',
      totalAyah: (json['totalAyah'] as num?)?.toInt() ?? 0,
    );
  }
}
