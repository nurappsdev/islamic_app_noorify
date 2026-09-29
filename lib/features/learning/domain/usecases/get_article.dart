import 'package:dartz/dartz.dart';

import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/learning/domain/entities/article.dart';
import 'package:tuhfatul_muslim/features/learning/domain/repositories/learning_repository.dart';

class GetArticle {
  const GetArticle(this._repository);

  final LearningRepository _repository;

  Future<Either<Failure, Article>> call(String articleId) =>
      _repository.getArticleById(articleId);
}
