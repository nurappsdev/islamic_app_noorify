class SurahDetail {
  const SurahDetail({
    required this.number,
    required this.name,
    required this.nameArabic,
    required this.translation,
    required this.revelationPlace,
    required this.totalAyah,
    required this.arabicAyahs,
    required this.englishAyahs,
    required this.bengaliAyahs,
  });

  final int number;
  final String name;
  final String nameArabic;
  final String translation;
  final String revelationPlace;
  final int totalAyah;
  final List<String> arabicAyahs;
  final List<String> englishAyahs;
  final List<String> bengaliAyahs;

  factory SurahDetail.fromJson(Map<String, dynamic> json) {
    List<String> stringList(Object? value) {
      if (value is! List) return const [];
      return value.map((e) => e.toString()).toList(growable: false);
    }

    return SurahDetail(
      number: (json['surahNo'] as num?)?.toInt() ?? 0,
      name: json['surahName'] as String? ?? '',
      nameArabic: json['surahNameArabic'] as String? ?? '',
      translation: json['surahNameTranslation'] as String? ?? '',
      revelationPlace: json['revelationPlace'] as String? ?? '',
      totalAyah: (json['totalAyah'] as num?)?.toInt() ?? 0,
      arabicAyahs: stringList(json['arabic1']),
      englishAyahs: stringList(json['english']),
      bengaliAyahs: stringList(json['bengali']),
    );
  }
}
