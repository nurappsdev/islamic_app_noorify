import 'package:islami_app_noorify/features/asma_husna/domain/entities/asma_name.dart';
import 'package:islami_app_noorify/features/asma_husna/domain/entities/asma_name_detail.dart';

/// Data-layer representation of [AsmaName], parsed from one entry of the
/// `data` list of `GET /asma-ul-husna`, e.g.:
/// ```
/// {_id, displayOrder, serialNumberBangla, nameArabic, nameBangla,
///  nameTransliteration, meaningBangla, meaningEnglish,
///  explanationParagraphs, audioUrl}
/// ```
/// (`audioUrl` is absent for "Allah" itself, the first entry.) [toJson]
/// round-trips the same shape back, so this is also what's written to and
/// read from the local cache (see `AsmaHusnaLocalDataSource`).
class AsmaNameModel extends AsmaName {
  const AsmaNameModel({
    required super.id,
    required super.displayOrder,
    required super.serialNumberBangla,
    required super.nameArabic,
    required super.nameBangla,
    required super.nameTransliteration,
    required super.meaningBangla,
    super.meaningEnglish,
    super.explanationParagraphs,
    super.audioUrl,
  });

  factory AsmaNameModel.fromJson(Map<String, dynamic> json) {
    final paragraphs = json['explanationParagraphs'];
    return AsmaNameModel(
      id: json['_id']?.toString() ?? '',
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
      serialNumberBangla: json['serialNumberBangla']?.toString() ?? '',
      nameArabic: json['nameArabic']?.toString() ?? '',
      nameBangla: json['nameBangla']?.toString() ?? '',
      nameTransliteration: json['nameTransliteration']?.toString() ?? '',
      meaningBangla: json['meaningBangla']?.toString() ?? '',
      meaningEnglish: json['meaningEnglish']?.toString() ?? '',
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

  Map<String, dynamic> toJson() => {
    '_id': id,
    'displayOrder': displayOrder,
    'serialNumberBangla': serialNumberBangla,
    'nameArabic': nameArabic,
    'nameBangla': nameBangla,
    'nameTransliteration': nameTransliteration,
    'meaningBangla': meaningBangla,
    'meaningEnglish': meaningEnglish,
    'explanationParagraphs': [
      for (final p in explanationParagraphs)
        {'text': p.text, 'isArabic': p.isArabic},
    ],
    'audioUrl': audioUrl,
  };
}
