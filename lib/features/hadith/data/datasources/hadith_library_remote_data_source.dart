import 'package:dio/dio.dart';

import 'package:islami_app_noorify/core/errors/exceptions.dart';
import 'package:islami_app_noorify/core/network/dio_client.dart';
import 'package:islami_app_noorify/core/services/api_constants.dart';
import 'package:islami_app_noorify/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:islami_app_noorify/features/hadith/data/models/ebook_model.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_plan_draft.dart';
import 'package:islami_app_noorify/features/hadith/data/models/hadith_category_page_model.dart';
import 'package:islami_app_noorify/features/hadith/data/models/hadith_detail_model.dart';
import 'package:islami_app_noorify/features/hadith/data/models/hadith_last_read_model.dart';
import 'package:islami_app_noorify/features/hadith/data/models/hadith_plan_model.dart';
import 'package:islami_app_noorify/features/hadith/data/models/hadith_read_record_model.dart';
import 'package:islami_app_noorify/features/hadith/data/models/hadith_reading_comparison_model.dart';
import 'package:islami_app_noorify/features/hadith/data/models/hadith_reading_history_model.dart';
import 'package:islami_app_noorify/features/hadith/data/models/hadith_library_book_model.dart';
import 'package:islami_app_noorify/features/hadith/data/models/hadith_reading_progress_model.dart';
import 'package:islami_app_noorify/features/hadith/data/models/hadith_sub_category_model.dart';

/// Talks to `GET /hadiths/books/lists` and `GET /ebooks` (public — no token
/// needed). Throws
/// [ServerException] / [NetworkException] / [ParsingException]; never returns
/// error states.
abstract interface class HadithLibraryRemoteDataSource {
  Future<List<HadithLibraryBookModel>> getBooks();

  /// `GET /ebooks` — the e-book shelf.
  Future<List<EbookModel>> getEbooks();

  /// `GET /hadiths/categories?bookId=...&page=...&limit=...&searchTerm=...`.
  Future<HadithCategoryPageModel> getCategories(
    String bookId, {
    required int page,
    required int limit,
    String? searchTerm,
  });

  /// `GET /hadiths/categories/{categoryId}/subcategories?page=...&limit=...`
  /// (optionally `&searchTerm=...`).
  Future<HadithSubCategoryPageModel> getSubCategories(
    String categoryId, {
    required int page,
    required int limit,
    String? searchTerm,
  });

  /// `POST /hadiths/reading/track` (needs the login token): reports the
  /// [seconds] spent reading one hadith on [date] (`YYYY-MM-DD`), and whether
  /// it was [completed]. Body: `{hadithId, seconds, completed, date}`.
  Future<void> trackReading({
    required String hadithId,
    required int seconds,
    required bool completed,
    required String date,
  });

  /// `GET /hadiths/reading/progress/categories` (needs the login token): the
  /// overall summary and the progress of every category.
  Future<HadithReadingProgressModel> getReadingProgress();

  /// `GET /hadiths/reading/progress/sub-categories` (needs the login token):
  /// the overall summary and the progress of every sub-category. Same shape as
  /// [getReadingProgress].
  Future<HadithReadingProgressModel> getSubCategoryReadingProgress();

  /// `GET /learning/reading/history?from=...&to=...` (needs the login token):
  /// the reading day by day between [from] and [to] (`YYYY-MM-DD`), with
  /// totals.
  Future<HadithReadingHistoryModel> getReadingHistory({
    required String from,
    required String to,
  });

  /// `GET /hadiths/reading/history/compare?from=...&to=...` (needs the login
  /// token): the user next to another reader over the same dates
  /// (`YYYY-MM-DD`).
  Future<HadithReadingComparisonModel> getReadingComparison({
    required String from,
    required String to,
  });

  /// `GET /hadiths/reading/recent?page=...&limit=...` (needs the login token):
  /// one page of the hadiths the user read, most recent first.
  Future<HadithReadRecordPageModel> getReadRecords({
    required int page,
    required int limit,
  });

  /// `GET /hadiths/plans?status=...&page=...&limit=...` (needs the login
  /// token): one page of the user's plans, each with its `counts`.
  Future<HadithPlanPageModel> getPlans({
    String? status,
    required int page,
    required int limit,
  });

  /// `POST /hadiths/plans` (needs the login token): creates a reading plan.
  /// Body: `{name, bookId, categoryIds?, subCategoryIds?, description?,
  /// targetDays?}`. Answers 201 on success.
  Future<void> createPlan(HadithPlanDraft draft);

