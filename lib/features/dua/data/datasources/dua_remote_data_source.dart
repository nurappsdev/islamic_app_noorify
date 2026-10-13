import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:tuhfatul_muslim/core/errors/exceptions.dart';
import 'package:tuhfatul_muslim/core/services/api_constants.dart';
import 'package:tuhfatul_muslim/features/dua/data/models/dua_api_models.dart';

int _asInt(Object? value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;

abstract interface class DuaRemoteDataSource {
  Future<List<DuaFeaturedModel>> getFeatured();
  Future<List<DuaCategoryModel>> getCategories();
  Future<DuaPage> getByCategory(
    String categoryId, {
    int page = 1,
    int limit = 20,
  });
}

/// Public, read-only content endpoints — same host as the rest of the app's
/// API, no access token required (same pattern as the Zikr catalog/routines
/// GETs in `ZikrRemoteDataSourceImpl`).
class DuaRemoteDataSourceImpl implements DuaRemoteDataSource {
  DuaRemoteDataSourceImpl({Dio? dio}) : _dio = dio ?? _buildDio();

  static const baseUrl = ApiConstants.baseUrl;
  final Dio _dio;

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
    final dio = Dio(options);
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

  Future<Response<dynamic>> _get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) => _call(() => _dio.get<dynamic>(path, queryParameters: queryParameters));

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
    throw ServerException(
      body['message']?.toString() ?? 'Request failed.',
      statusCode: response.statusCode,
    );
  }

  Map<String, dynamic> _body(Response<dynamic> response) => response.data is Map
      ? Map<String, dynamic>.from(response.data as Map)
      : const {};

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
