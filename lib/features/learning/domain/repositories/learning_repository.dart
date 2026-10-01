import 'package:dartz/dartz.dart';

import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/learning/domain/entities/article.dart';

/// Contract for the Learning (articles) API. Every call returns [Right] with
/// the result or [Left] with a typed [Failure].
abstract interface class LearningRepository {
  /// `GET /articles/categories?page=N&limit=N` - active categories.
  Future<Either<Failure, ArticleCategoryPage>> getArticleCategories({
    int page,
    int limit,
  });

  /// `GET /articles/categories/{categoryId}?page=N&limit=N[&searchTerm=..]`.
  Future<Either<Failure, ArticlePage>> getArticlesByCategory(
    String categoryId, {
    int page,
    int limit,
    String? searchTerm,
  });

  /// `GET /articles?page=N&limit=N[&categoryId=..][&searchTerm=..]`.
  Future<Either<Failure, ArticlePage>> searchArticles({
    int page,
    int limit,
    String? categoryId,
    String? searchTerm,
  });

  /// `GET /articles/{articleId}` - the full article, with its content.
  Future<Either<Failure, Article>> getArticleById(String articleId);
}
