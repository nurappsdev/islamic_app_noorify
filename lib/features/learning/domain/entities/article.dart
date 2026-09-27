import 'package:islami_app_noorify/core/utils/localized_text.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz_dashboard.dart';

/// A Learning category (`GET /articles/categories`). Shared with the quiz
/// categories on the server.
class ArticleCategory {
  const ArticleCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.displayOrder,
    required this.isActive,
    required this.totalArticles,
  });

  final String id;
  final LocalizedText name;
  final LocalizedText description;
  final int displayOrder;
  final bool isActive;

  /// Published articles in the category.
  final int totalArticles;
}

/// An article. List endpoints send a summary, so [content] is only filled by
/// `GET /articles/{id}`.
class Article {
  const Article({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.title,
    required this.excerpt,
    required this.content,
    required this.author,
    required this.coverImageUrl,
    required this.status,
    required this.publishedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? categoryId;
  final LocalizedText categoryName;
  final LocalizedText title;
  final LocalizedText excerpt;

  /// Markdown, in both languages.
  final LocalizedText content;
  final String author;
  final String? coverImageUrl;

  /// `published` or `draft`; `null` when the server left it out.
  final String? status;
  final DateTime? publishedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Reader endpoints only return published articles; anything else that
  /// slips through is not shown.
  bool get isPublished => status == null || status == 'published';

  /// When it went out, or when it was written if that is all there is.
  DateTime? get displayDate => publishedAt ?? createdAt;
}

class ArticleCategoryPage {
  const ArticleCategoryPage({required this.categories, required this.meta});

  final List<ArticleCategory> categories;
  final PaginationMeta meta;
}

class ArticlePage {
  const ArticlePage({required this.articles, required this.meta});

  final List<Article> articles;
  final PaginationMeta meta;
}

/// Which articles a list shows: one category's, or all of them.
class ArticleListScope {
  const ArticleListScope.category(ArticleCategory this.category);

  const ArticleListScope.all() : category = null;

  final ArticleCategory? category;
}
