class ReadingHistoryEntry {
  const ReadingHistoryEntry({
    required this.surahNo,
    required this.ayahNo,
    required this.surahName,
    required this.readAt,
  });

  final int surahNo;
  final int ayahNo;
  final String surahName;
  final DateTime readAt;

  Map<String, dynamic> toJson() => {
    'surahNo': surahNo,
    'ayahNo': ayahNo,
    'surahName': surahName,
    'readAt': readAt.toIso8601String(),
  };

  factory ReadingHistoryEntry.fromJson(Map<String, dynamic> json) {
    return ReadingHistoryEntry(
      surahNo: (json['surahNo'] as num).toInt(),
      ayahNo: (json['ayahNo'] as num).toInt(),
      surahName: json['surahName'] as String? ?? '',
      readAt:
          DateTime.tryParse(json['readAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
