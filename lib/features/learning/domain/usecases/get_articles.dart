import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/learning/domain/entities/article.dart';
import 'package:islami_app_noorify/features/learning/domain/repositories/learning_repository.dart';

/// One page of a list's articles: a category's from its own endpoint, or
/// every category's from the general one.
class GetArticles {
  const GetArticles(this._repository);

  final LearningRepository _repository;

  Future<Either<Failure, ArticlePage>> call(
    ArticleListScope scope, {
    int page = 1,
    int limit = 10,
    String? searchTerm,
  }) {
    final category = scope.category;
    if (category != null) {
      return _repository.getArticlesByCategory(
        category.id,
        page: page,
        limit: limit,
        searchTerm: searchTerm,
      );
    }
    return _repository.searchArticles(
      page: page,
      limit: limit,
      searchTerm: searchTerm,
    );
  }
}
