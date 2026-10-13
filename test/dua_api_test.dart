import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuhfatul_muslim/features/dua/data/datasources/dua_remote_data_source.dart';

class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.body);

  final Object body;
  RequestOptions? request;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test(
    'loads a category page with the supplied pagination parameters',
    () async {
      final adapter = _StubAdapter({
        'success': true,
        'data': [
          {
            '_id': 'dua-1',
            'categoryId': 'category-1',
            'title': {
              'bn': 'সকালে উপনীত হওয়ার দোয়া',
              'en': 'Dua on entering the morning',
            },
            'arabic': 'اللَّهُمَّ بِكَ أَصْبَحْنَا',
            'transliteration': {'bn': 'আল্লা-হুম্মা', 'en': 'Allahumma'},
            'translation': {'bn': 'হে আল্লাহ', 'en': 'O Allah'},
            'recommendedRepeatCount': 1,
          },
        ],
        'meta': {'page': 1, 'limit': 20, 'total': 6, 'totalPage': 1},
      });
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1'))
        ..httpClientAdapter = adapter;
      final source = DuaRemoteDataSourceImpl(dio: dio);

      final result = await source.getByCategory('category-1');

      expect(adapter.request?.method, 'GET');
      expect(adapter.request?.uri.path, '/api/v1/duas');
      expect(adapter.request?.uri.queryParameters, {
        'categoryId': 'category-1',
        'page': '1',
        'limit': '20',
      });
      expect(result.total, 6);
      expect(result.totalPage, 1);
      expect(result.items.single.title.bn, 'সকালে উপনীত হওয়ার দোয়া');
    },
  );
}
