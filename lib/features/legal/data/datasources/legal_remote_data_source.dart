import 'package:dio/dio.dart';

import 'package:islami_app_noorify/core/errors/exceptions.dart';
import 'package:islami_app_noorify/core/network/dio_client.dart';
import 'package:islami_app_noorify/core/services/api_constants.dart';
import 'package:islami_app_noorify/features/legal/data/models/legal_document_model.dart';
import 'package:islami_app_noorify/features/legal/domain/entities/legal_document.dart';

/// Talks to the public `/settings/...` endpoints (no auth needed, so they work
/// on the Sign Up screen). Throws [ServerException] / [NetworkException] /
/// [ParsingException].
abstract interface class LegalRemoteDataSource {
  Future<LegalDocumentModel> getDocument(LegalDocumentType type);
}

class LegalRemoteDataSourceImpl implements LegalRemoteDataSource {
  LegalRemoteDataSourceImpl({Dio? dio}) : _dio = dio ?? DioClient().dio;

  final Dio _dio;

  @override
  Future<LegalDocumentModel> getDocument(LegalDocumentType type) async {
    final path = switch (type) {
      LegalDocumentType.aboutUs => ApiConstants.aboutUsEndPoint,
      LegalDocumentType.termsOfService => ApiConstants.termsOfServiceEndPoint,
      LegalDocumentType.privacyPolicy => ApiConstants.privacyPolicyEndPoint,
    };

    final Response<dynamic> response;
    try {
      response = await _dio.get<dynamic>(path);
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
      throw ParsingException('Response is missing "data".');
    }
    return LegalDocumentModel.fromJson(data);
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
