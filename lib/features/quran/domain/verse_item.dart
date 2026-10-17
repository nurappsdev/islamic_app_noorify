class VerseItem {
  const VerseItem({
    required this.surahNo,
    required this.ayahNo,
    required this.arabic,
    required this.translation,
  });

  final int surahNo;
  final int ayahNo;
  final String arabic;
  final String translation;

  static final _htmlTag = RegExp(r'<[^>]*>');

  factory VerseItem.fromJson(Map<String, dynamic> json) {
    final verseKey = json['verse_key'] as String? ?? '0:0';
    final parts = verseKey.split(':');
    final translations = json['translations'] as List?;
    final translationText = translations != null && translations.isNotEmpty
        ? (translations.first as Map<String, dynamic>)['text'] as String? ?? ''
        : '';
    return VerseItem(
      surahNo: int.tryParse(parts[0]) ?? 0,
      ayahNo: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
      arabic: json['text_uthmani'] as String? ?? '',
      translation: translationText.replaceAll(_htmlTag, ''),
    );
  }
}
