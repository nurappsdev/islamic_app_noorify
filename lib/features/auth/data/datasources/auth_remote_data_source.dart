import 'package:dio/dio.dart';

import 'package:islami_app_noorify/core/errors/exceptions.dart';
import 'package:islami_app_noorify/core/network/dio_client.dart';
import 'package:islami_app_noorify/core/services/api_constants.dart';
import 'package:islami_app_noorify/features/auth/data/models/auth_user_model.dart';
import 'package:islami_app_noorify/features/auth/data/models/login_request_model.dart';
import 'package:islami_app_noorify/features/auth/data/models/login_response_model.dart';
import 'package:islami_app_noorify/features/auth/data/models/register_request_model.dart';
import 'package:islami_app_noorify/features/auth/data/models/resend_otp_request_model.dart';
import 'package:islami_app_noorify/features/auth/data/models/verify_otp_request_model.dart';

/// Talks to the REST auth endpoints via Dio. Throws [ServerException] /
/// [NetworkException] / [ParsingException]; never returns error states.
abstract interface class AuthRemoteDataSource {
  Future<AuthUserModel> register(RegisterRequestModel body);

  /// Verifies the e-mail OTP; returns the server confirmation message.
  Future<String> verifyEmail(VerifyOtpRequestModel body);

  /// Requests a fresh OTP e-mail; returns the server confirmation message.
  Future<String> resendOtp(ResendOtpRequestModel body);

  /// Signs in; returns the auth token (+ user when the API includes it).
  Future<LoginResponseModel> login(LoginRequestModel body);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl({Dio? dio}) : _dio = dio ?? DioClient().dio;

  final Dio _dio;

  @override
  Future<AuthUserModel> register(RegisterRequestModel body) async {
    final json = _envelope(await _send(ApiConstants.signUpEndPoint, body.toJson()));
    final payload = json['data'];
    if (payload is! Map<String, dynamic>) {
      throw ParsingException('Registration response is missing "data".');
    }
    return AuthUserModel.fromJson(payload);
  }

  @override
  Future<String> verifyEmail(VerifyOtpRequestModel body) async {
    final json =
        _envelope(await _send(ApiConstants.verifyEmailEndPoint, body.toJson()));
    return json['message']?.toString() ?? 'Your email has been verified.';
  }

  @override
  Future<String> resendOtp(ResendOtpRequestModel body) async {
    final json =
        _envelope(await _send(ApiConstants.resendOtpEndPoint, body.toJson()));
    return json['message']?.toString() ?? 'A new code has been sent to your email.';
  }

  @override
  Future<LoginResponseModel> login(LoginRequestModel body) async {
    final response = await _send(ApiConstants.signInEndPoint, body.toJson());
    final json = _envelope(response);
    final data = json['data'];
    return LoginResponseModel.fromJson(
      data is Map<String, dynamic> ? data : json,
      headerToken: response.headers.value('authorization') ??
          response.headers.value('x-access-token'),
    );
  }

  // ---------------------------------------------------------------------------
  // Shared plumbing
  // ---------------------------------------------------------------------------

  /// POSTs [data] to [path]. Throws [ServerException] for any non-success
  /// response (`success: false`, non-2xx status, auth/validation error body).
  Future<Response<dynamic>> _send(String path, Map<String, dynamic> data) async {
    final Response<dynamic> response;
    try {
      response = await _dio.post<dynamic>(path, data: data);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }

    final body = response.data;
    final json = body is Map<String, dynamic> ? body : const <String, dynamic>{};
    final status = response.statusCode ?? 0;
    final isSuccess =
        status >= 200 && status < 300 && json['success'] != false;

    if (!isSuccess) {
      throw ServerException(
        _extractError(json) ?? 'Request failed ($status).',
        statusCode: status,
      );
    }
    return response;
  }

  Map<String, dynamic> _envelope(Response<dynamic> response) {
    final body = response.data;
    return body is Map<String, dynamic> ? body : const <String, dynamic>{};
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
        final json =
            data is Map<String, dynamic> ? data : const <String, dynamic>{};
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
