class Bookmark {
  const Bookmark({
    required this.surahNo,
    required this.ayahNo,
    required this.surahName,
    required this.snippet,
    required this.savedAt,
  });

  final int surahNo;
  final int ayahNo;
  final String surahName;
  final String snippet;
  final DateTime savedAt;

  Map<String, dynamic> toJson() => {
    'surahNo': surahNo,
    'ayahNo': ayahNo,
    'surahName': surahName,
    'snippet': snippet,
    'savedAt': savedAt.toIso8601String(),
  };

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      surahNo: (json['surahNo'] as num).toInt(),
      ayahNo: (json['ayahNo'] as num).toInt(),
      surahName: json['surahName'] as String? ?? '',
      snippet: json['snippet'] as String? ?? '',
      savedAt:
          DateTime.tryParse(json['savedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
