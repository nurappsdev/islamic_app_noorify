import 'package:islami_app_noorify/features/asma_husna/domain/entities/asma_name_detail.dart';

/// Data-layer representation of [AsmaNameDetail], parsed from the `data`
/// object of `GET /asma-ul-husna/{id}`.
class AsmaNameDetailModel extends AsmaNameDetail {
  const AsmaNameDetailModel({
    required super.nameArabic,
    required super.nameBangla,
    required super.nameTransliteration,
    required super.meaningEnglish,
    required super.meaningBangla,
    required super.explanationParagraphs,
    super.audioUrl,
  });

  factory AsmaNameDetailModel.fromJson(Map<String, dynamic> json) {
    final paragraphs = json['explanationParagraphs'];
    return AsmaNameDetailModel(
      nameArabic: json['nameArabic']?.toString() ?? '',
      nameBangla: json['nameBangla']?.toString() ?? '',
      nameTransliteration: json['nameTransliteration']?.toString() ?? '',
      meaningEnglish: json['meaningEnglish']?.toString() ?? '',
      meaningBangla: json['meaningBangla']?.toString() ?? '',
      explanationParagraphs: paragraphs is List
          ? paragraphs
                .whereType<Map>()
                .map(
                  (e) => AsmaExplanationParagraph(
                    text: e['text']?.toString() ?? '',
                    isArabic: e['isArabic'] == true,
                  ),
                )
                .toList()
          : const [],
      audioUrl: json['audioUrl']?.toString(),
    );
  }
}
