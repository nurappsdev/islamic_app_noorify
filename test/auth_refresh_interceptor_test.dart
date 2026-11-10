import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tuhfatul_muslim/core/network/auth_refresh_interceptor.dart';
import 'package:tuhfatul_muslim/features/auth/data/datasources/auth_local_data_source.dart';

/// Fake server: `/user/family` accepts only `Bearer new-access`; the refresh
/// endpoint swaps the `old-refresh` cookie for `new-access`.
class _Adapter implements HttpClientAdapter {
  int familyCalls = 0;
  int refreshCalls = 0;
  bool refreshRejected = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    ResponseBody json(int status, Map<String, dynamic> body) =>
        ResponseBody.fromString(
          jsonEncode(body),
          status,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );

    if (options.path == '/auth/refresh-token') {
      refreshCalls++;
      if (refreshRejected) return json(401, {'success': false});
      expect(options.headers['Cookie'], 'refreshToken=old-refresh');
      return ResponseBody.fromString(
        jsonEncode({
          'success': true,
          'data': {'accessToken': 'new-access'},
        }),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
          'set-cookie': ['refreshToken=rotated-refresh; Path=/; HttpOnly'],
        },
      );
    }

    familyCalls++;
    final ok = options.headers['Authorization'] == 'Bearer new-access';
    return json(ok ? 200 : 401, {'success': ok});
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Directory tmp;
  late AuthLocalDataSourceImpl local;
  late _Adapter adapter;
  late Dio dio;

  setUp(() async {
    tmp = Directory.systemTemp.createTempSync('refresh_test');
    Hive.init(tmp.path);
    final box = await Hive.openBox<dynamic>(
      't${DateTime.now().microsecondsSinceEpoch}',
    );
    local = AuthLocalDataSourceImpl(box: box);
    await local.cacheToken('expired-access');
    await local.cacheRefreshToken('old-refresh');

    adapter = _Adapter();
    dio = Dio(
      BaseOptions(
        baseUrl: 'https://example.test',
        validateStatus: (s) => s != null && s < 500,
      ),
    )..httpClientAdapter = adapter;
    dio.interceptors.add(
      AuthRefreshInterceptor(dio: dio, local: local, refreshDio: dio),
    );
    AuthRefreshInterceptor.onSessionExpired = null;
  });

  tearDown(() async {
    await Hive.close();
    tmp.deleteSync(recursive: true);
  });

  Future<Response<dynamic>> family() => dio.get<dynamic>(
    '/user/family',
    options: Options(headers: {'Authorization': 'Bearer ${local.getToken()}'}),
  );

  test('401 refreshes the token and retries the request', () async {
    final response = await family();

    expect(response.statusCode, 200);
    expect(local.getToken(), 'new-access');
    expect(local.getRefreshToken(), 'rotated-refresh');
    expect(adapter.familyCalls, 2);
    expect(adapter.refreshCalls, 1);
  });

  test('concurrent 401s share a single refresh', () async {
    final responses = await Future.wait([family(), family(), family()]);

    expect(responses.map((r) => r.statusCode), everyElement(200));
    expect(adapter.refreshCalls, 1);
  });

  test('a rejected refresh token ends the session', () async {
    adapter.refreshRejected = true;
    var expired = false;
    AuthRefreshInterceptor.onSessionExpired = () async => expired = true;

    final response = await family();

    expect(response.statusCode, 401);
    expect(expired, isTrue);
    expect(local.getToken(), isNull);
    expect(local.getRefreshToken(), isNull);
  });
}
