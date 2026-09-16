import 'package:dio/dio.dart';

import 'package:islami_app_noorify/core/errors/exceptions.dart';
import 'package:islami_app_noorify/core/network/dio_client.dart';
import 'package:islami_app_noorify/core/services/api_constants.dart';
import 'package:islami_app_noorify/features/alarm/data/models/alarm_dashboard_model.dart';
import 'package:islami_app_noorify/features/alarm/data/models/ringtone_model.dart';
import 'package:islami_app_noorify/features/alarm/domain/entities/alarm_entry.dart';
import 'package:islami_app_noorify/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:islami_app_noorify/features/home/domain/daily_prayer_times.dart';
import 'package:islami_app_noorify/features/home/domain/prayer_theme_schedule.dart';

/// Talks to the custom-alarm REST endpoints. Throws [ServerException] /
/// [NetworkException] / [ParsingException]; never returns error states.
abstract interface class AlarmRemoteDataSource {
  /// `POST /alarms/custom`.
  Future<void> createAlarm(AlarmEntry alarm);

  /// `GET /alarms` — the countdown text and the prayer-alarms list.
  Future<AlarmDashboardModel> getAlarmDashboard();

  /// `GET /alarms/ringtones`.
  Future<List<RingtoneModel>> getRingtones();

  /// `PATCH /alarms/custom/{id}` with `{ "isEnabled": enabled }`.
  Future<void> updateAlarmEnabled({required String id, required bool enabled});

  /// `DELETE /alarms/custom/{id}`.
  Future<void> deleteAlarm(String id);

  /// `DELETE /alarms/ringtones/{id}`.
  Future<void> deleteRingtone(String id);
}

class AlarmRemoteDataSourceImpl implements AlarmRemoteDataSource {
  AlarmRemoteDataSourceImpl({Dio? dio, AuthLocalDataSource? local})
    : _dio = dio ?? DioClient().dio,
      _local = local ?? AuthLocalDataSourceImpl();

  final Dio _dio;
  final AuthLocalDataSource _local;

  @override
  Future<void> createAlarm(AlarmEntry alarm) async {
    final Response<dynamic> response;
    try {
      response = await _dio.post<dynamic>(
        ApiConstants.alarmsCustomEndPoint,
        data: _toRequestJson(alarm),
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
        _extractError(json) ?? 'Request failed ($status).',
        statusCode: status,
      );
    }
  }

  @override
  Future<AlarmDashboardModel> getAlarmDashboard() async {
    final Response<dynamic> response;
    try {
      response = await _dio.get<dynamic>(
        ApiConstants.alarmsDashboardEndPoint,
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
        _extractError(json) ?? 'Request failed ($status).',
        statusCode: status,
      );
    }

    final data = json['data'];
    if (data is! Map<String, dynamic>) {
      throw ParsingException('Alarm dashboard response is missing "data".');
    }
    return AlarmDashboardModel.fromJson(data);
  }

  @override
  Future<List<RingtoneModel>> getRingtones() async {
    final Response<dynamic> response;
    try {
      response = await _dio.get<dynamic>(
        ApiConstants.alarmsRingtonesEndPoint,
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
        _extractError(json) ?? 'Request failed ($status).',
        statusCode: status,
      );
    }

    final data = json['data'];
    if (data is! List) {
      throw ParsingException('Ringtone catalog response is missing "data".');
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map(RingtoneModel.fromJson)
        .toList();
  }

  @override
  Future<void> updateAlarmEnabled({
    required String id,
    required bool enabled,
  }) async {
    final Response<dynamic> response;
    try {
      response = await _dio.patch<dynamic>(
        ApiConstants.alarmCustomItemEndPoint(id),
        data: {'isEnabled': enabled},
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
        _extractError(json) ?? 'Request failed ($status).',
        statusCode: status,
      );
    }
  }

  @override
  Future<void> deleteAlarm(String id) async {
    final Response<dynamic> response;
    try {
      response = await _dio.delete<dynamic>(
        ApiConstants.alarmCustomItemEndPoint(id),
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
        _extractError(json) ?? 'Request failed ($status).',
        statusCode: status,
      );
    }
  }

  @override
  Future<void> deleteRingtone(String id) async {
    final Response<dynamic> response;
    try {
      response = await _dio.delete<dynamic>(
        ApiConstants.alarmRingtoneItemEndPoint(id),
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
        _extractError(json) ?? 'Request failed ($status).',
        statusCode: status,
      );
    }
  }

  Map<String, dynamic> _toRequestJson(AlarmEntry alarm) => {
    'time': formatPrayerTime(
      PrayerClockTime(hour: alarm.hour, minute: alarm.minute),
    ),
    'soundMode': alarm.vibrateAndRing
        ? 'vibrate_and_ring'
        : alarm.vibrate
        ? 'vibrate'
        : 'ring',
    'ringtoneId': alarm.ringtoneId,
    'ringtoneName': alarm.ringtoneName,
    'isEnabled': alarm.enabled,
    'label': alarm.label,
  };

  Map<String, String>? _authHeaders() {
    final token = _local.getToken();
    return token == null ? null : {'Authorization': 'Bearer $token'};
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
