/// A resource returned by the internal Quran translation catalog.
class TranslationEdition {
  const TranslationEdition({
    required this.id,
    required this.name,
    required this.languageName,
    this.resourceId,
  });
  final String id, name, languageName;
  final int? resourceId;
  bool get isBuiltIn => id == kBuiltInEnglishId || id == kBuiltInBengaliId;
  factory TranslationEdition.fromJson(Map<String, dynamic> json) {
    final resource = (json['resourceId'] as num).toInt();
    return TranslationEdition(
      id: resource == 20
          ? kBuiltInEnglishId
          : resource == 161
          ? kBuiltInBengaliId
          : 'qc$resource',
      resourceId: resource,
      name: json['name'] as String,
      languageName:
          json['languageCode'] as String? ??
          json['authorName'] as String? ??
          '',
    );
  }
}

const kBuiltInEnglishId = 'english';
const kBuiltInBengaliId = 'bengali';
int resourceIdForEdition(String id) => id == kBuiltInEnglishId
    ? 20
    : id == kBuiltInBengaliId
    ? 161
    : int.tryParse(id.replaceFirst('qc', '')) ?? 161;
bool isBuiltInEditionId(String id) =>
    id == kBuiltInEnglishId || id == kBuiltInBengaliId;
