/// One paragraph of an [AsmaNameDetail]'s explanation — Arabic verses are
/// flagged so the UI can render them with a different style/alignment.
class AsmaExplanationParagraph {
  const AsmaExplanationParagraph({required this.text, required this.isArabic});

  final String text;
  final bool isArabic;
}

/// Full detail of one of the 99 Names of Allah, as returned by
/// `GET /asma-ul-husna/{id}`.
class AsmaNameDetail {
  const AsmaNameDetail({
    required this.nameArabic,
    required this.nameBangla,
    required this.nameTransliteration,
    required this.meaningEnglish,
    required this.meaningBangla,
    required this.explanationParagraphs,
    this.audioUrl,
  });

  final String nameArabic;
  final String nameBangla;
  final String nameTransliteration;
  final String meaningEnglish;
  final String meaningBangla;
  final List<AsmaExplanationParagraph> explanationParagraphs;
  final String? audioUrl;
}
