import 'package:dio/dio.dart';

import 'package:islami_app_noorify/core/errors/exceptions.dart';
import 'package:islami_app_noorify/core/network/dio_client.dart';
import 'package:islami_app_noorify/core/services/api_constants.dart';
import 'package:islami_app_noorify/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:islami_app_noorify/features/learning/data/models/article_model.dart';
import 'package:islami_app_noorify/features/learning/domain/entities/article.dart';
import 'package:islami_app_noorify/features/quiz/data/datasources/quiz_api_requests.dart';

/// Talks to the article REST endpoints. Throws [ServerException] /
/// [NetworkException] / [ParsingException]; never returns error states.
abstract interface class LearningRemoteDataSource {
  Future<ArticleCategoryPage> getArticleCategories({
    required int page,
    required int limit,
  });

  Future<ArticlePage> getArticlesByCategory(
    String categoryId, {
    required int page,
    required int limit,
    String? searchTerm,
  });

  Future<ArticlePage> searchArticles({
    required int page,
    required int limit,
    String? categoryId,
    String? searchTerm,
  });

  Future<ArticleModel> getArticleById(String articleId);
}

/// Shares the quiz requests' token handling and error envelope.
class LearningRemoteDataSourceImpl
    with QuizApiRequests
    implements LearningRemoteDataSource {
  LearningRemoteDataSourceImpl({Dio? dio, AuthLocalDataSource? local})
    : dio = dio ?? DioClient().dio,
      local = local ?? AuthLocalDataSourceImpl();

  @override
  final Dio dio;
  @override
  final AuthLocalDataSource local;

  @override
  Future<ArticleCategoryPage> getArticleCategories({
    required int page,
    required int limit,
  }) async {
    final json = await sendQuizRequest(
      () => dio.get<dynamic>(
        ApiConstants.articleCategoriesEndPoint,
        queryParameters: {'page': page, 'limit': limit},
        options: quizAuthOptions(),
      ),
    );
    _requireList(json, 'Article categories');
    return articleCategoryPageFromJson(json);
  }

  @override
  Future<ArticlePage> getArticlesByCategory(
    String categoryId, {
    required int page,
    required int limit,
    String? searchTerm,
  }) async {
    final json = await sendQuizRequest(
      () => dio.get<dynamic>(
        ApiConstants.articleCategoryArticlesEndPoint(
          Uri.encodeComponent(categoryId),
        ),
        queryParameters: {'page': page, 'limit': limit, ..._search(searchTerm)},
        options: quizAuthOptions(),
      ),
    );
    _requireList(json, 'Articles');
    return articlePageFromJson(json);
  }

  @override
  Future<ArticlePage> searchArticles({
    required int page,
    required int limit,
    String? categoryId,
    String? searchTerm,
  }) async {
    final json = await sendQuizRequest(
      () => dio.get<dynamic>(
        ApiConstants.articlesEndPoint,
        queryParameters: {
          if (categoryId != null && categoryId.isNotEmpty)
            'categoryId': categoryId,
          'page': page,
          'limit': limit,
          ..._search(searchTerm),
        },
        options: quizAuthOptions(),
      ),
    );
    _requireList(json, 'Articles');
    return articlePageFromJson(json);
  }

  @override
  Future<ArticleModel> getArticleById(String articleId) async {
    final json = await sendQuizRequest(
      () => dio.get<dynamic>(
        ApiConstants.articleEndPoint(Uri.encodeComponent(articleId)),
        options: quizAuthOptions(),
      ),
    );
    final article = ArticleModel.fromJson(quizDataMap(json, 'Article'));
    // A draft is as good as missing to a reader.
    if (!article.isPublished) {
      throw ServerException('Article unavailable', statusCode: 404);
    }
    return article;
  }

  Map<String, String> _search(String? term) {
    final trimmed = term?.trim() ?? '';
    return trimmed.isEmpty ? const {} : {'searchTerm': trimmed};
  }

  void _requireList(Map<String, dynamic> json, String what) {
    if (json['data'] is! List) {
      throw ParsingException('$what response is missing "data".');
    }
  }
}
