import 'package:dio/dio.dart';

import 'package:islami_app_noorify/core/errors/exceptions.dart';
import 'package:islami_app_noorify/core/network/dio_client.dart';
import 'package:islami_app_noorify/core/services/api_constants.dart';
import 'package:islami_app_noorify/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:islami_app_noorify/features/quran/domain/quran_last_read.dart';
import 'package:islami_app_noorify/features/quran/domain/quran_reading_dashboard.dart';
import 'package:islami_app_noorify/features/quran/domain/quran_reading_history.dart';
import 'package:islami_app_noorify/features/quran/domain/quran_reading_progress.dart';

/// The signed-in user's Quran reading endpoints (`/quran/reading/...`). Every
/// call sends the stored login token; an expired one is renewed by the shared
/// client's `AuthRefreshInterceptor`. Throws [ServerException] /
/// [NetworkException] / [ParsingException]; never returns error states.
abstract interface class QuranReadingRemoteDataSource {
  /// `POST /quran/reading/track`: [seconds] spent reading ayahs
  /// [fromAyah]-[toAyah] of [surahNumber] on the local calendar day [date]
  /// (`YYYY-MM-DD`).
  Future<QuranReadingTrackResult> trackReading({
    required int surahNumber,
    required int fromAyah,
    required int toAyah,
    required int seconds,
    required String date,
  });

  /// `GET /quran/reading/dashboard`.
  Future<QuranReadingDashboard> getDashboard();

  /// `GET /quran/reading/history`: the last [days] days, or the [from]-[to]
  /// window (`YYYY-MM-DD`) when given.
  Future<QuranReadingHistory> getHistory({
    required int days,
    String? from,
    String? to,
  });

  /// `GET /quran/reading/history/compare`, over the same window as
  /// [getHistory].
  Future<QuranReadingComparison> getComparison({
    required int days,
    String? from,
    String? to,
  });

  /// `GET /quran/reading/last-read`.
  Future<QuranLastRead> getLastRead();
}

class QuranReadingRemoteDataSourceImpl implements QuranReadingRemoteDataSource {
  QuranReadingRemoteDataSourceImpl({Dio? dio, AuthLocalDataSource? local})
    : _dioOverride = dio,
      _localOverride = local;

  final Dio? _dioOverride;
  final AuthLocalDataSource? _localOverride;

  // Resolved on first use: the app-wide instance is created before Hive (the
  // token's storage) is guaranteed open.
  late final Dio _dio = _dioOverride ?? DioClient().dio;
  late final AuthLocalDataSource _local =
      _localOverride ?? AuthLocalDataSourceImpl();

  @override
  Future<QuranReadingTrackResult> trackReading({
    required int surahNumber,
    required int fromAyah,
    required int toAyah,
    required int seconds,
    required String date,
  }) async => QuranReadingTrackResult.fromJson(
    await _send(
      'POST',
      ApiConstants.quranReadingTrackEndPoint,
      body: {
        'surahNumber': surahNumber,
        'fromAyah': fromAyah,
        'toAyah': toAyah,
        'seconds': seconds,
        'date': date,
      },
      what: 'Quran reading track',
    ),
  );

  @override
  Future<QuranReadingDashboard> getDashboard() async =>
      QuranReadingDashboard.fromJson(
        await _send(
          'GET',
          ApiConstants.quranReadingDashboardEndPoint,
          what: 'Quran reading dashboard',
        ),
      );

  @override
  Future<QuranReadingHistory> getHistory({
    required int days,
    String? from,
    String? to,
  }) async => QuranReadingHistory.fromJson(
    await _send(
      'GET',
      ApiConstants.quranReadingHistoryEndPoint,
      query: _window(days, from, to),
      what: 'Quran reading history',
    ),
  );

  @override
  Future<QuranReadingComparison> getComparison({
    required int days,
    String? from,
    String? to,
  }) async => QuranReadingComparison.fromJson(
    await _send(
      'GET',
      ApiConstants.quranReadingCompareEndPoint,
      query: _window(days, from, to),
      what: 'Quran reading comparison',
    ),
  );

  @override
  Future<QuranLastRead> getLastRead() async => QuranLastRead.fromJson(
    await _send(
      'GET',
      ApiConstants.quranLastReadEndPoint,
      what: 'Quran last read',
    ),
  );

  static Map<String, Object> _window(int days, String? from, String? to) => {
    'days': days,
    'from': ?from,
    'to': ?to,
  };

  /// Sends one authenticated request and returns the envelope's `data`
  /// object, throwing the data-layer exceptions on any failure.
  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, Object>? query,
    Map<String, Object>? body,
    required String what,
  }) async {
    final token = _local.getToken();
    final Response<dynamic> response;
    try {
      response = await _dio.request<dynamic>(
        path,
        data: body,
        queryParameters: query,
        options: Options(
          method: method,
          headers: token == null ? null : {'Authorization': 'Bearer $token'},
        ),
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }

    final raw = response.data;
    final json = raw is Map<String, dynamic> ? raw : const <String, dynamic>{};
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
      throw ParsingException('$what response is missing "data".');
    }
    return data;
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
          .whereType<Map<String, dynamic>>()
          .map((e) => e['message'])
          .whereType<String>()
          .where((m) => m.isNotEmpty)
          .join('\n');
      if (messages.isNotEmpty) return messages;
    }
    final message = json['message'];
    return message is String && message.isNotEmpty ? message : null;
  }
}
