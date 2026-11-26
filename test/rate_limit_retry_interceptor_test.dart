import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuhfatul_muslim/core/network/rate_limit_retry_interceptor.dart';
import 'package:tuhfatul_muslim/features/dua/data/datasources/dua_remote_data_source.dart';

/// Answers `429` for the first [rateLimited] calls, then `200`, recording
/// every request so a test can count the replays.
class _RateLimitedAdapter implements HttpClientAdapter {
  _RateLimitedAdapter({this.rateLimited = 1, this.resetHeader = '1'});

  final int rateLimited;

  /// The `RateLimit-Reset` the 429 carries; `null` sends no delay header.
  final String? resetHeader;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (requests.length <= rateLimited) {
      return ResponseBody.fromString(
        jsonEncode({'success': false, 'message': 'Too many requests'}),
        429,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
          if (resetHeader != null) 'ratelimit-reset': [resetHeader!],
        },
      );
    }
    return ResponseBody.fromString(
      jsonEncode({'success': true, 'data': []}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio _client(
  _RateLimitedAdapter adapter, {
  int maxRetries = 2,
  Duration maxDelay = const Duration(seconds: 5),
}) {
  final dio = Dio(
    BaseOptions(validateStatus: (status) => status != null && status < 500),
  )..httpClientAdapter = adapter;
  return dio
    ..interceptors.add(
      RateLimitRetryInterceptor(
        dio: dio,
        maxRetries: maxRetries,
        maxDelay: maxDelay,
        // Keeps the test fast; the real client waits out the named second.
        fallbackDelay: Duration.zero,
      ),
    );
}

void main() {
  test(
    'waits out a 429 and replays the GET, so the caller sees the 200',
    () async {
      final adapter = _RateLimitedAdapter();
      final response = await _client(adapter).get<dynamic>('/duas/categories');

      expect(response.statusCode, 200);
      expect(adapter.requests, hasLength(2));
    },
  );

  test('gives up after maxRetries and returns the 429 to the caller', () async {
    final adapter = _RateLimitedAdapter(rateLimited: 10);
    final response = await _client(
      adapter,
      maxRetries: 2,
    ).get<dynamic>('/duas/categories');

    expect(response.statusCode, 429);
    // The first attempt plus two retries.
    expect(adapter.requests, hasLength(3));
  });

  test(
    'does not replay when the server names a delay beyond maxDelay',
    () async {
      // The 15-minute budget is spent: blocking the screen on it is worse than
      // letting the caller fail.
      final adapter = _RateLimitedAdapter(rateLimited: 10, resetHeader: '900');
      final response = await _client(
        adapter,
        maxDelay: const Duration(seconds: 5),
      ).get<dynamic>('/duas/categories');

      expect(response.statusCode, 429);
      expect(adapter.requests, hasLength(1));
    },
  );

  test('retries a 429 that carries no delay header at all', () async {
    final adapter = _RateLimitedAdapter(resetHeader: null);
    final response = await _client(adapter).get<dynamic>('/duas/categories');

    expect(response.statusCode, 200);
    expect(adapter.requests, hasLength(2));
  });

  test(
    'never replays a POST, which the server may already have counted',
    () async {
      final adapter = _RateLimitedAdapter(rateLimited: 10);
      final response = await _client(
        adapter,
      ).post<dynamic>('/duas/reading/track', data: {'duaId': 'dua-1'});

      expect(response.statusCode, 429);
      expect(adapter.requests, hasLength(1));
    },
  );

  test('the dua client carries the rate-limit retry', () {
    final interceptors = DuaRemoteDataSourceImpl().client.interceptors;
    expect(interceptors.whereType<RateLimitRetryInterceptor>(), hasLength(1));
  });
}