  /// `PATCH /hadiths/plans/{id}` (needs the login token): renames the plan
  /// and / or changes its target days. 409 when the new name is taken.
  Future<void> updatePlan(String id, {String? name, int? targetDays});

  /// `DELETE /hadiths/plans/{id}` (needs the login token): removes the plan;
  /// its name becomes free again.
  Future<void> deletePlan(String id);

  /// `GET /hadiths/reading/last-read` (needs the login token): the hadith
  /// read most recently, or null when the user has not read any yet.
  Future<HadithLastReadModel?> getLastRead();

  /// `GET /hadiths?page=...&limit=...` filtered by `subCategoryId` or
  /// `bookId`; or, with [planId], `GET /hadiths/plans/{planId}/hadiths` (needs
  /// the login token): the hadiths of one plan.
  Future<HadithDetailPageModel> getHadiths({
    String? subCategoryId,
    String? bookId,
    String? planId,
    required int page,
    required int limit,
  });
}

class HadithLibraryRemoteDataSourceImpl
    implements HadithLibraryRemoteDataSource {
  HadithLibraryRemoteDataSourceImpl({Dio? dio, AuthLocalDataSource? local})
    : _dio = dio ?? DioClient().dio,
      _local = local ?? AuthLocalDataSourceImpl();

  final Dio _dio;
  final AuthLocalDataSource _local;

  @override
  Future<List<HadithLibraryBookModel>> getBooks() async {
    final envelope = await _getList(
      ApiConstants.hadithBooksListEndPoint,
      // The API paginates at 10 by default; 100 is its maximum.
      {'limit': 100},
      'Hadith books',
    );
    return envelope.items.map(HadithLibraryBookModel.fromJson).toList();
  }

  @override
  Future<List<EbookModel>> getEbooks() async {
    final envelope = await _getList(ApiConstants.ebooksEndPoint, {
      'limit': 50,
    }, 'E-books');
    return envelope.items.map(EbookModel.fromJson).toList();
  }

  @override
  Future<HadithCategoryPageModel> getCategories(
    String bookId, {
    required int page,
    required int limit,
    String? searchTerm,
  }) async {
    final envelope = await _getList(ApiConstants.hadithCategoriesEndPoint, {
      'bookId': bookId,
      'page': page,
      'limit': limit,
      // Matches the category's Bangla, Arabic or English name.
      if (searchTerm != null && searchTerm.isNotEmpty) 'searchTerm': searchTerm,
    }, 'Hadith categories');
    return HadithCategoryPageModel.fromJson(envelope.items, envelope.meta);
  }

  @override
  Future<HadithSubCategoryPageModel> getSubCategories(
    String categoryId, {
    required int page,
    required int limit,
    String? searchTerm,
  }) async {
    final envelope =
        await _getList(ApiConstants.hadithSubCategoriesEndPoint(categoryId), {
          'page': page,
          'limit': limit,
          if (searchTerm != null && searchTerm.isNotEmpty)
            'searchTerm': searchTerm,
        }, 'Hadith sub-categories');
    return HadithSubCategoryPageModel.fromJson(envelope.items, envelope.meta);
  }

  @override
  Future<HadithDetailPageModel> getHadiths({
    String? subCategoryId,
    String? bookId,
    String? planId,
    required int page,
    required int limit,
  }) async {
    if (planId != null) {
      // A plan's hadiths come with their read state, and only for its owner.
      final envelope = await _getList(
        ApiConstants.hadithPlanHadithsEndPoint(planId),
        {'page': page, 'limit': limit},
        'Plan hadiths',
        authenticated: true,
      );
      return HadithDetailPageModel.fromJson([
        for (final item in envelope.items) unwrapPlanHadith(item),
      ], envelope.meta);
    }
    final envelope = await _getList(ApiConstants.hadithsEndPoint, {
      'subCategoryId': ?subCategoryId,
      'bookId': ?bookId,
      'page': page,
      'limit': limit,
    }, 'Hadiths');
    return HadithDetailPageModel.fromJson(envelope.items, envelope.meta);
  }

  @override
  Future<void> trackReading({
    required String hadithId,
    required int seconds,
    required bool completed,
    required String date,
  }) async {
    final token = _local.getToken();
    final Response<dynamic> response;
    try {
      response = await _dio.post<dynamic>(
        ApiConstants.hadithReadingTrackEndPoint,
        data: {
          'hadithId': hadithId,
          'seconds': seconds,
          'completed': completed,
          'date': date,
        },
        options: Options(
          headers: token == null ? null : {'Authorization': 'Bearer $token'},
        ),
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }

    final body = response.data;
    final json = body is Map<String, dynamic>
        ? body
        : const <String, dynamic>{};
    final status = response.statusCode ?? 0;
    final isSuccess = status >= 200 && status < 300 && json['success'] != false;
    if (!isSuccess) {
      throw ServerException(
        _extractError(json) ?? 'Request failed ($status).',
        statusCode: status,
      );
    }
  }

  @override
  Future<HadithReadingProgressModel> getReadingProgress() =>
      _getProgress(ApiConstants.hadithReadingProgressCategoriesEndPoint);

  @override
  Future<HadithReadingProgressModel> getSubCategoryReadingProgress() =>
      _getProgress(ApiConstants.hadithReadingProgressSubCategoriesEndPoint);

  Future<HadithReadingProgressModel> _getProgress(String path) async {
    final token = _local.getToken();
    final Response<dynamic> response;
    try {
      response = await _dio.get<dynamic>(
        path,
        options: Options(
          headers: token == null ? null : {'Authorization': 'Bearer $token'},
        ),
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }

    final body = response.data;
    final json = body is Map<String, dynamic>
        ? body
        : const <String, dynamic>{};
    final status = response.statusCode ?? 0;
    final isSuccess = status >= 200 && status < 300 && json['success'] != false;
    if (!isSuccess) {
      throw ServerException(
        _extractError(json) ?? 'Request failed ($status).',
        statusCode: status,
      );
    }

    final data = json['data'];
    if (data is! Map<String, dynamic>) {
      throw ParsingException('Reading progress response is missing "data".');
    }
    return HadithReadingProgressModel.fromJson(data);
  }

  @override
  Future<HadithReadingHistoryModel> getReadingHistory({
    required String from,
    required String to,
  }) async => HadithReadingHistoryModel.fromJson(
    await _getAuthedData(ApiConstants.hadithReadingHistoryEndPoint, {
      'from': from,
      'to': to,
    }, 'Reading history'),
  );

  @override
  Future<HadithReadingComparisonModel> getReadingComparison({
    required String from,
    required String to,
  }) async => HadithReadingComparisonModel.fromJson(
    await _getAuthedData(ApiConstants.hadithReadingCompareEndPoint, {
      'from': from,
      'to': to,
    }, 'Reading comparison'),
  );

  /// GETs [path] with the login token and returns the envelope's `data`
  /// object, throwing the data-layer exceptions on any failure.
  Future<Map<String, dynamic>> _getAuthedData(
    String path,
    Map<String, dynamic> query,
    String what,
  ) async {
    final token = _local.getToken();
    final Response<dynamic> response;
    try {
      response = await _dio.get<dynamic>(
        path,
        queryParameters: query,
        options: Options(
          headers: token == null ? null : {'Authorization': 'Bearer $token'},
        ),
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }

    final body = response.data;
    final json = body is Map<String, dynamic>
        ? body
        : const <String, dynamic>{};
    final status = response.statusCode ?? 0;
    final isSuccess = status >= 200 && status < 300 && json['success'] != false;
    if (!isSuccess) {
      throw ServerException(
        _extractError(json) ?? 'Request failed ($status).',
        statusCode: status,
      );
    }

    final data = json['data'];
    if (data is! Map<String, dynamic>) {
      throw ParsingException('$what response is missing "data".');
    }
    return data;
  }

  @override
  Future<HadithReadRecordPageModel> getReadRecords({
    required int page,
    required int limit,
  }) async {
    final envelope = await _getList(
      ApiConstants.hadithReadingRecentEndPoint,
      {'page': page, 'limit': limit},
      'Reading history',
      authenticated: true,
    );
    return HadithReadRecordPageModel.fromJson(envelope.items, envelope.meta);
  }

  @override
  Future<HadithPlanPageModel> getPlans({
    String? status,
    required int page,
    required int limit,
  }) async {
    final envelope = await _getList(
      ApiConstants.hadithPlansEndPoint,
      {
        if (status != null && status.isNotEmpty) 'status': status,
        'page': page,
        'limit': limit,
      },
      'Hadith plans',
      authenticated: true,
    );
    return HadithPlanPageModel.fromJson(envelope.items, envelope.meta);
  }

  @override
  Future<void> createPlan(HadithPlanDraft draft) => _sendAuthed(
    'POST',
    ApiConstants.hadithPlansEndPoint,
    data: draft.toJson(),
  );

  @override
  Future<void> updatePlan(String id, {String? name, int? targetDays}) =>
      _sendAuthed(
        'PATCH',
        ApiConstants.hadithPlanEndPoint(id),
        // Only what changes; the API leaves the rest as it is.
        data: {'name': ?name, 'targetDays': ?targetDays},
      );

  @override
  Future<void> deletePlan(String id) =>
      _sendAuthed('DELETE', ApiConstants.hadithPlanEndPoint(id));

  /// Sends [method] to [path] with the login token, and throws the data-layer
  /// exceptions unless the API answers with a success. A refusal carries the
  /// API's own message — 400 invalid, 404 not found, 409 name taken — so the
  /// user sees why.
  Future<void> _sendAuthed(String method, String path, {Object? data}) async {
    final token = _local.getToken();
    final Response<dynamic> response;
    try {
      response = await _dio.request<dynamic>(
        path,
        data: data,
        options: Options(
          method: method,
          headers: token == null ? null : {'Authorization': 'Bearer $token'},
        ),
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }

    final body = response.data;
    final json = body is Map<String, dynamic>
        ? body
        : const <String, dynamic>{};
    final status = response.statusCode ?? 0;
    final isSuccess = status >= 200 && status < 300 && json['success'] != false;
    if (!isSuccess) {
      throw ServerException(
        _extractError(json) ?? 'Request failed ($status).',
        statusCode: status,
      );
    }
  }

  @override
  Future<HadithLastReadModel?> getLastRead() async {
    final token = _local.getToken();
    final Response<dynamic> response;
    try {
      response = await _dio.get<dynamic>(
        ApiConstants.hadithLastReadEndPoint,
        options: Options(
          headers: token == null ? null : {'Authorization': 'Bearer $token'},
        ),
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }

    final body = response.data;
    final json = body is Map<String, dynamic>
        ? body
        : const <String, dynamic>{};
    final status = response.statusCode ?? 0;
    final isSuccess = status >= 200 && status < 300 && json['success'] != false;
    if (!isSuccess) {
      throw ServerException(
        _extractError(json) ?? 'Request failed ($status).',
        statusCode: status,
      );
    }

    final data = json['data'];
    if (data is! Map<String, dynamic>) {
      throw ParsingException('Last read response is missing "data".');
    }
    final lastRead = data['lastRead'];
    if (lastRead is! Map<String, dynamic>) return null;
    final model = HadithLastReadModel.fromJson(lastRead);
    return model.hadithId.isEmpty ? null : model;
  }

  /// GETs [path] and returns the envelope's `data` array (as maps) and `meta`,
  /// throwing the data-layer exceptions on any failure. Public endpoints need
  /// no token; pass [authenticated] to send the login token.
  Future<({List<Map<String, dynamic>> items, Map<String, dynamic> meta})>
  _getList(
    String path,
    Map<String, dynamic> query,
    String what, {
    bool authenticated = false,
  }) async {
    final token = authenticated ? _local.getToken() : null;
    final Response<dynamic> response;
    try {
      response = await _dio.get<dynamic>(
        path,
        queryParameters: query,
        options: token == null
            ? null
            : Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }

    final body = response.data;
    final json = body is Map<String, dynamic>
        ? body
        : const <String, dynamic>{};
    final status = response.statusCode ?? 0;
    final isSuccess = status >= 200 && status < 300 && json['success'] != false;
    if (!isSuccess) {
      throw ServerException(
        _extractError(json) ?? 'Request failed ($status).',
        statusCode: status,
      );
    }

    final data = json['data'];
    if (data is! List) {
      throw ParsingException('$what response is missing "data".');
    }
    final meta = json['meta'];
    return (
      items: data.whereType<Map<String, dynamic>>().toList(),
      meta: meta is Map<String, dynamic> ? meta : const <String, dynamic>{},
    );
  }

  Exception _mapDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return NetworkException('The request timed out. Please try again.');
      case DioExceptionType.connectionError:
        return NetworkException();
      case DioExceptionType.badCertificate:
        return NetworkException('Could not establish a secure connection.');
      case DioExceptionType.cancel:
        return NetworkException('The request was cancelled.');
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        final data = e.response?.data;
        final json = data is Map<String, dynamic>
            ? data
            : const <String, dynamic>{};
        return ServerException(
          _extractError(json) ??
              'Request failed (${e.response?.statusCode ?? 'network error'}).',
          statusCode: e.response?.statusCode,
        );
    }
  }

  String? _extractError(Map<String, dynamic> json) {
    final sources = json['errorSources'];
    if (sources is List && sources.isNotEmpty) {
      final messages = sources
          .whereType<Map>()
          .map((e) => e['message']?.toString())
          .where((m) => m != null && m.isNotEmpty)
          .join('\n');
      if (messages.isNotEmpty) return messages;
    }
    final message = json['message']?.toString();
    return (message != null && message.isNotEmpty) ? message : null;
  }
}
