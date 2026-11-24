import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tuhfatul_muslim/core/errors/exceptions.dart';
import 'package:tuhfatul_muslim/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:tuhfatul_muslim/features/hadith/data/datasources/hadith_library_remote_data_source.dart';
import 'package:tuhfatul_muslim/core/services/api_constants.dart';
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
    case '/ebooks':
      return _page([
        {'_id': 'e1', 'titleEnglish': 'Advice for the Muslim'},
      ]);
    case '/hadiths/reading/read':
      return _page([
        {'hadithId': 'h1', 'isRead': true},
      ]);
  }
  throw StateError('Unexpected ${r.path}');
}

/// The same server after a second book was added in the dashboard.
Map<String, Object?> _serveTwoBooks(RequestOptions r) {
  if (r.path != '/hadiths/books/lists') return _serve(r);
  return _page([
    {'_id': 'b1', 'title': 'Riyad', 'displayOrder': 1},
    {'_id': 'b2', 'title': 'Forty Hadith', 'displayOrder': 2},
  ]);
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

  // The window is short, so a chapter read earlier today does not keep
  // showing the hadiths it had then: the copy is checked against the API on
  // the next visit. Without this, a chapter that grew from 2 hadiths to 10
  // still showed 2 for a whole day.
  test('a copy past the window is refreshed before it is shown', () async {
    await _source(Adapter(_serve)).getBooks();
    final db = await HadithDatabase().open();
    await db.update('hadith_content_cache', {
      'cached_at': DateTime.now()
          .subtract(HadithContentCache.refreshAfter * 2)
          .millisecondsSinceEpoch,
    });

    final server = Adapter(_serveTwoBooks);
    expect((await _source(server).getBooks()).map((b) => b.id), ['b1', 'b2']);
    expect(_paths(server), ['/hadiths/books/lists']);
  });

  // ...while a copy inside the window still opens without the network, so
  // moving back and forth between screens stays instant.
  test('a copy inside the window answers without the API', () async {
    await _source(Adapter(_serve)).getCategories('b1', page: 1, limit: 20);

    final server = Adapter(_serve);
    await _source(server).getCategories('b1', page: 1, limit: 20);
    expect(server.requests, isEmpty);
  });

  // Day-old content is checked against the API *before* it is shown: a copy
  // served first and refreshed afterwards would hide content added on the
  // server until the screen was opened a second time.
  test('day-old content is refreshed before it is shown', () async {
    await _source(Adapter(_serve)).getBooks();
    final db = await HadithDatabase().open();
    await db.update('hadith_content_cache', {'cached_at': 0});

    final server = Adapter(_serveTwoBooks);
    final books = await _source(server).getBooks();
    expect(books.map((b) => b.id), ['b1', 'b2']);
    expect(_paths(server), ['/hadiths/books/lists']);
    final rows = await db.query('hadith_content_cache', columns: ['cached_at']);
    expect(rows.single['cached_at'], greaterThan(0));
  });

  // ...but offline reading survives: when that check cannot be made, the
  // stored copy still answers.
  test('day-old content falls back to the stored copy when offline', () async {
    await _source(Adapter(_serve)).getBooks();
    await (await HadithDatabase().open()).update('hadith_content_cache', {
      'cached_at': 0,
    });

    final offline = _offline();
    final books = await _source(offline).getBooks();
    expect(books.single.id, 'b1');
    expect(offline.requests, hasLength(1));
  });

  // Content deleted in the dashboard must not keep opening from the device:
  // the stored copy is dropped as soon as the API answers that the request
  // has nothing left, so not even an offline open brings it back.
  test('a list the API empties is forgotten, not kept', () async {
    await _source(Adapter(_serve)).getEbooks();
    // Past the window, so the next open asks the API: what the e-book shelf
    // does a couple of minutes after an admin deletes the last e-book.
    await (await HadithDatabase().open()).update('hadith_content_cache', {
      'cached_at': DateTime.now()
          .subtract(HadithContentCache.refreshAfter * 2)
          .millisecondsSinceEpoch,
    });

    final emptied = Adapter((r) => _page(const []));
    expect(await _source(emptied).getEbooks(), isEmpty);
    expect(emptied.requests, hasLength(1));

    // Nothing is left to answer from, online or off.
    final offline = _offline();
    await expectLater(
      _source(offline).getEbooks(),
      throwsA(isA<NetworkException>()),
    );
  });

  // An unknown query parameter is not a way past the API's own cache: the
  // e-book endpoint passes parameters it does not know into its database
  // filter, so a request carrying one came back with an empty shelf — and an
  // empty answer now drops the stored copy, which would clear the shelf on
  // the device too. A refresh sends the same query as a plain open.
  test('a forced refresh sends no extra query parameters', () async {
    final server = Adapter(_serve);
    final source = _source(server);
    await source.getEbooks();
    await source.getEbooks(forceRefresh: true);

    expect(server.requests, hasLength(2));
    expect(
      server.requests.last.queryParameters,
      server.requests.first.queryParameters,
    );
  });

  // The reported bug: a book opened before its categories were added stored
  // `data: []`, and for a day the screen answered "no results" from the
  // device without a single request reaching the API.
  test('an empty page is never stored', () async {
    final empty = Adapter((r) => _page(const []));
    final before = await _source(empty).getCategories('b2', page: 1, limit: 20);
    expect(before.categories, isEmpty);

    final server = Adapter(_serve);
    final after = await _source(server).getCategories('b2', page: 1, limit: 20);
    expect(after.categories, hasLength(1));
    expect(_paths(server), ['/hadiths/categories#1']);
  });

  // The category, chapter and hadith lists refresh like the shelf does.
  test('a forced refresh of categories goes to the API', () async {
    await _source(Adapter(_serve)).getCategories('b1', page: 1, limit: 20);

    final cached = Adapter(_serve);
    await _source(cached).getCategories('b1', page: 1, limit: 20);
    expect(cached.requests, isEmpty);

    final server = Adapter(_serve);
    await _source(
      server,
    ).getCategories('b1', page: 1, limit: 20, forceRefresh: true);
    expect(_paths(server), ['/hadiths/categories#1']);
  });

  test('a forced refresh of a hadith page goes to the API', () async {
    await _source(
      Adapter(_serve),
    ).getHadiths(subCategoryId: 's9', page: 1, limit: 2);

    final server = Adapter(_serve);
    await _source(
      server,
    ).getHadiths(subCategoryId: 's9', page: 1, limit: 2, forceRefresh: true);
    expect(_paths(server).first, '/hadiths#1');
  });

  // A book added on the server has to be reachable from the app: the shelf
  // caches its list, so a pull-to-refresh asks the API again instead of
  // redrawing the stored copy.
  test('a forced refresh goes to the API and stores what it finds', () async {
    await _source(Adapter(_serve)).getBooks();

    Map<String, Object?> serveTwo(RequestOptions r) {
      if (r.path != '/hadiths/books/lists') return _serve(r);
      return _page([
        {'_id': 'b1', 'title': 'Riyad', 'displayOrder': 1},
        {'_id': 'b2', 'title': 'Forty Hadith', 'displayOrder': 2},
      ]);
    }

    final server = Adapter(serveTwo);
    final refreshed = await _source(server).getBooks(forceRefresh: true);
    expect(refreshed.map((b) => b.id), ['b1', 'b2']);
    expect(_paths(server), ['/hadiths/books/lists']);

    // The new book is now the stored copy, so the next open shows it offline.
    final offline = _offline();
    expect((await _source(offline).getBooks()).map((b) => b.id), ['b1', 'b2']);
    expect(offline.requests, isEmpty);
  });

  // Each environment keeps its own content: a build pointed at another host
  // must not answer from the previous host's copy.
  test('the stored key is scoped to the API host', () {
    final key = HadithContentCache.keyOf('/hadiths/books/lists', {
      'limit': 100,
    });
    expect(key, startsWith(ApiConstants.baseUrl));
    expect(key, endsWith('/hadiths/books/lists?limit=100'));
  });

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
