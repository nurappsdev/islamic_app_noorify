import 'package:tuhfatul_muslim/core/utils/localized_text.dart';

/// Reads a non-empty string id/slug from `_id` (Mongo) or `id`, or `null`.
String? readId(Object? value) {
  final text = value?.toString().trim();
  return (text == null || text.isEmpty) ? null : text;
}

String _idOf(Map<String, dynamic> json) =>
    readId(json['_id']) ?? readId(json['id']) ?? '';

int _asInt(Object? value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;

String? _urlOf(Object? value) {
  final text = value?.toString().trim();
  return (text == null || text.isEmpty) ? null : text;
}

/// A dua category, as `GET /duas/categories` returns it — also embedded
/// (without [description]/[totalDuasCount]) inside each `GET /duas/featured`
/// item as its `category` field.
class DuaCategoryModel {
  const DuaCategoryModel({
    required this.id,
    required this.slug,
    required this.name,
    this.description = LocalizedText.empty,
    this.isFeatured = false,
    this.isActive = true,
    this.displayOrder = 0,
    this.totalDuasCount = 0,
    this.iconUrl,
  });

  final String id;
  final String slug;
  final LocalizedText name;
  final LocalizedText description;
  final bool isFeatured;
  final bool isActive;
  final int displayOrder;
  final int totalDuasCount;
  final String? iconUrl;

  factory DuaCategoryModel.fromJson(Map<String, dynamic> json) =>
      DuaCategoryModel(
        id: _idOf(json),
        slug: json['slug']?.toString() ?? '',
        name: LocalizedText.fromJson(json['name']),
        description: LocalizedText.fromJson(json['description']),
        isFeatured: json['isFeatured'] == true,
        isActive: json['isActive'] != false,
        displayOrder: _asInt(json['displayOrder']),
        totalDuasCount: _asInt(json['totalDuasCount']),
        iconUrl: _urlOf(json['iconUrl']),
      );
}

/// One dua, as `GET /duas/featured` returns it — a single, ready-to-read
/// dua (not a group of several), with its own Arabic text and bilingual
/// transliteration/translation/instruction/reference/virtue.
class DuaFeaturedModel {
  const DuaFeaturedModel({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.arabic,
    required this.transliteration,
    required this.translation,
    this.instruction = LocalizedText.empty,
    this.reference = LocalizedText.empty,
    this.virtue = LocalizedText.empty,
    this.tags = const [],
    this.recommendedRepeatCount = 1,
    this.isFeatured = false,
    this.isActive = true,
    this.displayOrder = 0,
    this.iconUrl,
    this.category,
  });

  final String id;
  final String categoryId;
  final LocalizedText title;
  final String arabic;
  final LocalizedText transliteration;
  final LocalizedText translation;
  final LocalizedText instruction;
  final LocalizedText reference;
  final LocalizedText virtue;
  final List<String> tags;
  final int recommendedRepeatCount;
  final bool isFeatured;
  final bool isActive;
  final int displayOrder;
  final String? iconUrl;
  final DuaCategoryModel? category;

  /// A copy with [category] replaced — used to swap in the full category
  /// (with [DuaCategoryModel.totalDuasCount]) once `GET /duas/categories`
  /// has loaded, since the `category` embedded in a `/duas/featured` item
  /// omits that field.
  DuaFeaturedModel withCategory(DuaCategoryModel category) => DuaFeaturedModel(
    id: id,
    categoryId: categoryId,
    title: title,
    arabic: arabic,
    transliteration: transliteration,
    translation: translation,
    instruction: instruction,
    reference: reference,
    virtue: virtue,
    tags: tags,
    recommendedRepeatCount: recommendedRepeatCount,
    isFeatured: isFeatured,
    isActive: isActive,
    displayOrder: displayOrder,
    iconUrl: iconUrl,
    category: category,
  );

  factory DuaFeaturedModel.fromJson(Map<String, dynamic> json) {
    final categoryJson = json['category'];
    return DuaFeaturedModel(
      id: _idOf(json),
      categoryId: readId(json['categoryId']) ?? '',
      title: LocalizedText.fromJson(json['title']),
      arabic: json['arabic']?.toString() ?? '',
      transliteration: LocalizedText.fromJson(json['transliteration']),
      translation: LocalizedText.fromJson(json['translation']),
      instruction: LocalizedText.fromJson(json['instruction']),
      reference: LocalizedText.fromJson(json['reference']),
      virtue: LocalizedText.fromJson(json['virtue']),
      tags: [
        for (final tag in json['tags'] as List? ?? const []) tag.toString(),
      ],
      recommendedRepeatCount: _asInt(json['recommendedRepeatCount']) == 0
          ? 1
          : _asInt(json['recommendedRepeatCount']),
      isFeatured: json['isFeatured'] == true,
      isActive: json['isActive'] != false,
      displayOrder: _asInt(json['displayOrder']),
      iconUrl: _urlOf(json['iconUrl']),
      category: categoryJson is Map
          ? DuaCategoryModel.fromJson(Map<String, dynamic>.from(categoryJson))
          : null,
    );
  }
}

/// One page from `GET /duas`. The category endpoint returns the same dua
/// shape as `/duas/featured`, plus pagination metadata in `meta`.
class DuaPage {
  const DuaPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPage,
  });

  final List<DuaFeaturedModel> items;
  final int page;
  final int limit;
  final int total;
  final int totalPage;
}
