import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:tuhfatul_muslim/core/network/language_header_interceptor.dart';
import 'package:tuhfatul_muslim/core/errors/exceptions.dart';
import 'package:tuhfatul_muslim/core/services/api_constants.dart';
import 'package:tuhfatul_muslim/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:tuhfatul_muslim/features/dua/data/models/dua_api_models.dart';
import 'package:tuhfatul_muslim/features/dua/data/models/dua_plan_api_models.dart';

int _asInt(Object? value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;

Map<String, dynamic> _mapOf(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : const {};

abstract interface class DuaRemoteDataSource {
  Future<List<DuaFeaturedModel>> getFeatured();
  Future<List<DuaCategoryModel>> getCategories();
  Future<DuaPage> getByCategory(
    String categoryId, {
    int page = 1,
    int limit = 20,
  });

  /// One dua's full content (`GET /duas/{id}`) — used to show a plan's duas
  /// for reading, since the plan endpoints only guarantee `duaId`.
  Future<DuaFeaturedModel> getDuaById(String id);

  /// Reports dua reading (`POST /duas/reading/track`) — the signed-in
  /// user's access token, `duaId`, the `seconds` spent reading since the
  /// last report and the `date` (`YYYY-MM-DD`) it was read on. The server
  /// awards the Dua point from the day's total: half a point per complete
  /// five minutes, one point at most.
  Future<void> trackReading({
    required String duaId,
    required int seconds,
    required String date,
  });

  /// Dua planner — needs the signed-in user's access token.
  Future<DuaPlanPage> getPlans({String? status, int page = 1, int limit = 10});
  Future<DuaPlan> createPlan(DuaPlanDraft draft);
  Future<DuaPlanDetail> getPlanDetail(String id);
  Future<void> editPlan(String id, DuaPlanDraft draft);
  Future<void> deletePlan(String id);
}

/// Content endpoints are public/read-only; the Dua planner endpoints need the
/// signed-in user's access token (same split as `ZikrRemoteDataSourceImpl`'s
/// public catalog/routines GETs vs. its authenticated plan endpoints).
class DuaRemoteDataSourceImpl implements DuaRemoteDataSource {
  DuaRemoteDataSourceImpl({Dio? dio, AuthLocalDataSource? local})
    : _local = local ?? AuthLocalDataSourceImpl(),
      _dio = dio ?? _buildDio();

  static const baseUrl = ApiConstants.baseUrl;
  final Dio _dio;
  final AuthLocalDataSource _local;

  static Dio _buildDio() {
    final options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
      headers: const {
        'Accept': 'application/json',
        'X-API-Key': ApiConstants.apiKey,
      },
      validateStatus: (status) => status != null && status < 500,
    );
    final dio = Dio(options)
      ..interceptors.add(const LanguageHeaderInterceptor());
    if (kDebugMode) dio.interceptors.add(_DuaApiLogInterceptor());
    return dio;
  }

  @override
  Future<List<DuaFeaturedModel>> getFeatured() async => _dataList(
    await _get('/duas/featured'),
  ).map(DuaFeaturedModel.fromJson).toList(growable: false);

  @override
  Future<List<DuaCategoryModel>> getCategories() async => _dataList(
    await _get('/duas/categories'),
  ).map(DuaCategoryModel.fromJson).toList(growable: false);

  @override
  Future<DuaPage> getByCategory(
    String categoryId, {
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _get(
      '/duas',
      queryParameters: {'categoryId': categoryId, 'page': page, 'limit': limit},
    );
    final body = _body(response);
    final meta = body['meta'] is Map
        ? Map<String, dynamic>.from(body['meta'] as Map)
        : const <String, dynamic>{};
    return DuaPage(
      items: _dataList(
        response,
      ).map(DuaFeaturedModel.fromJson).toList(growable: false),
      page: _asInt(meta['page']) == 0 ? page : _asInt(meta['page']),
      limit: _asInt(meta['limit']) == 0 ? limit : _asInt(meta['limit']),
      total: _asInt(meta['total']),
      totalPage: _asInt(meta['totalPage']),
    );
  }

  @override
  Future<DuaFeaturedModel> getDuaById(String id) async =>
      DuaFeaturedModel.fromJson(_dataMap(await _get('/duas/$id')));

  @override
  Future<void> trackReading({
    required String duaId,
    required int seconds,
    required String date,
  }) => _call(
    () => _dio.post<dynamic>(
      '/duas/reading/track',
      data: {'duaId': duaId, 'seconds': seconds, 'date': date},
      options: _options(requiresAuth: true),
    ),
  );

  @override
  Future<DuaPlanPage> getPlans({
    String? status,
    int page = 1,
    int limit = 10,
  }) async {
    final response = await _get(
      '/duas/planner/plans',
      queryParameters: {'status': ?status, 'page': page, 'limit': limit},
      requiresAuth: true,
    );
    final meta = _mapOf(_body(response)['meta']);
    return DuaPlanPage(
      plans: _dataList(response).map(DuaPlan.fromJson).toList(growable: false),
      page: _asInt(meta['page']) == 0 ? page : _asInt(meta['page']),
      limit: _asInt(meta['limit']) == 0 ? limit : _asInt(meta['limit']),
      total: _asInt(meta['total']),
      totalPage: _asInt(meta['totalPage']),
    );
  }

  @override
  Future<DuaPlan> createPlan(DuaPlanDraft draft) async => DuaPlan.fromJson(
    _dataMap(
      await _call(
        () => _dio.post<dynamic>(
          '/duas/planner/plans',
          data: draft.toJson(),
          options: _options(requiresAuth: true),
        ),
      ),
    ),
  );

  @override
  Future<DuaPlanDetail> getPlanDetail(String id) async =>
      DuaPlanDetail.fromJson(
        _dataMap(await _get('/duas/planner/plans/$id', requiresAuth: true)),
      );

  @override
  Future<void> editPlan(String id, DuaPlanDraft draft) => _call(
    () => _dio.patch<dynamic>(
      '/duas/planner/plans/$id',
      data: draft.toJson(),
      options: _options(requiresAuth: true),
    ),
  );

  @override
  Future<void> deletePlan(String id) => _call(
    () => _dio.delete<dynamic>(
      '/duas/planner/plans/$id',
      options: _options(requiresAuth: true),
    ),
  );

  Future<Response<dynamic>> _get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = false,
  }) => _call(
    () => _dio.get<dynamic>(
      path,
      queryParameters: queryParameters,
      options: _options(requiresAuth: requiresAuth),
    ),
  );

  Options _options({required bool requiresAuth}) {
    final token = _local.getToken();
    if (requiresAuth && (token == null || token.trim().isEmpty)) {
      throw AuthenticationRequiredException();
    }
    return Options(
      headers: token == null ? null : {'Authorization': 'Bearer $token'},
    );
  }

  Future<Response<dynamic>> _call(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      final response = await request();
      _ensureSuccess(response);
      return response;
    } on DioException catch (error) {
      throw NetworkException(error.message ?? 'Network request failed.');
    }
  }

  void _ensureSuccess(Response<dynamic> response) {
    final body = _body(response);
    final success =
        response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300 &&
        body['success'] != false;
    if (success) return;
    if (response.statusCode == 401) throw AuthenticationRequiredException();
    throw ServerException(
      body['message']?.toString() ?? 'Request failed.',
      statusCode: response.statusCode,
    );
  }

  Map<String, dynamic> _body(Response<dynamic> response) => response.data is Map
      ? Map<String, dynamic>.from(response.data as Map)
      : const {};

  Map<String, dynamic> _dataMap(Response<dynamic> response) {
    final data = _body(response)['data'];
    if (data is! Map) throw ParsingException('Dua response data is invalid.');
    return Map<String, dynamic>.from(data);
  }

  List<Map<String, dynamic>> _dataList(Response<dynamic> response) {
    final data = _body(response)['data'];
    if (data is! List) throw ParsingException('Dua response data is invalid.');
    return [
      for (final item in data)
        if (item is Map) Map<String, dynamic>.from(item),
    ];
  }
}

class _DuaApiLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('[DUA API] → ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    debugPrint(
      '[DUA API] ← ${response.statusCode} ${response.requestOptions.uri}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint(
      '[DUA API] ✕ ${err.requestOptions.method} ${err.requestOptions.uri}: '
      '${err.response?.statusCode} ${err.response?.data ?? err.message}',
    );
    handler.next(err);
  }
}
