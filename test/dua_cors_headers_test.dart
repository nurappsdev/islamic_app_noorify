import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuhfatul_muslim/features/dua/data/datasources/dua_remote_data_source.dart';

/// Captures the request the data source actually sends.
class _CapturingAdapter implements HttpClientAdapter {
  RequestOptions? request;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
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

/// The headers the API lists in `Access-Control-Allow-Headers`, plus the
/// CORS-safelisted ones the browser never needs permission for. Anything a
/// request carries beyond this set is blocked by the browser before it is
/// sent - which is what broke every dua call on Web.
const _browserPermitted = {
  // Access-Control-Allow-Headers, as the server sends it.
  'content-type',
  'authorization',
  'x-api-key',
  'x-requested-with',
  'accept',
  'origin',
  // CORS-safelisted request headers.
  'accept-language',
  'content-language',
  'range',
};

void main() {
  late _CapturingAdapter adapter;
  late DuaRemoteDataSourceImpl source;

  setUp(() {
    adapter = _CapturingAdapter();
    source = DuaRemoteDataSourceImpl();
    source.client.httpClientAdapter = adapter;
  });

  test('sends no header the browser would block the dua call over', () async {
    await source.getCategories();

    final sent = adapter.request!.headers.keys
        .map((k) => k.toLowerCase())
        .toSet();
    final blocked = sent.difference(_browserPermitted);

    if (kIsWeb) {
      expect(
        blocked,
        isEmpty,
        reason:
            'On Web these headers are not in the API\'s '
            'Access-Control-Allow-Headers, so Chrome blocks the request '
            'with a bare "XMLHttpRequest onError" and no status: $blocked',
      );
    } else {
      // Native has no CORS; the timezone hint is still sent there.
      expect(blocked, contains('x-timezone'));
    }
  });

  test('X-Timezone is sent on native and withheld on Web', () async {
    await source.getFeatured();

    final headers = {
      for (final e in adapter.request!.headers.entries)
        e.key.toLowerCase(): e.value,
    };
    expect(headers.containsKey('x-timezone'), isNot(kIsWeb));
  });

  test('the request still carries the headers the API needs', () async {
    await source.getCategories();

    final headers = {
      for (final e in adapter.request!.headers.entries)
        e.key.toLowerCase(): e.value,
    };
    // The API key and language must survive the Web guard.
    expect(headers['x-api-key'], isNotNull);
    expect(headers['accept-language'], isNotNull);
  });
}
