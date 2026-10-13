import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/features/dua/data/models/dua_api_models.dart';

/// One dua saved into one folder — a snapshot of a `/duas/featured` item (or
/// the legacy mock detail), stored bilingually so it renders correctly
/// regardless of the app's language at read time. Persisted by
/// [DuaBookmarkStore] in `HiveService.duaBookmarks`, keyed `<duaId>::<folder>`.
class DuaBookmarkModel {
  const DuaBookmarkModel({
    required this.duaId,
    required this.folder,
    required this.titleBn,
    required this.titleEn,
    required this.arabic,
    required this.transliterationBn,
    required this.transliterationEn,
    required this.translationBn,
    required this.translationEn,
    required this.referenceBn,
    required this.referenceEn,
    required this.categoryNameBn,
    required this.categoryNameEn,
    required this.recommendedRepeatCount,
    required this.createdAt,
    this.iconUrl,
  });

  /// The dua's own `_id` from `/duas/featured`, or `mock:<name>` for the
  /// legacy catalog's demo duas.
  final String duaId;
  final String folder;
  final String titleBn;
  final String titleEn;
  final String arabic;
  final String transliterationBn;
  final String transliterationEn;
  final String translationBn;
  final String translationEn;
  final String referenceBn;
  final String referenceEn;
  final String categoryNameBn;
  final String categoryNameEn;
  final int recommendedRepeatCount;
  final DateTime createdAt;
  final String? iconUrl;

  Map<String, dynamic> toMap() => {
    'duaId': duaId,
    'folder': folder,
    'titleBn': titleBn,
    'titleEn': titleEn,
    'arabic': arabic,
    'transliterationBn': transliterationBn,
    'transliterationEn': transliterationEn,
    'translationBn': translationBn,
    'translationEn': translationEn,
    'referenceBn': referenceBn,
    'referenceEn': referenceEn,
    'categoryNameBn': categoryNameBn,
    'categoryNameEn': categoryNameEn,
    'recommendedRepeatCount': recommendedRepeatCount,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'iconUrl': iconUrl,
  };

  factory DuaBookmarkModel.fromMap(Map<dynamic, dynamic> map) =>
      DuaBookmarkModel(
        duaId: map['duaId'] as String? ?? '',
        folder: map['folder'] as String? ?? '',
        titleBn: map['titleBn'] as String? ?? '',
        titleEn: map['titleEn'] as String? ?? '',
        arabic: map['arabic'] as String? ?? '',
        transliterationBn: map['transliterationBn'] as String? ?? '',
        transliterationEn: map['transliterationEn'] as String? ?? '',
        translationBn: map['translationBn'] as String? ?? '',
        translationEn: map['translationEn'] as String? ?? '',
        referenceBn: map['referenceBn'] as String? ?? '',
        referenceEn: map['referenceEn'] as String? ?? '',
        categoryNameBn: map['categoryNameBn'] as String? ?? '',
        categoryNameEn: map['categoryNameEn'] as String? ?? '',
        recommendedRepeatCount: map['recommendedRepeatCount'] as int? ?? 1,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          map['createdAt'] as int? ?? 0,
        ),
        iconUrl: map['iconUrl'] as String?,
      );

  /// Rebuilds a [DuaFeaturedModel]-shaped value so the saved dua can be
  /// reopened on `DuaReaderScreen` via `DuaReaderArgs.real` — there is no
  /// "get dua by id" endpoint to refetch it from.
  DuaFeaturedModel toFeaturedModel() => DuaFeaturedModel(
    id: duaId,
    categoryId: '',
    title: LocalizedText(bn: titleBn, en: titleEn),
    arabic: arabic,
    transliteration: LocalizedText(
      bn: transliterationBn,
      en: transliterationEn,
    ),
    translation: LocalizedText(bn: translationBn, en: translationEn),
    reference: LocalizedText(bn: referenceBn, en: referenceEn),
    recommendedRepeatCount: recommendedRepeatCount,
    iconUrl: iconUrl,
    category: DuaCategoryModel(
      id: '',
      slug: '',
      name: LocalizedText(bn: categoryNameBn, en: categoryNameEn),
    ),
  );
}
