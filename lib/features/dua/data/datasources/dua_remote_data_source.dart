import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:tuhfatul_muslim/core/network/auth_refresh_interceptor.dart';
import 'package:tuhfatul_muslim/core/network/language_header_interceptor.dart';
import 'package:tuhfatul_muslim/core/errors/exceptions.dart';
import 'package:tuhfatul_muslim/core/services/api_constants.dart';
import 'package:tuhfatul_muslim/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:tuhfatul_muslim/features/dua/data/models/dua_api_models.dart';
import 'package:tuhfatul_muslim/features/dua/data/models/dua_plan_api_models.dart';
import 'package:tuhfatul_muslim/features/dua/data/models/dua_reading_api_models.dart';

int _asInt(Object? value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;

Map<String, dynamic> _mapOf(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : const {};

abstract interface class DuaRemoteDataSource {
  Future<List<DuaFeaturedModel>> getFeatured();
  Future<List<DuaCategoryModel>> getCategories();
  Future<DuaCategoryModel> getCategory(String idOrSlug);
  Future<DuaPage> getByCategory(
    String categoryId, {
    int page = 1,
    int limit = 20,
  });
  Future<DuaPage> browseDuas({
    String? categoryId,
    String? category,
    String? searchTerm,
    bool? isFeatured,
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
  Future<DuaFeaturedModel?> getLastRead({String? categoryId});
  Future<DuaReadingHistoryPage> getReadingHistory({
    int page = 1,
    int limit = 20,
  });
  Future<void> deleteReadingHistoryItem(String duaId);
  Future<void> clearReadingHistory();
  Future<DuaDailySummary> getReadingSummary({required String date});
  Future<DuaReadingCalendar> getReadingCalendar({
    int days = 30,
    String? from,
    String? to,
  });
  Future<DuaReadingDashboard> getReadingDashboard({
    required String timeframe,
    String? date,
  });

  /// Dua planner — needs the signed-in user's access token.
  Future<DuaPlanPage> getPlans({String? status, int page = 1, int limit = 10});
  Future<DuaPlan> createPlan(DuaPlanDraft draft);
  Future<DuaPlanDetail> getPlanDetail(String id);
  Future<void> editPlan(String id, DuaPlanDraft draft);
  Future<void> setPlanReminder(String id, {required bool enabled});
  Future<void> deletePlan(String id);
  Future<DuaPlannerToday> getPlannerToday();
  Future<DuaPlanHistory> getPlanHistory(String id, {String? from, String? to});
  Future<void> addPlanItem(String planId, DuaPlanItemDraft item);
  Future<void> removePlanItem(String planId, String duaId);
}

/// Content endpoints are public/read-only; the Dua planner endpoints need the
/// signed-in user's access token (same split as `ZikrRemoteDataSourceImpl`'s
/// public catalog/routines GETs vs. its authenticated plan endpoints).
class DuaRemoteDataSourceImpl implements DuaRemoteDataSource {
  DuaRemoteDataSourceImpl({Dio? dio, AuthLocalDataSource? local})
    : _local = local ?? _defaultLocal(),
      _dio = dio ?? _buildDio() {
    if (_dio.interceptors.whereType<LanguageHeaderInterceptor>().isEmpty) {
      _dio.interceptors.add(const LanguageHeaderInterceptor());
    }
  }

  static const baseUrl = ApiConstants.baseUrl;
  final Dio _dio;

  /// Test seam: lets a test prove the client carries the interceptors the
  /// authenticated planner endpoints depend on.
  @visibleForTesting
  Dio get client => _dio;
  final AuthLocalDataSource? _local;

  static AuthLocalDataSource? _defaultLocal() {
    try {
      return AuthLocalDataSourceImpl();
    } catch (_) {
      // Public browse endpoints are usable before Hive is initialized.
      return null;
    }
  }

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
    if (kDebugMode) dio.interceptors.add(DuaApiLogInterceptor());
    // Without this, an expired access token makes every planner call fail
    // with 401 ("provide a valid access token") until the user signs in
    // again — the shared `DioClient` has carried it all along, but this
    // feature builds its own client.
    dio.interceptors.add(AuthRefreshInterceptor(dio: dio));
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
  Future<DuaCategoryModel> getCategory(String idOrSlug) async =>
      DuaCategoryModel.fromJson(
        _dataMap(await _get('/duas/categories/$idOrSlug')),
      );

  @override
  Future<DuaPage> getByCategory(
    String categoryId, {
    int page = 1,
    int limit = 20,
  }) => browseDuas(categoryId: categoryId, page: page, limit: limit);

  @override
  Future<DuaPage> browseDuas({
    String? categoryId,
    String? category,
    String? searchTerm,
    bool? isFeatured,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _get(
      '/duas',
      queryParameters: {
        'categoryId': ?categoryId,
        'category': ?category,
        'searchTerm': ?searchTerm,
        'isFeatured': ?isFeatured,
        'page': page,
        'limit': limit,
      },
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
  Future<DuaFeaturedModel?> getLastRead({String? categoryId}) async {
    final response = await _get(
      '/duas/reading/last-read',
      queryParameters: {'categoryId': ?categoryId},
      requiresAuth: true,
    );
    final data = _body(response)['data'];
    if (data == null || data is! Map) return null;
    return DuaFeaturedModel.fromJson(Map<String, dynamic>.from(data));
  }

  @override
  Future<DuaReadingHistoryPage> getReadingHistory({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _get(
      '/duas/reading/history',
      queryParameters: {'page': page, 'limit': limit},
      requiresAuth: true,
    );
    final meta = _mapOf(_body(response)['meta']);
    return DuaReadingHistoryPage(
      items: _dataList(
        response,
      ).map(DuaReadingHistoryItem.fromJson).toList(growable: false),
      page: _asInt(meta['page']) == 0 ? page : _asInt(meta['page']),
      totalPage: _asInt(meta['totalPage']),
    );
  }

  @override
  Future<void> deleteReadingHistoryItem(String duaId) => _call(
    () => _dio.delete<dynamic>(
      '/duas/reading/history/$duaId',
      options: _options(requiresAuth: true),
    ),
  );

  @override
  Future<void> clearReadingHistory() => _call(
    () => _dio.delete<dynamic>(
      '/duas/reading/history',
      options: _options(requiresAuth: true),
    ),
  );

  @override
  Future<DuaDailySummary> getReadingSummary({required String date}) async =>
      DuaDailySummary.fromJson(
        _dataMap(
          await _get(
            '/duas/reading/summary',
            queryParameters: {'date': date},
            requiresAuth: true,
          ),
        ),
      );

  @override
  Future<DuaReadingCalendar> getReadingCalendar({
    int days = 30,
    String? from,
    String? to,
  }) async => DuaReadingCalendar.fromJson(
    _dataMap(
      await _get(
        '/duas/reading/calendar',
        // An explicit window wins over the rolling `days` default.
        queryParameters: from != null && to != null
            ? {'from': from, 'to': to}
            : {'days': days},
        requiresAuth: true,
      ),
    ),
  );

  @override
  Future<DuaReadingDashboard> getReadingDashboard({
    required String timeframe,
    String? date,
  }) async => DuaReadingDashboard.fromJson(
    _dataMap(
      await _get(
        '/duas/reading/dashboard',
        queryParameters: {'timeframe': timeframe, 'date': ?date},
        requiresAuth: true,
      ),
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
  Future<DuaPlan> createPlan(DuaPlanDraft draft) async {
    final payload = draft.toJson();
    if (kDebugMode) {
      debugPrint('[DUA API] create plan payload: ${jsonEncode(payload)}');
    }
    return DuaPlan.fromJson(
      _dataMap(
        await _call(
          () => _dio.post<dynamic>(
            '/duas/planner/plans',
            data: payload,
            options: _options(requiresAuth: true),
          ),
        ),
      ),
    );
  }

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

  /// The same `PATCH` as [editPlan], carrying only `reminderEnabled` — the
  /// plan's duas and schedule are left untouched.
  @override
  Future<void> setPlanReminder(String id, {required bool enabled}) => _call(
    () => _dio.patch<dynamic>(
      '/duas/planner/plans/$id',
      data: {'reminderEnabled': enabled},
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

  @override
  Future<DuaPlannerToday> getPlannerToday() async => DuaPlannerToday.fromJson(
    _dataMap(await _get('/duas/planner/today', requiresAuth: true)),
  );

  @override
  Future<DuaPlanHistory> getPlanHistory(
    String id, {
    String? from,
    String? to,
  }) async => DuaPlanHistory.fromJson(
    _dataMap(
      await _get(
        '/duas/planner/plans/$id/history',
        queryParameters: {'from': ?from, 'to': ?to},
        requiresAuth: true,
      ),
    ),
  );

  @override
  Future<void> addPlanItem(String planId, DuaPlanItemDraft item) => _call(
    () => _dio.post<dynamic>(
      '/duas/planner/plans/$planId/items',
      data: item.toJson(),
      options: _options(requiresAuth: true),
    ),
  );

  @override
  Future<void> removePlanItem(String planId, String duaId) => _call(
    () => _dio.delete<dynamic>(
      '/duas/planner/plans/$planId/items/$duaId',
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
    String? token;
    try {
      token = _local?.getToken();
    } catch (_) {
      // Public catalog endpoints must still work while local auth storage is
      // not initialized (for example, a cold-start widget test).
      token = null;
    }
    if (requiresAuth && (token == null || token.trim().isEmpty)) {
      throw AuthenticationRequiredException();
    }
    return Options(
      headers: {
        'X-Timezone': ApiConstants.timezone,
        if (token != null) 'Authorization': 'Bearer $token',
      },
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

/// Traces the dua endpoints in the debug console: every call's method, URI
/// and status, and for the reading report also the exact body sent and the
/// server's answer. Added only in debug builds (see [_buildDio]).
class DuaApiLogInterceptor extends Interceptor {
  /// `POST /duas/reading/track`, whose body is traced field by field.
  static const _trackPath = '/duas/reading/track';

  static bool _isTrack(RequestOptions options) =>
      options.path.endsWith(_trackPath);

  /// The reading report exactly as it goes on the wire: the three fields by
  /// name, then the encoded body, where a quoted value tells a string from a
  /// number at a glance.
  ///
  /// Request headers are never printed — the session's bearer token is one
  /// of them.
  static void _logReadingPayload(RequestOptions options) {
    final data = options.data;
    if (data is Map) {
      debugPrint(
        '[DUA API]   payload duaId=${data['duaId']} '
        'seconds=${data['seconds']} date=${data['date']}',
      );
    }
    debugPrint('[DUA API]   body ${_short(data)}');
  }

  /// [body] as one line, cut short so a long answer stays readable.
  static String _short(Object? body) {
    String text;
    try {
      text = body is String ? body : jsonEncode(body);
    } catch (_) {
      text = '$body';
    }
    return text.length <= 600 ? text : '${text.substring(0, 600)}…';
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('[DUA API] → ${options.method} ${options.uri}');
    if (_isTrack(options)) _logReadingPayload(options);
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
    // Includes a refusal: anything under 500 arrives here, so a rejected
    // report shows the server's own message next to what was sent.
    if (_isTrack(response.requestOptions)) {
      debugPrint('[DUA API]   response ${_short(response.data)}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint(
      '[DUA API] ✕ ${err.requestOptions.method} ${err.requestOptions.uri}: '
      '${err.response?.statusCode} ${err.response?.data ?? err.message}',
    );
    // Not delivered: the repository keeps this report and sends it again.
    if (_isTrack(err.requestOptions)) _logReadingPayload(err.requestOptions);
    handler.next(err);
  }
}
