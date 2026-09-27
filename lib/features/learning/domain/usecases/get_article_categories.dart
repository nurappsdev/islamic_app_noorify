import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/learning/domain/entities/article.dart';
import 'package:islami_app_noorify/features/learning/domain/repositories/learning_repository.dart';

class GetArticleCategories {
  const GetArticleCategories(this._repository);

  final LearningRepository _repository;

  Future<Either<Failure, ArticleCategoryPage>> call({
    int page = 1,
    int limit = 10,
  }) => _repository.getArticleCategories(page: page, limit: limit);
}
