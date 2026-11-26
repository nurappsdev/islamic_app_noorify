import 'package:dio/dio.dart';

import 'package:tuhfatul_muslim/core/errors/exceptions.dart';
import 'package:tuhfatul_muslim/core/network/dio_client.dart';
import 'package:tuhfatul_muslim/core/services/api_constants.dart';
import 'package:tuhfatul_muslim/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:tuhfatul_muslim/features/settings/data/models/app_update_note_model.dart';
import 'package:tuhfatul_muslim/features/settings/data/models/product_item_model.dart';
import 'package:tuhfatul_muslim/features/settings/data/models/support_overview_model.dart';

/// Talks to the Settings extras (`/settings/our-products`,
/// `/settings/new-updates`, `/settings/overview`) and the support desk
/// (`/support/tickets`, `/support/feedback`). Throws [ServerException] /
/// [NetworkException] / [ParsingException]; never returns error states.
abstract interface class SettingsSupportRemoteDataSource {
  Future<List<ProductItemModel>> getOurProducts();

  Future<AppUpdateNoteModel> getNewUpdates();

  Future<SupportOverviewModel> getOverview();

  /// Returns the server's `message` so the screen can show what it said.
  Future<String> submitTicket({
    required String reason,
    required String description,
  });

  Future<String> submitFeedback({
    required int rating,
    required String feedbackText,
  });
}

class SettingsSupportRemoteDataSourceImpl
    implements SettingsSupportRemoteDataSource {
  SettingsSupportRemoteDataSourceImpl({Dio? dio, AuthLocalDataSource? local})
    : _dio = dio ?? DioClient().dio,
      _local = local ?? AuthLocalDataSourceImpl();

  final Dio _dio;
  final AuthLocalDataSource _local;

  @override
  Future<List<ProductItemModel>> getOurProducts() async {
    final data = await _get(ApiConstants.ourProductsEndPoint);
    // The list may arrive as `data: [...]` or `data: { items: [...] }`.
    final list = data is List
        ? data
        : (data is Map<String, dynamic>
              ? (data['items'] ?? data['products'] ?? data['data'])
              : null);
    if (list is! List) {
      throw ParsingException('Our Products response is missing a list.');
    }
    return list
        .whereType<Map>()
        .map((e) => ProductItemModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<AppUpdateNoteModel> getNewUpdates() async {
    final data = await _get(ApiConstants.newUpdatesEndPoint);
    if (data is! Map<String, dynamic>) {
      throw ParsingException('New Updates response is missing "data".');
    }
    return AppUpdateNoteModel.fromJson(data);
  }

  @override
  Future<SupportOverviewModel> getOverview() async {
    final data = await _get(ApiConstants.settingsOverviewEndPoint);
    if (data is! Map<String, dynamic>) {
      throw ParsingException('Overview response is missing "data".');
    }
    return SupportOverviewModel.fromJson(data);
  }

  @override
  Future<String> submitTicket({
    required String reason,
    required String description,
  }) => _post(ApiConstants.supportTicketsEndPoint, {
    'reason': reason,
    'description': description,
  });

  @override
  Future<String> submitFeedback({
    required int rating,
    required String feedbackText,
  }) => _post(ApiConstants.supportFeedbackEndPoint, {
    'rating': rating,
    'feedbackText': feedbackText,
  });

  /// `GET [path]`, returning the envelope's `data` untouched.
  Future<Object?> _get(String path) async {
    final Response<dynamic> response;
    try {
      response = await _dio.get<dynamic>(
        path,
        options: Options(headers: _authHeaders()),
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
    return _envelope(response)['data'];
  }

  /// `POST [path]` with [body], returning the envelope's `message`.
  Future<String> _post(String path, Map<String, dynamic> body) async {
    final Response<dynamic> response;
    try {
      response = await _dio.post<dynamic>(
        path,
        data: body,
        options: Options(headers: _authHeaders()),
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
    return _envelope(response)['message']?.toString() ?? '';
  }

  Map<String, String>? _authHeaders() {
    final token = _local.getToken();
    return token == null ? null : {'Authorization': 'Bearer $token'};
  }

  /// Checks `{ success, data, message }` and hands back the whole envelope,
  /// throwing [ServerException] on anything the API rejected.
  Map<String, dynamic> _envelope(Response<dynamic> response) {
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
    return json;
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
