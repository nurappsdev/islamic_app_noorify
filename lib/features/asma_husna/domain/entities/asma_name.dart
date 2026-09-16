/// One of the 99 Names of Allah, as returned by `GET /asma-ul-husna`.
class AsmaName {
  const AsmaName({
    required this.id,
    required this.displayOrder,
    required this.serialNumberBangla,
    required this.nameArabic,
    required this.nameBangla,
    required this.nameTransliteration,
    required this.meaningBangla,
    this.audioUrl,
  });

  final String id;
  final int displayOrder;
  final String serialNumberBangla;
  final String nameArabic;
  final String nameBangla;
  final String nameTransliteration;
  final String meaningBangla;
  final String? audioUrl;

  /// `1` -> `"01"`, `12` -> `"12"` — the number badge shown on each card.
  String get orderLabel => displayOrder.toString().padLeft(2, '0');

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return nameTransliteration.toLowerCase().contains(q) ||
        nameArabic.contains(q) ||
        nameBangla.contains(q) ||
        meaningBangla.toLowerCase().contains(q);
  }
}
