import 'package:islami_app_noorify/features/legal/domain/entities/legal_document.dart';

class LegalDocumentModel extends LegalDocument {
  const LegalDocumentModel({
    required super.title,
    required super.content,
    super.effectiveDate,
    super.lastUpdated,
  });

  /// Parses the `data` object of `GET /settings/terms-of-service` and
  /// `GET /settings/privacy-policy`.
  factory LegalDocumentModel.fromJson(Map<String, dynamic> json) {
    return LegalDocumentModel(
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      effectiveDate: json['effectiveDate']?.toString(),
      lastUpdated: json['lastUpdated']?.toString(),
    );
  }
}
