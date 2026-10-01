import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/features/learning/domain/entities/article.dart';
import 'package:tuhfatul_muslim/features/quiz/data/models/quiz_category_model.dart';
import 'package:tuhfatul_muslim/features/quiz/data/models/quiz_dashboard_model.dart';

/// The article API names ids `_id`; `id` is accepted too.
String? _readObjectId(Map<String, dynamic> json) =>
    readId(json['_id']) ?? readId(json['id']);

DateTime? _readDate(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;

String? _readText(Object? value) {
  if (value is! String) return null;
  final text = value.trim();
  return text.isEmpty ? null : text;
}

List<Map<String, dynamic>> _readList(Object? value) => value is List
    ? value.map(readMap).whereType<Map<String, dynamic>>().toList()
    : const [];

class ArticleCategoryModel extends ArticleCategory {
  const ArticleCategoryModel({
    required super.id,
    required super.name,
    required super.description,
    required super.displayOrder,
    required super.isActive,
    required super.totalArticles,
  });

  factory ArticleCategoryModel.fromJson(Map<String, dynamic> json) {
    return ArticleCategoryModel(
      id: _readObjectId(json) ?? '',
      name: LocalizedText.fromJson(json['name']),
      description: LocalizedText.fromJson(json['description']),
      displayOrder: readNum(json['displayOrder'])?.toInt() ?? 0,
      // A category the server leaves unmarked is taken as active.
      isActive: json['isActive'] != false,
      totalArticles: readNum(json['totalArticles'])?.toInt() ?? 0,
    );
  }
}

class ArticleModel extends Article {
  const ArticleModel({
    required super.id,
    required super.categoryId,
    required super.categoryName,
    required super.title,
    required super.excerpt,
    required super.content,
    required super.author,
    required super.coverImageUrl,
    required super.status,
    required super.publishedAt,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ArticleModel.fromJson(Map<String, dynamic> json) {
    // `categoryId` arrives populated (`{_id, name, ...}`) or as a bare id.
    final category = readMap(json['categoryId']);
    final coverUrl = _readText(json['coverImageUrl']);
    final coverUri = coverUrl == null ? null : Uri.tryParse(coverUrl);
    return ArticleModel(
      id: _readObjectId(json) ?? '',
      categoryId: category == null
          ? readId(json['categoryId'])
          : _readObjectId(category),
      categoryName: LocalizedText.fromJson(category?['name']),
      title: LocalizedText.fromJson(json['title']),
      excerpt: LocalizedText.fromJson(json['excerpt']),
      content: LocalizedText.fromJson(json['content']),
      author: _readText(json['author']) ?? '',
      // Only an absolute http(s) URL can be loaded.
      coverImageUrl:
          coverUri != null &&
              (coverUri.scheme == 'http' || coverUri.scheme == 'https') &&
              coverUri.host.isNotEmpty
          ? coverUrl
          : null,
      status: _readText(json['status']),
      publishedAt: _readDate(json['publishedAt']),
      createdAt: _readDate(json['createdAt']),
      updatedAt: _readDate(json['updatedAt']),
    );
  }
}

/// Builds a page from the `{data: [...], meta: {...}}` envelope.
ArticleCategoryPage articleCategoryPageFromJson(Map<String, dynamic> json) {
  final items = _readList(json['data']);
  final categories =
      items
          .map(ArticleCategoryModel.fromJson)
          .where((category) => category.id.isNotEmpty && category.isActive)
          .toList()
        ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
  return ArticleCategoryPage(
    categories: categories,
    meta: PaginationMetaModel.fromJson(json['meta'], itemCount: items.length),
  );
}

ArticlePage articlePageFromJson(Map<String, dynamic> json) {
  final items = _readList(json['data']);
  return ArticlePage(
    articles: items
        .map(ArticleModel.fromJson)
        .where((article) => article.id.isNotEmpty && article.isPublished)
        .toList(),
    meta: PaginationMetaModel.fromJson(json['meta'], itemCount: items.length),
  );
}
