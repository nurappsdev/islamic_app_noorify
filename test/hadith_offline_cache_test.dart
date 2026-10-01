import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tuhfatul_muslim/core/errors/exceptions.dart';
import 'package:tuhfatul_muslim/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:tuhfatul_muslim/features/hadith/data/datasources/hadith_library_remote_data_source.dart';
import 'package:tuhfatul_muslim/features/hadith/data/hadith_content_cache.dart';
import 'package:tuhfatul_muslim/features/hadith/data/hadith_database.dart';

import 'quran_content_test.dart' show Adapter;

class _SignedIn implements AuthLocalDataSource {
  @override
  String? getToken() => 'token';
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Map<String, Object?> _page(
  List<Map<String, Object?>> items, {
  int page = 1,
  int totalPage = 1,
}) => {
  'success': true,
  'data': items,
  'meta': {
    'page': page,
    'limit': items.length,
    'total': items.length * totalPage,
    'totalPage': totalPage,
  },
};

Map<String, Object?> _hadith(int n) => {
  '_id': 'h$n',
  'hadithNumber': n,
  'textArabic': 'نص $n',
  'textBangla': 'হাদিস $n',
};

/// Serves books, categories and paged hadiths (3 pages of 2).
Map<String, Object?> _serve(RequestOptions r) {
  switch (r.path) {
    case '/hadiths/books/lists':
      return _page([
        {'_id': 'b1', 'title': 'Riyad', 'displayOrder': 1},
      ]);
    case '/hadiths/categories':
      return _page([
        {'_id': 'c1', 'nameBangla': 'ঈমান', 'bookId': 'b1'},
      ]);
    case '/hadiths':
      final page = int.parse('${r.queryParameters['page']}');
      return _page(
        [_hadith(page * 2 - 1), _hadith(page * 2)],
        page: page,
        totalPage: 3,
      );
    case '/hadiths/reading/read':
      return _page([
        {'hadithId': 'h1', 'isRead': true},
      ]);
  }
  throw StateError('Unexpected ${r.path}');
}

/// A server that cannot be reached.
Adapter _offline() => Adapter(
  (r) => throw DioException(
    requestOptions: r,
    type: DioExceptionType.connectionError,
  ),
);

/// A fresh data source and cache: memory is empty, as after an app restart.
HadithLibraryRemoteDataSourceImpl _source(Adapter adapter) =>
    HadithLibraryRemoteDataSourceImpl(
      dio: Dio(BaseOptions(baseUrl: 'https://example.test/api/v1'))
        ..httpClientAdapter = adapter,
      local: _SignedIn(),
      cache: HadithContentCache(),
    );

Iterable<String> _paths(Adapter adapter) => adapter.requests.map(
  (r) =>
      '${r.path}${r.queryParameters['page'] == null ? '' : '#${r.queryParameters['page']}'}',
);

void main() {
  late Directory dir;
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    dir = await Directory.systemTemp.createTemp('hadith_cache_test');
    await databaseFactory.setDatabasesPath(dir.path);
  });
  setUp(() async {
    final db = await HadithDatabase().open();
    await db.delete('hadith_content_cache');
  });
  tearDownAll(() async {
    await (await HadithDatabase().open()).close();
    await dir.delete(recursive: true);
  });

  test('library content read once opens again without the API', () async {
    final first = Adapter(_serve);
    final source = _source(first);
    await source.getBooks();
    await source.getCategories('b1', page: 1, limit: 20);
    expect(_paths(first), contains('/hadiths/books/lists'));

    final again = Adapter(_serve);
    final restarted = _source(again);
    final books = await restarted.getBooks();
    final categories = await restarted.getCategories('b1', page: 1, limit: 20);
    expect(books.single.id, 'b1');
    expect(categories.categories, hasLength(1));
    expect(again.requests, isEmpty);
  });

  test('reading a scope stores its other hadith pages too', () async {
    final server = Adapter(_serve);
    final source = _source(server);
    final first = await source.getHadiths(
      subCategoryId: 's1',
      page: 1,
      limit: 2,
    );
    expect(first.hadiths, hasLength(2));
    // Pages 2 and 3 follow in the background.
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(_paths(server), ['/hadiths#1', '/hadiths#2', '/hadiths#3']);

    final offline = _offline();
    final later = _source(offline);
    final third = await later.getHadiths(
      subCategoryId: 's1',
      page: 3,
      limit: 2,
    );
    expect(third.hadiths.map((h) => h.id), ['h5', 'h6']);
    expect(offline.requests, isEmpty);
  });

  test(
    'offline: stored content loads, missing content reports offline',
    () async {
      await _source(Adapter(_serve)).getBooks();

      final source = _source(_offline());
      expect((await source.getBooks()).single.id, 'b1');
      await expectLater(
        source.getCategories('b1', page: 1, limit: 20),
        throwsA(isA<NetworkException>()),
      );
    },
  );

  test('user data and searches always come from the API', () async {
    final server = Adapter(_serve);
    final source = _source(server);
    await source.getReadHadiths(subCategoryId: 's1');
    await source.getReadHadiths(subCategoryId: 's1');
    await source.getCategories('b1', page: 1, limit: 20, searchTerm: 'ঈমান');
    await source.getCategories('b1', page: 1, limit: 20, searchTerm: 'ঈমান');
    expect(
      _paths(server).where((p) => p == '/hadiths/reading/read'),
      hasLength(2),
    );
    expect(
      server.requests.where((r) => r.queryParameters['searchTerm'] != null),
      hasLength(2),
    );
  });

  test(
    'day-old content shows at once and refreshes in the background',
    () async {
      await _source(Adapter(_serve)).getBooks();
      final db = await HadithDatabase().open();
      await db.update('hadith_content_cache', {'cached_at': 0});

      final server = Adapter(_serve);
      final books = await _source(server).getBooks();
      expect(books.single.id, 'b1');
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(_paths(server), ['/hadiths/books/lists']);
      final rows = await db.query(
        'hadith_content_cache',
        columns: ['cached_at'],
      );
      expect(rows.single['cached_at'], greaterThan(0));
    },
  );

  test('content stored under an older version is dropped', () async {
    await _source(Adapter(_serve)).getBooks();
    final db = await HadithDatabase().open();
    await db.update('hadith_content_cache', {
      'content_version': HadithContentCache.contentVersion - 1,
    });

    final server = Adapter(_serve);
    await _source(server).getBooks();
    expect(_paths(server), ['/hadiths/books/lists']);
  });
}
