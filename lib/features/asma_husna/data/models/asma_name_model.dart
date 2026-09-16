import 'package:islami_app_noorify/features/asma_husna/domain/entities/asma_name.dart';

/// Data-layer representation of [AsmaName], parsed from one entry of the
/// `data` list of `GET /asma-ul-husna`, e.g.:
/// ```
/// {_id, displayOrder, serialNumberBangla, nameArabic, nameBangla,
///  nameTransliteration, meaningBangla, audioUrl}
/// ```
/// (`audioUrl` is absent for "Allah" itself, the first entry.)
class AsmaNameModel extends AsmaName {
  const AsmaNameModel({
    required super.id,
    required super.displayOrder,
    required super.serialNumberBangla,
    required super.nameArabic,
    required super.nameBangla,
    required super.nameTransliteration,
    required super.meaningBangla,
    super.audioUrl,
  });

  factory AsmaNameModel.fromJson(Map<String, dynamic> json) {
    return AsmaNameModel(
      id: json['_id']?.toString() ?? '',
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
      serialNumberBangla: json['serialNumberBangla']?.toString() ?? '',
      nameArabic: json['nameArabic']?.toString() ?? '',
      nameBangla: json['nameBangla']?.toString() ?? '',
      nameTransliteration: json['nameTransliteration']?.toString() ?? '',
      meaningBangla: json['meaningBangla']?.toString() ?? '',
      audioUrl: json['audioUrl']?.toString(),
    );
  }
}
