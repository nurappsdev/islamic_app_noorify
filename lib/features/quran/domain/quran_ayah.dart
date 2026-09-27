/// Content identifiers are independent of the recitation/audio provider.
class QuranAyah {
  const QuranAyah({
    required this.surahNumber,
    required this.ayahNumber,
    required this.verseKey,
    required this.ayahIndex,
    required this.paraNumber,
    required this.pageNumber,
    required this.textArabic,
    this.sajdahNumber,
    this.translations = const {},
  });
  final int surahNumber, ayahNumber, ayahIndex, paraNumber, pageNumber;
  final int? sajdahNumber;
  final String verseKey, textArabic;
  final Map<int, AyahTranslation> translations;

  factory QuranAyah.fromJson(Map<String, dynamic> json) => QuranAyah(
    surahNumber: (json['surahNumber'] as num).toInt(),
    ayahNumber: (json['ayahNumber'] as num).toInt(),
    verseKey: json['verseKey'] as String,
    ayahIndex: (json['ayahIndex'] as num).toInt(),
    paraNumber: (json['paraNumber'] as num).toInt(),
    pageNumber: (json['pageNumber'] as num).toInt(),
    sajdahNumber: (json['sajdahNumber'] as num?)?.toInt(),
    textArabic: json['textArabic'] as String,
    translations: {
      for (final raw in (json['translations'] as List? ?? []))
        (raw['resourceId'] as num).toInt(): AyahTranslation.fromJson(
          raw as Map<String, dynamic>,
        ),
    },
  );
}

class AyahTranslation {
  const AyahTranslation({
    required this.resourceId,
    required this.name,
    required this.authorName,
    required this.text,
  });
  final int resourceId;
  final String name, authorName, text;
  factory AyahTranslation.fromJson(Map<String, dynamic> json) =>
      AyahTranslation(
        resourceId: (json['resourceId'] as num).toInt(),
        name: json['name'] as String? ?? '',
        authorName: json['authorName'] as String? ?? '',
        text:
            json['textPlain'] as String? ??
            (json['text'] as String? ?? '')
                .replaceAll(RegExp(r'<sup\b[^>]*>.*?</sup>', dotAll: true), '')
                .replaceAll(RegExp(r'<[^>]*>'), ''),
      );
}

class QuranPagination {
  const QuranPagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPage,
  });
  final int page, limit, total, totalPage;
  bool get hasNext => page < totalPage;
  factory QuranPagination.fromJson(Map<String, dynamic> json) =>
      QuranPagination(
        page: (json['page'] as num?)?.toInt() ?? 1,
        limit: (json['limit'] as num?)?.toInt() ?? 0,
        total: (json['total'] as num?)?.toInt() ?? 0,
        totalPage: (json['totalPage'] as num?)?.toInt() ?? 1,
      );
}
