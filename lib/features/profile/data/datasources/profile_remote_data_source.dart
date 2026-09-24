import 'dart:io';

import 'package:dio/dio.dart';

import 'package:islami_app_noorify/core/errors/exceptions.dart';
import 'package:islami_app_noorify/core/network/dio_client.dart';
import 'package:islami_app_noorify/core/services/api_constants.dart';
import 'package:islami_app_noorify/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:islami_app_noorify/features/profile/data/models/profile_model.dart';

/// Talks to `GET`/`PATCH /user/me` and `POST /s3/upload`. Throws
/// [ServerException] / [NetworkException] / [ParsingException]; never
/// returns error states.
abstract interface class ProfileRemoteDataSource {
  Future<ProfileModel> getMe();

  /// PATCHes only the non-null fields. All parameters are optional.
  Future<ProfileModel> updateMe({
    String? name,
    String? phone,
    String? gender,
    String? dateOfBirth,
    String? profession,
    String? location,
    String? preferredLanguage,
    String? avatarUrl,
  });

  /// Uploads [file] to `POST /s3/upload?primaryPath=$primaryPath` and
  /// returns the S3 `publicUrl` from the response.
  Future<String> uploadImage({required File file, required String primaryPath});
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  ProfileRemoteDataSourceImpl({Dio? dio, AuthLocalDataSource? local})
    : _dio = dio ?? DioClient().dio,
      _local = local ?? AuthLocalDataSourceImpl();

  final Dio _dio;
  final AuthLocalDataSource _local;

  @override
  Future<ProfileModel> getMe() async {
    final Response<dynamic> response;
    try {
      response = await _dio.get<dynamic>(
        ApiConstants.getProfileEndPoint,
        options: Options(headers: _authHeaders()),
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
    return _parseProfileResponse(response);
  }

  @override
  Future<ProfileModel> updateMe({
    String? name,
    String? phone,
    String? gender,
    String? dateOfBirth,
    String? profession,
    String? location,
    String? preferredLanguage,
    String? avatarUrl,
  }) async {
    final body = <String, dynamic>{
      'name': ?name,
      'phone': ?phone,
      'gender': ?gender,
      'dateOfBirth': ?dateOfBirth,
      'profession': ?profession,
      'location': ?location,
      'preferredLanguage': ?preferredLanguage,
      'avatarUrl': ?avatarUrl,
    };

    final Response<dynamic> response;
    try {
      response = await _dio.patch<dynamic>(
        ApiConstants.updateProfileEndPoint,
        data: body,
        options: Options(headers: _authHeaders()),
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
    return _parseProfileResponse(response);
  }

  @override
  Future<String> uploadImage({
    required File file,
    required String primaryPath,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.uri.pathSegments.last,
      ),
    });

    final Response<dynamic> response;
    try {
      response = await _dio.post<dynamic>(
        ApiConstants.s3UploadEndPoint,
        data: formData,
        queryParameters: {'primaryPath': primaryPath},
        options: Options(headers: _authHeaders()),
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
        _extractError(json) ?? 'Upload failed ($status).',
        statusCode: status,
      );
    }

    final data = json['data'];
    final publicUrl = data is Map<String, dynamic>
        ? (data['publicUrl'] ?? data['url'])?.toString()
        : null;
    if (publicUrl == null || publicUrl.isEmpty) {
      throw ParsingException('Upload response is missing "publicUrl".');
    }
    return publicUrl;
  }

  Map<String, String>? _authHeaders() {
    final token = _local.getToken();
    return token == null ? null : {'Authorization': 'Bearer $token'};
  }

  /// Unwraps `{ success, data: {...} }` into a [ProfileModel], throwing
  /// [ServerException] / [ParsingException] on anything unexpected.
  ProfileModel _parseProfileResponse(Response<dynamic> response) {
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
      throw ParsingException('Profile response is missing "data".');
    }
    return ProfileModel.fromJson(data);
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
