import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;

import 'package:tuhfatul_muslim/core/errors/exceptions.dart';
import 'package:tuhfatul_muslim/core/network/dio_client.dart';
import 'package:tuhfatul_muslim/core/services/api_constants.dart';
import 'package:tuhfatul_muslim/core/storage/latest_json_cache.dart';
import 'package:tuhfatul_muslim/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:tuhfatul_muslim/features/leaderboard/data/models/leaderboard_board_model.dart';
import 'package:tuhfatul_muslim/features/leaderboard/data/models/leaderboard_user_detail_model.dart';

/// Talks to the leaderboard REST endpoint. Throws [ServerException] /
/// [NetworkException] / [ParsingException]; never returns error states.
abstract interface class LeaderboardRemoteDataSource {
  /// `GET /leaderboard/top?period=daily|weekly|monthly|yearly&limit=N`.
  ///
  /// [from] and [to] (`YYYY-MM-DD`, [from] the earlier day) ask the server for
  /// an explicit window instead of the one it derives from [period] itself.
  /// Left out, the server picks the window - for `weekly` that is the calendar
  /// week containing today, which is not what the app wants; see
  /// `docs/leaderboard-weekly-window-handoff.md`.
  Future<LeaderboardBoardModel> getTop({
    required String period,
    required int limit,
    String? from,
    String? to,
  });

  /// `GET /leaderboard/users/:userId?period=...&date=...`. [date] is the
  /// period's `key` from a leaderboard response (`2026-09`); omitted, the
  /// server uses the current period.
  Future<LeaderboardUserDetailModel> getUserPosition({
    required String userId,
    required String period,
    String? date,
  });
}

class LeaderboardRemoteDataSourceImpl implements LeaderboardRemoteDataSource {
  LeaderboardRemoteDataSourceImpl({Dio? dio, AuthLocalDataSource? local})
    : _dio = dio ?? DioClient().dio,
      _local = local ?? AuthLocalDataSourceImpl();

  final Dio _dio;
  final AuthLocalDataSource _local;

  /// The latest successfully-fetched payload per leaderboard query, read back
  /// by [LeaderboardRepositoryImpl] when a later request fails. Keyed per
  /// period/user so an offline "daily" view never shows a cached "monthly"
  /// board (or someone else's cached standing).
  static LatestJsonCache cacheFor(String key) =>
      LatestJsonCache('leaderboard_$key');

  @override
  Future<LeaderboardBoardModel> getTop({
    required String period,
    required int limit,
    String? from,
    String? to,
  }) async {
    final query = <String, dynamic>{
      'period': period,
      'limit': limit,
      if (from != null && from.isNotEmpty) 'from': from,
      if (to != null && to.isNotEmpty) 'to': to,
    };
    final data = await _getData(
      ApiConstants.leaderboardTopEndPoint,
      query,
      cacheKey: 'top_$period',
    );
    _logWindow(ApiConstants.leaderboardTopEndPoint, query, data);
    return LeaderboardBoardModel.fromJson(data);
  }

  @override
  Future<LeaderboardUserDetailModel> getUserPosition({
    required String userId,
    required String period,
    String? date,
  }) async {
    final path = ApiConstants.leaderboardUserEndPoint(userId);
    final query = <String, dynamic>{
      'period': period,
      if (date != null && date.isNotEmpty) 'date': date,
    };
    final data = await _getData(
      path,
      query,
      cacheKey: 'user_${userId}_$period',
    );
    _logWindow(path, query, data);
    return LeaderboardUserDetailModel.fromJson(data);
  }

  /// Debug builds only: prints the parameters a leaderboard call was made
  /// with and the date window the server resolved them to, so a filter's
  /// range can be read straight off the console.
  ///
  /// The window is the server's own - the app sends nothing but `period` -
  /// and a `weekly` window that runs past today is the open backend defect in
  /// `docs/leaderboard-weekly-window-handoff.md`, which is why a future `to`
  /// is called out here.
  void _logWindow(
    String path,
    Map<String, dynamic> query,
    Map<String, dynamic> data,
  ) {
    if (!kDebugMode) return;
    final raw = data['period'];
    final window = raw is Map ? raw : const <dynamic, dynamic>{};
    final from = DateTime.tryParse(window['from']?.toString() ?? '');
    final to = DateTime.tryParse(window['to']?.toString() ?? '');

    final span = (from == null || to == null)
        ? 'from=${window['from']} to=${window['to']}'
        : '${_day(from)} ... ${_day(to)} '
              '(${to.difference(from).inDays + 1} days)';

    debugPrint(
      '[leaderboard] $path params: $query\n'
      '  window: $span  type=${window['type']} key=${window['key']}\n'
      '  label: ${window['label']}',
    );

    // Compared against the device's own civil date, the same clock the rest
    // of the app reads days from.
    final today = DateTime.now();
    final endsAhead = to == null
        ? 0
        : DateTime(
            to.year,
            to.month,
            to.day,
          ).difference(DateTime(today.year, today.month, today.day)).inDays;
    if (endsAhead > 0) {
      debugPrint(
        '[leaderboard] !! window ends $endsAhead day(s) in the future: '
        'those days cannot hold any points yet. '
        'See docs/leaderboard-weekly-window-handoff.md',
      );
    }

    // Asked for a window and got a different one back: the server does not
    // honour these parameters, so only it can fix the range.
    final asked = (
      from: query['from']?.toString(),
      to: query['to']?.toString(),
    );
    if (asked.from != null && asked.to != null) {
      final got = (
        from: window['from']?.toString(),
        to: window['to']?.toString(),
      );
      if (got.from != asked.from || got.to != asked.to) {
        debugPrint(
          '[leaderboard] !! asked for ${asked.from} ... ${asked.to} but the '
          'server answered ${got.from} ... ${got.to}: it ignores from/to. '
          'See docs/leaderboard-weekly-window-handoff.md',
        );
      }
    }
  }

  static String _day(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// GETs [path] and returns the envelope's `data` object, caching it under
  /// [cacheKey] for [LeaderboardRepositoryImpl]'s offline fallback.
  Future<Map<String, dynamic>> _getData(
    String path,
    Map<String, dynamic> query, {
    required String cacheKey,
  }) async {
    final Response<dynamic> response;
    try {
      response = await _dio.get<dynamic>(
        path,
        queryParameters: query,
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
      throw ParsingException('Leaderboard response is missing "data".');
    }
    unawaited(cacheFor(cacheKey).save(data));
    return data;
  }

  Map<String, String>? _authHeaders() {
    final token = _local.getToken();
    return token == null ? null : {'Authorization': 'Bearer $token'};
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
