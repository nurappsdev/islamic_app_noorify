import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:tuhfatul_muslim/core/errors/exceptions.dart';
import 'package:tuhfatul_muslim/core/network/auth_refresh_interceptor.dart';
import 'package:tuhfatul_muslim/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:tuhfatul_muslim/features/zikr/data/models/zikr_api_models.dart';

abstract interface class ZikrRemoteDataSource {
  Future<UserTasbihProfile> getProfile();
  Future<List<ZikrRoutine>> getRoutines();
  Future<List<ZikrCatalogItem>> getCatalog();
  Future<ZikrCatalogItem> createCatalog(Map<String, dynamic> body);
  Future<ZikrCatalogItem> updateCatalog(String id, Map<String, dynamic> body);
  Future<void> deleteCatalog(String id);
  Future<ZikrRoutine> createRoutine(Map<String, dynamic> body);
  Future<ZikrRoutine> updateRoutine(String id, Map<String, dynamic> body);
  Future<void> deleteRoutine(String id);
  Future<UserTasbihProfile> increment(Map<String, dynamic> body);
  Future<List<ZikrPlan>> getPlans({String? status, String? type});
  Future<ZikrPlan> createPlan(Map<String, dynamic> body);
  Future<ZikrPlan> enrollPlan(String id);
  Future<ZikrPlan> incrementPlan(String id, int countAdded);
  Future<void> deletePlan(String id);
  Future<TasbihAnalyticsResponse> getAnalytics(String period);
  Future<PaginatedHistory> getHistory({required int page, required int limit});
}

class ZikrRemoteDataSourceImpl implements ZikrRemoteDataSource {
  ZikrRemoteDataSourceImpl({Dio? dio, AuthLocalDataSource? local})
    : _local = local ?? AuthLocalDataSourceImpl(),
      _dio = dio ?? _buildDio();

