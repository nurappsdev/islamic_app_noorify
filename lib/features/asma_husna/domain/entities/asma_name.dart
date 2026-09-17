import 'package:islami_app_noorify/features/asma_husna/domain/entities/asma_name_detail.dart';

/// One of the 99 Names of Allah, as returned by `GET /asma-ul-husna` — now
/// including its full explanation ([meaningEnglish]/[explanationParagraphs])
/// so one list fetch is enough to populate both the list and detail screens
/// (see [toDetail] and `AsmaHusnaRepositoryImpl`).
class AsmaName {
  const AsmaName({
    required this.id,
    required this.displayOrder,
    required this.serialNumberBangla,
    required this.nameArabic,
    required this.nameBangla,
    required this.nameTransliteration,
    required this.meaningBangla,
    this.meaningEnglish = '',
    this.explanationParagraphs = const [],
    this.audioUrl,
  });

  final String id;
  final int displayOrder;
  final String serialNumberBangla;
  final String nameArabic;
  final String nameBangla;
  final String nameTransliteration;
  final String meaningBangla;
  final String meaningEnglish;
  final List<AsmaExplanationParagraph> explanationParagraphs;
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

  /// Builds the [AsmaNameDetailScreen]'s view model straight from this
  /// (already-loaded) name, so the detail screen needs no network call of
  /// its own once the full list has been fetched/cached once.
  AsmaNameDetail toDetail() => AsmaNameDetail(
    nameArabic: nameArabic,
    nameBangla: nameBangla,
    nameTransliteration: nameTransliteration,
    meaningEnglish: meaningEnglish,
    meaningBangla: meaningBangla,
    explanationParagraphs: explanationParagraphs,
    audioUrl: audioUrl,
  );
}
