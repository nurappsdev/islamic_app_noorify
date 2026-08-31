/// One hadith of a [HadithBook], as stored in the local database.
class HadithEntry {
  const HadithEntry({
    required this.hadithNo,
    required this.titleAr,
    required this.titleBn,
    required this.arabicText,
    required this.banglaNarrator,
    required this.banglaText,
    required this.referencesText,
  });

  final int hadithNo;
  final String titleAr;
  final String titleBn;
  final String arabicText;
  final String banglaNarrator;
  final String banglaText;
  final String referencesText;

  factory HadithEntry.fromRow(Map<String, Object?> row) => HadithEntry(
    hadithNo: (row['hadith_no'] as int?) ?? 0,
    titleAr: (row['title_ar'] as String?) ?? '',
    titleBn: (row['title_bn'] as String?) ?? '',
    arabicText: (row['arabic_text'] as String?) ?? '',
    banglaNarrator: (row['bangla_narrator'] as String?) ?? '',
    banglaText: (row['bangla_text'] as String?) ?? '',
    referencesText: (row['references_text'] as String?) ?? '',
  );
}