  static const baseUrl = 'https://tuhfatulmuslim1.ilmifygroup.com/api/v1';
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
      headers: const {'Accept': 'application/json'},
      validateStatus: (status) => status != null && status < 500,
    );
    final dio = Dio(options);
    // The feature is served from its own documented host, so the refresh
    // request must use that same host rather than the app-wide API base URL.
    dio.interceptors.add(
      AuthRefreshInterceptor(dio: dio, refreshDio: Dio(options)),
    );
    if (kDebugMode) dio.interceptors.add(_ZikrApiLogInterceptor());
    return dio;
  }

  @override
  Future<UserTasbihProfile> getProfile() async =>
      UserTasbihProfile.fromJson(_dataMap(await _get('/zikr/tasbih/profile')));

  @override
  Future<List<ZikrRoutine>> getRoutines() async => _dataList(
    await _get('/zikr/routines', requiresAuth: false),
  ).map(ZikrRoutine.fromJson).toList(growable: false);

  @override
  Future<List<ZikrCatalogItem>> getCatalog() async => _dataList(
    await _get('/zikr/catalog', requiresAuth: false),
  ).map(ZikrCatalogItem.fromJson).toList(growable: false);

  @override
  Future<ZikrCatalogItem> createCatalog(Map<String, dynamic> body) async =>
      ZikrCatalogItem.fromJson(_dataMap(await _post('/zikr/catalog', body)));

  @override
  Future<ZikrCatalogItem> updateCatalog(
    String id,
    Map<String, dynamic> body,
  ) async => ZikrCatalogItem.fromJson(
    _dataMap(await _patch('/zikr/catalog/$id', body)),
  );

  @override
  Future<void> deleteCatalog(String id) => _delete('/zikr/catalog/$id');

  @override
  Future<ZikrRoutine> createRoutine(Map<String, dynamic> body) async =>
      ZikrRoutine.fromJson(_dataMap(await _post('/zikr/routines', body)));

  @override
  Future<ZikrRoutine> updateRoutine(
    String id,
    Map<String, dynamic> body,
  ) async =>
      ZikrRoutine.fromJson(_dataMap(await _patch('/zikr/routines/$id', body)));

  @override
  Future<void> deleteRoutine(String id) => _delete('/zikr/routines/$id');

  @override
  Future<UserTasbihProfile> increment(Map<String, dynamic> body) async {
    final data = _dataMap(await _post('/zikr/tasbih/increment', body));
    final profile = data['profile'];
    return UserTasbihProfile.fromJson(
      profile is Map ? Map<String, dynamic>.from(profile) : data,
    );
  }

  @override
  Future<List<ZikrPlan>> getPlans({String? status, String? type}) async =>
      _dataList(
        await _get('/zikr/plans', query: {'status': ?status, 'type': ?type}),
      ).map(ZikrPlan.fromJson).toList(growable: false);

  @override
  Future<ZikrPlan> createPlan(Map<String, dynamic> body) async =>
      ZikrPlan.fromJson(_dataMap(await _post('/zikr/plans', body)));

  @override
  Future<ZikrPlan> enrollPlan(String id) async =>
      ZikrPlan.fromJson(_dataMap(await _post('/zikr/plans/$id/enroll', {})));

  @override
  Future<ZikrPlan> incrementPlan(String id, int countAdded) async =>
      ZikrPlan.fromJson(
        _dataMap(
          await _patch('/zikr/plans/$id/progress', {'countAdded': countAdded}),
        ),
      );

  @override
  Future<void> deletePlan(String id) => _delete('/zikr/plans/$id');

  @override
  Future<TasbihAnalyticsResponse> getAnalytics(String period) async =>
      TasbihAnalyticsResponse.fromJson(
        _dataMap(await _get('/zikr/analytics', query: {'period': period})),
      );

  @override
  Future<PaginatedHistory> getHistory({
    required int page,
    required int limit,
  }) async {
    final response = await _get(
      '/zikr/history',
      query: {'page': page, 'limit': limit},
    );
    final body = _body(response);
    final data = body['data'];
    return PaginatedHistory(
      items: [
        for (final item in data as List? ?? const [])
          if (item is Map)
            ZikrSessionHistory.fromJson(Map<String, dynamic>.from(item)),
      ],
      meta: PaginationMeta.fromJson(
        body['meta'] is Map
            ? Map<String, dynamic>.from(body['meta'] as Map)
            : const {},
      ),
    );
  }

  Future<Response<dynamic>> _get(
    String path, {
    Map<String, dynamic>? query,
    bool requiresAuth = true,
  }) => _call(
    () => _dio.get<dynamic>(
      path,
      queryParameters: query,
      options: _options(requiresAuth: requiresAuth),
    ),
  );
  Future<Response<dynamic>> _post(String path, Map<String, dynamic> body) =>
      _call(() => _dio.post<dynamic>(path, data: body, options: _options()));
  Future<Response<dynamic>> _patch(String path, Map<String, dynamic> body) =>
      _call(() => _dio.patch<dynamic>(path, data: body, options: _options()));
  Future<void> _delete(String path) async => _ensureSuccess(
    await _call(() => _dio.delete<dynamic>(path, options: _options())),
  );

  Options _options({bool requiresAuth = true}) {
    final token = _local.getToken();
    if (requiresAuth && (token == null || token.trim().isEmpty)) {
      if (kDebugMode) {
        debugPrint('[ZIKR AUTH] access token: absent — login required');
      }
      throw AuthenticationRequiredException();
    }
    if (kDebugMode) {
      debugPrint(
        '[ZIKR AUTH] access token: '
        '${token == null || token.isEmpty ? 'not attached (public request)' : 'attached'}',
      );
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
    if (response.statusCode == 401) {
      throw AuthenticationRequiredException();
    }
    final error = ApiErrorResponse.fromJson(body);
    final details = error.errorSources
        .map((source) => source.message)
        .where((message) => message.isNotEmpty)
        .join('\n');
    throw ServerException(
      details.isEmpty ? error.message : details,
      statusCode: response.statusCode,
    );
  }

  Map<String, dynamic> _body(Response<dynamic> response) => response.data is Map
      ? Map<String, dynamic>.from(response.data as Map)
      : const {};
  Map<String, dynamic> _dataMap(Response<dynamic> response) {
    final data = _body(response)['data'];
    if (data is! Map) throw ParsingException('Zikr response is missing data.');
    return Map<String, dynamic>.from(data);
  }

  List<Map<String, dynamic>> _dataList(Response<dynamic> response) {
    final data = _body(response)['data'];
    if (data is! List) throw ParsingException('Zikr response data is invalid.');
    return [
      for (final item in data)
        if (item is Map) Map<String, dynamic>.from(item),
    ];
  }
}

/// Debug-only, Zikr-specific network log. Auth values are deliberately
/// redacted, while request data and full response bodies remain visible for
/// backend integration debugging.
class _ZikrApiLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('[ZIKR API] → ${options.method} ${options.uri}');
    debugPrint('[ZIKR API] request body: ${options.data}');
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    debugPrint(
      '[ZIKR API] ← ${response.statusCode} ${response.requestOptions.uri}',
    );
    debugPrint('[ZIKR API] response body: ${response.data}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint(
      '[ZIKR API] ✕ ${err.requestOptions.method} ${err.requestOptions.uri}',
    );
    debugPrint(
      '[ZIKR API] error: ${err.response?.statusCode} ${err.response?.data ?? err.message}',
    );
    handler.next(err);
  }
}
