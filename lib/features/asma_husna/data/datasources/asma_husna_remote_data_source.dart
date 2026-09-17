import 'package:dio/dio.dart';

import 'package:islami_app_noorify/core/errors/exceptions.dart';
import 'package:islami_app_noorify/core/network/dio_client.dart';
import 'package:islami_app_noorify/core/services/api_constants.dart';
import 'package:islami_app_noorify/features/asma_husna/data/models/asma_name_detail_model.dart';
import 'package:islami_app_noorify/features/asma_husna/data/models/asma_name_model.dart';

/// Talks to the Asma-ul-Husna REST endpoint. Throws [ServerException] /
/// [NetworkException] / [ParsingException]; never returns error states.
abstract interface class AsmaHusnaRemoteDataSource {
  /// `GET /asma-ul-husna?page=1&limit=99&sort=displayOrder _id&fields=...`
  /// — `limit` covers all 99 names in one request since the list is fixed
  /// size, and `fields` now also pulls each name's full explanation
  /// (`meaningEnglish`/`explanationParagraphs`) so this single call is
  /// enough to populate the local cache for both the list and detail
  /// screens (see `AsmaHusnaLocalDataSource`) — no separate per-id
  /// `getNameDetail` round trip needed once it's synced.
  Future<List<AsmaNameModel>> getNames();

  /// `GET /asma-ul-husna/{id}` — the full explanation for one name.
  Future<AsmaNameDetailModel> getNameDetail(String id);
}

class AsmaHusnaRemoteDataSourceImpl implements AsmaHusnaRemoteDataSource {
  AsmaHusnaRemoteDataSourceImpl({Dio? dio}) : _dio = dio ?? DioClient().dio;

  final Dio _dio;

  @override
  Future<List<AsmaNameModel>> getNames() async {
    final Response<dynamic> response;
    try {
      response = await _dio.get<dynamic>(
        ApiConstants.asmaUlHusnaEndPoint,
        queryParameters: {
          'page': 1,
          'limit': 99,
          'sort': 'displayOrder _id',
          'fields':
              'meaningBangla,serialNumberBangla,nameArabic,nameBangla,'
              'displayOrder,audioUrl,nameTransliteration,meaningEnglish,'
              'explanationParagraphs',
        },
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
      throw ParsingException('Asma-ul-Husna response is missing "data".');
    }
    return data
        .whereType<Map>()
        .map((e) => AsmaNameModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<AsmaNameDetailModel> getNameDetail(String id) async {
    final Response<dynamic> response;
    try {
      response = await _dio.get<dynamic>(
        ApiConstants.asmaUlHusnaDetailEndPoint(id),
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
    if (data is! Map) {
      throw ParsingException(
        'Asma-ul-Husna detail response is missing "data".',
      );
    }
    return AsmaNameDetailModel.fromJson(Map<String, dynamic>.from(data));
  }

  /// Turns a low-level [DioException] into one of our data-layer exceptions.
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

  /// Reads a message out of `{ errorSources: [{message}], message }`.
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
