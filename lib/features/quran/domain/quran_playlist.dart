class QuranPlaylistItem {
  const QuranPlaylistItem({
    required this.surahNo,
    required this.surahName,
    required this.arabicName,
    required this.revelationPlace,
    required this.startAyah,
    required this.endAyah,
    required this.totalAyah,
  });

  final int surahNo;
  final String surahName;
  final String arabicName;
  final String revelationPlace;
  final int startAyah;
  final int endAyah;
  final int totalAyah;

  Map<String, dynamic> toJson() => {
    'surahNo': surahNo,
    'surahName': surahName,
    'arabicName': arabicName,
    'revelationPlace': revelationPlace,
    'startAyah': startAyah,
    'endAyah': endAyah,
    'totalAyah': totalAyah,
  };

  factory QuranPlaylistItem.fromJson(Map<String, dynamic> json) =>
      QuranPlaylistItem(
        surahNo: (json['surahNo'] as num?)?.toInt() ?? 1,
        surahName: json['surahName'] as String? ?? '',
        arabicName: json['arabicName'] as String? ?? '',
        revelationPlace: json['revelationPlace'] as String? ?? 'Meccan',
        startAyah: (json['startAyah'] as num?)?.toInt() ?? 1,
        endAyah: (json['endAyah'] as num?)?.toInt() ?? 1,
        totalAyah: (json['totalAyah'] as num?)?.toInt() ?? 1,
      );
}

class QuranPlaylist {
  const QuranPlaylist({
    required this.id,
    required this.title,
    required this.items,
    required this.createdAt,
  });

  final String id;
  final String title;
  final List<QuranPlaylistItem> items;
  final DateTime createdAt;

  String get surahSummaryText {
    if (items.isEmpty) return 'No Surahs';
    final names = items.map((e) => e.surahName).take(2).join(', ');
    return 'Sura ($names${items.length > 2 ? ', ...' : ''})';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'items': items.map((e) => e.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory QuranPlaylist.fromJson(Map<String, dynamic> json) => QuranPlaylist(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    items:
        (json['items'] as List<dynamic>?)
            ?.map((e) => QuranPlaylistItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
  );
}
