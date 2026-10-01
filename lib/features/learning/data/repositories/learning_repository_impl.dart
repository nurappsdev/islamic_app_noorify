import 'package:dartz/dartz.dart';

import 'package:tuhfatul_muslim/core/errors/exceptions.dart';
import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/learning/data/datasources/learning_remote_data_source.dart';
import 'package:tuhfatul_muslim/features/learning/domain/entities/article.dart';
import 'package:tuhfatul_muslim/features/learning/domain/repositories/learning_repository.dart';

class LearningRepositoryImpl implements LearningRepository {
  LearningRepositoryImpl(this._remote);

  final LearningRemoteDataSource _remote;

  /// Full articles already read this session, so going back and forth
  /// between a list and an article does not fetch it again.
  final Map<String, Article> _articles = {};

  @override
  Future<Either<Failure, ArticleCategoryPage>> getArticleCategories({
    int page = 1,
    int limit = 10,
  }) => _guard(() => _remote.getArticleCategories(page: page, limit: limit));

  @override
  Future<Either<Failure, ArticlePage>> getArticlesByCategory(
    String categoryId, {
    int page = 1,
    int limit = 10,
    String? searchTerm,
  }) => _guard(
    () => _remote.getArticlesByCategory(
      categoryId,
      page: page,
      limit: limit,
      searchTerm: searchTerm,
    ),
  );

  @override
  Future<Either<Failure, ArticlePage>> searchArticles({
    int page = 1,
    int limit = 10,
    String? categoryId,
    String? searchTerm,
  }) => _guard(
    () => _remote.searchArticles(
      page: page,
      limit: limit,
      categoryId: categoryId,
      searchTerm: searchTerm,
    ),
  );

  @override
  Future<Either<Failure, Article>> getArticleById(String articleId) async {
    final cached = _articles[articleId];
    if (cached != null) return Right(cached);
    final result = await _guard<Article>(
      () => _remote.getArticleById(articleId),
    );
    result.fold((_) {}, (article) => _articles[articleId] = article);
    return result;
  }

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() call) async {
    try {
      return Right(await call());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ParsingException catch (e) {
      return Left(ParsingFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
