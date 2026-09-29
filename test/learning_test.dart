import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/core/storage/hive_service.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:tuhfatul_muslim/features/learning/data/datasources/learning_remote_data_source.dart';
import 'package:tuhfatul_muslim/features/learning/data/repositories/learning_repository_impl.dart';
import 'package:tuhfatul_muslim/features/learning/domain/entities/article.dart';
import 'package:tuhfatul_muslim/features/learning/domain/repositories/learning_repository.dart';
import 'package:tuhfatul_muslim/features/learning/domain/usecases/get_article.dart';
import 'package:tuhfatul_muslim/features/learning/domain/usecases/get_article_categories.dart';
import 'package:tuhfatul_muslim/features/learning/domain/usecases/get_articles.dart';
import 'package:tuhfatul_muslim/features/learning/presentation/bloc/article_categories_bloc.dart';
import 'package:tuhfatul_muslim/features/learning/presentation/bloc/article_detail_bloc.dart';
import 'package:tuhfatul_muslim/features/learning/presentation/bloc/articles_bloc.dart';
import 'package:tuhfatul_muslim/features/learning/presentation/learning_failure_message.dart';
import 'package:tuhfatul_muslim/features/learning/presentation/screens/article_details_screen.dart';
import 'package:tuhfatul_muslim/features/learning/presentation/screens/articles_screen.dart';
import 'package:tuhfatul_muslim/features/learning/presentation/screens/learning_screen.dart';
import 'package:tuhfatul_muslim/features/learning/presentation/widgets/learning_widgets.dart';
import 'package:tuhfatul_muslim/features/quiz/domain/entities/quiz_dashboard.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';

// ---------------------------------------------------------------- HTTP stubs

/// Answers each request by `"METHOD /path"`, and remembers the requests.
class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.routes);

  final Map<String, (int, Object)> routes;
  final requests = <RequestOptions>[];

  RequestOptions get last => requests.last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final key = '${options.method} ${options.uri.path.split('/api/v1').last}';
    final (status, body) =
        routes[key] ?? (404, {'success': false, 'message': 'Not found'});
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _FakeLocal implements AuthLocalDataSource {
  @override
  String? getToken() => 'tkn';

  @override
  bool get hasToken => true;

  @override
  Future<void> cacheToken(String token) async {}

  @override
  Future<void> clearToken() async {}
}

({LearningRemoteDataSourceImpl source, _StubAdapter http}) _setup(
  Map<String, (int, Object)> routes,
) {
  final http = _StubAdapter(routes);
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://example.test/api/v1',
      validateStatus: (s) => s != null && s < 500,
    ),
  )..httpClientAdapter = http;
  return (
    source: LearningRemoteDataSourceImpl(dio: dio, local: _FakeLocal()),
    http: http,
  );
}

Map<String, Object> _ok(Object data, {Object? meta}) => {
  'statusCode': 200,
  'success': true,
  'message': 'ok',
  'data': data,
  'meta': ?meta,
};

Map<String, Object?> _categoryJson(
  String id, {
  int order = 1,
  bool active = true,
}) => {
  '_id': id,
  'name': {'bn': 'বিভাগ $id', 'en': 'Category $id'},
  'description': {'bn': 'বিবরণ', 'en': 'About $id'},
  'displayOrder': order,
  'isActive': active,
  'totalArticles': 3,
};

Map<String, Object?> _articleJson(
  String id, {
  String status = 'published',
  Object? content,
}) => {
  '_id': id,
  'categoryId': {
    '_id': 'cat1',
    'name': {'bn': 'কুরআন ও ওহি', 'en': 'Quran & Revelation'},
    'isActive': true,
  },
  'title': {'bn': 'শিরোনাম $id', 'en': 'Title $id'},
  'excerpt': {'bn': 'সারাংশ $id', 'en': 'Excerpt $id'},
  'content': ?content,
  'author': 'Research Team',
  'coverImageUrl': 'https://cdn.example.test/$id.jpg',
  'status': status,
  'publishedAt': '2026-09-27T05:12:12.815Z',
  'createdAt': '2026-09-27T05:12:12.818Z',
  'updatedAt': '2026-09-27T05:12:12.818Z',
};

// ------------------------------------------------------------ domain fakes

const _category = ArticleCategory(
  id: 'cat1',
  name: LocalizedText(bn: 'কুরআন ও ওহি', en: 'Quran & Revelation'),
  description: LocalizedText(bn: 'ওহির ইতিহাস', en: 'Revelation history'),
  displayOrder: 1,
  isActive: true,
  totalArticles: 12,
);

Article _article(String id, {LocalizedText content = LocalizedText.empty}) =>
    Article(
      id: id,
      categoryId: 'cat1',
      categoryName: _category.name,
      title: LocalizedText(bn: 'শিরোনাম $id', en: 'Title $id'),
      excerpt: LocalizedText(bn: 'সারাংশ $id', en: 'Excerpt $id'),
      content: content,
      author: 'Research Team',
      coverImageUrl: null,
      status: 'published',
      publishedAt: DateTime.utc(2026, 9, 27, 5),
      createdAt: null,
      updatedAt: null,
    );

PaginationMeta _meta(int page, int totalPage, {int limit = 2}) =>
    PaginationMeta(
      page: page,
      limit: limit,
      total: totalPage * limit,
      totalPage: totalPage,
    );

/// Pages of [pageSize] from [total] numbered articles; a search keeps the
/// ones whose title contains it.
class _FakeLearning implements LearningRepository {
  _FakeLearning({this.total = 5});

  final int total;

  /// Articles per page, whatever the caller asks for.
  static const pageSize = 2;
  final calls = <String>[];
  Failure? articleFailure;
  Failure? listFailure;

  @override
  Future<Either<Failure, ArticleCategoryPage>> getArticleCategories({
    int page = 1,
    int limit = 10,
  }) async {
    calls.add('categories p$page');
    return Right(
      ArticleCategoryPage(
        categories: [
          ArticleCategory(
            id: 'c$page',
            name: LocalizedText(bn: 'বিভাগ $page', en: 'Category $page'),
            description: LocalizedText.empty,
            displayOrder: page,
            isActive: true,
            totalArticles: page,
          ),
        ],
        meta: _meta(page, 2, limit: limit),
      ),
    );
  }

  Either<Failure, ArticlePage> _page(int page, String? searchTerm) {
    final failure = listFailure;
    if (failure != null) return Left(failure);
    final all = [
      for (var i = 1; i <= total; i++) _article('a$i'),
    ].where((a) => searchTerm == null || a.title.en!.contains(searchTerm));
    final matching = all.toList();
    final totalPage = (matching.length / pageSize).ceil();
    return Right(
      ArticlePage(
        articles: matching.skip((page - 1) * pageSize).take(pageSize).toList(),
        meta: PaginationMeta(
          page: page,
          limit: pageSize,
          total: matching.length,
          totalPage: totalPage,
        ),
      ),
    );
  }

  @override
  Future<Either<Failure, ArticlePage>> getArticlesByCategory(
    String categoryId, {
    int page = 1,
    int limit = 10,
    String? searchTerm,
  }) async {
    calls.add('category $categoryId p$page "${searchTerm ?? ''}"');
    return _page(page, searchTerm);
  }

  @override
  Future<Either<Failure, ArticlePage>> searchArticles({
    int page = 1,
    int limit = 10,
    String? categoryId,
    String? searchTerm,
  }) async {
    calls.add('all p$page "${searchTerm ?? ''}"');
    return _page(page, searchTerm);
  }

  @override
  Future<Either<Failure, Article>> getArticleById(String articleId) async {
    calls.add('article $articleId');
    final failure = articleFailure;
    if (failure != null) return Left(failure);
    return Right(
      _article(
        articleId,
        content: const LocalizedText(
          bn: '## ওহির সূচনা\n\n1. **সত্য স্বপ্ন**',
          en: '## The Descent\n\n1. **True Dreams**\n2. Angel in Human Form',
        ),
      ),
    );
  }
}

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 20));

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  bool bangla = false,
}) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final language = LanguageBloc(initialLanguage: AppLanguage.english);
  if (bangla) language.add(const UpdateLanguage(AppLanguage.bangla));
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, child) => BlocProvider.value(
        value: language,
        child: MaterialApp(home: screen),
      ),
    ),
  );
  for (var i = 0; i < 100; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
  }
  // Pages pulled in after the first frame, and HTML laid out.
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  setUpAll(() async {
    final dir = await Directory.systemTemp.createTemp('learning_test');
    Hive.init(dir.path);
    await Hive.openBox<dynamic>(HiveService.authBox);
  });

  group('LearningRemoteDataSource', () {
    test('categories: page and limit, bearer token, active only, ordered, '
        'with meta', () async {
      final s = _setup({
        'GET /articles/categories': (
          200,
          _ok(
            [
              _categoryJson('b', order: 2),
              _categoryJson('a', order: 1),
              _categoryJson('off', active: false),
            ],
            meta: {'page': 1, 'limit': 10, 'total': 16, 'totalPage': 2},
          ),
        ),
      });
      final page = await s.source.getArticleCategories(page: 1, limit: 10);
      expect(s.http.last.uri.queryParameters, {'page': '1', 'limit': '10'});
      expect(s.http.last.headers['Authorization'], 'Bearer tkn');
      expect(page.categories.map((c) => c.id), ['a', 'b']);
      expect(page.categories.first.totalArticles, 3);
      expect(page.categories.first.description.en, 'About a');
      expect(page.meta.totalPage, 2);
      expect(page.meta.hasMore, isTrue);
    });

    test('category articles: path, search term, drafts dropped', () async {
      final s = _setup({
        'GET /articles/categories/cat1': (
          200,
          _ok(
            [_articleJson('x1'), _articleJson('x2', status: 'draft')],
            meta: {'page': 2, 'limit': 10, 'total': 11, 'totalPage': 2},
          ),
        ),
      });
      final page = await s.source.getArticlesByCategory(
        'cat1',
        page: 2,
        limit: 10,
        searchTerm: '  Prophetic ',
      );
      expect(s.http.last.uri.queryParameters, {
        'page': '2',
        'limit': '10',
        'searchTerm': 'Prophetic',
      });
      expect(page.articles.map((a) => a.id), ['x1']);
      final article = page.articles.single;
      expect(article.categoryId, 'cat1');
      expect(article.categoryName.en, 'Quran & Revelation');
      expect(article.coverImageUrl, 'https://cdn.example.test/x1.jpg');
      expect(article.publishedAt, DateTime.utc(2026, 9, 27, 5, 12, 12, 815));
      expect(article.content.isEmpty, isTrue);
      expect(page.meta.hasMore, isFalse);
    });

    test('a blank search term is not sent', () async {
      final s = _setup({
        'GET /articles/categories/cat1': (200, _ok(<Object>[])),
      });
      await s.source.getArticlesByCategory(
        'cat1',
        page: 1,
        limit: 10,
        searchTerm: '   ',
      );
      expect(s.http.last.uri.queryParameters.containsKey('searchTerm'), false);
    });

    test(
      'general search uses /articles with categoryId and searchTerm',
      () async {
        final s = _setup({
          'GET /articles': (200, _ok([_articleJson('g1')])),
        });
        final page = await s.source.searchArticles(
          page: 1,
          limit: 10,
          categoryId: 'cat1',
          searchTerm: 'sabr',
        );
        expect(s.http.last.uri.queryParameters, {
          'categoryId': 'cat1',
          'page': '1',
          'limit': '10',
          'searchTerm': 'sabr',
        });
        expect(page.articles.single.id, 'g1');
        // No meta: one page holding what came back.
        expect(page.meta.hasMore, isFalse);
      },
    );

    test('article detail: full bilingual content; a bare category id and a '
        'bad cover URL are handled', () async {
      final json = _articleJson(
        'd1',
        content: {'bn': '## শিরোনাম', 'en': '## Heading'},
      )..['categoryId'] = 'cat9';
      json['coverImageUrl'] = 'not a url';
      final s = _setup({'GET /articles/d1': (200, _ok(json))});
      final article = await s.source.getArticleById('d1');
      expect(s.http.last.headers['Authorization'], 'Bearer tkn');
      expect(article.content.en, '## Heading');
      expect(article.content.bn, '## শিরোনাম');
      expect(article.categoryId, 'cat9');
      expect(article.categoryName.isEmpty, isTrue);
      expect(article.coverImageUrl, isNull);
    });

    test('a 404, and a draft detail, fail as not found', () async {
      final s = _setup({
        'GET /articles/draft': (
          200,
          _ok(_articleJson('draft', status: 'draft')),
        ),
      });
      final repo = LearningRepositoryImpl(s.source);
      final missing = await repo.getArticleById('gone');
      expect(missing.fold((f) => f.statusCode, (_) => null), 404);
      final draft = await repo.getArticleById('draft');
      expect(draft.fold((f) => f.statusCode, (_) => null), 404);
    });
  });

  test('the repository keeps articles already read', () async {
    final s = _setup({
      'GET /articles/d1': (200, _ok(_articleJson('d1', content: 'Body'))),
    });
    final repo = LearningRepositoryImpl(s.source);
    await repo.getArticleById('d1');
    await repo.getArticleById('d1');
    expect(s.http.requests, hasLength(1));
  });

  group('ArticleCategoriesBloc', () {
    test('loads page after page until the last', () async {
      final repo = _FakeLearning();
      final bloc = ArticleCategoriesBloc(GetArticleCategories(repo));
      bloc.add(const LoadArticleCategories());
      await _settle();
      expect(bloc.state.items.map((c) => c.id), ['c1']);
      expect(bloc.state.hasMore, isTrue);
      bloc.add(const LoadMoreArticleCategories());
      await _settle();
      bloc.add(const LoadMoreArticleCategories());
      await _settle();
      expect(bloc.state.items.map((c) => c.id), ['c1', 'c2']);
      expect(bloc.state.hasMore, isFalse);
      expect(repo.calls, ['categories p1', 'categories p2']);
      await bloc.close();
    });
  });

  group('ArticlesBloc', () {
    test('a category list pages through its own endpoint, one request at a '
        'time', () async {
      final repo = _FakeLearning();
      final bloc = ArticlesBloc(
        GetArticles(repo),
        scope: const ArticleListScope.category(_category),
      );
      bloc.add(const LoadArticles());
      await _settle();
      // Two scroll events while page 2 is on its way fetch it once.
      bloc
        ..add(const LoadMoreArticles())
        ..add(const LoadMoreArticles());
      await _settle();
      bloc.add(const LoadMoreArticles());
      await _settle();
      bloc.add(const LoadMoreArticles());
      await _settle();
      expect(bloc.state.items.map((a) => a.id), ['a1', 'a2', 'a3', 'a4', 'a5']);
      expect(bloc.state.hasMore, isFalse);
      expect(repo.calls, [
        'category cat1 p1 ""',
        'category cat1 p2 ""',
        'category cat1 p3 ""',
      ]);
      await bloc.close();
    });

    test(
      'a search starts again from page 1; the same term is not re-sent',
      () async {
        final repo = _FakeLearning(total: 12);
        final bloc = ArticlesBloc(
          GetArticles(repo),
          scope: const ArticleListScope.all(),
        );
        bloc.add(const LoadArticles());
        await _settle();
        bloc.add(const LoadMoreArticles());
        await _settle();
        bloc.add(const SearchArticles(' 1'));
        await _settle();
        bloc.add(const SearchArticles('1 '));
        await _settle();
        expect(repo.calls, ['all p1 ""', 'all p2 ""', 'all p1 "1"']);
        expect(bloc.state.page, 1);
        expect(bloc.state.searchTerm, '1');
        expect(bloc.state.items.map((a) => a.id), ['a1', 'a10']);
        await bloc.close();
      },
    );

    test('a failed first page can be retried', () async {
      final repo = _FakeLearning()..listFailure = const NetworkFailure();
      final bloc = ArticlesBloc(
        GetArticles(repo),
        scope: const ArticleListScope.all(),
      );
      bloc.add(const LoadArticles());
      await _settle();
      expect(bloc.state.status, LearningLoadStatus.failure);
      repo.listFailure = null;
      bloc.add(const LoadArticles());
      await _settle();
      expect(bloc.state.status, LearningLoadStatus.success);
      await bloc.close();
    });
  });

  test('article Markdown becomes HTML; raw HTML stays text', () {
    final html = articleMarkdownToHtml(
      '## The Descent\n\n### Forms\n\n1. **True Dreams**\n2. Angel\n\n'
      '<script>alert(1)</script>',
    );
    expect(html, contains('<h2>The Descent</h2>'));
    expect(html, contains('<h3>Forms</h3>'));
    expect(html, contains('<li><strong>True Dreams</strong></li>'));
    expect(html, isNot(contains('<script>')));
    expect(html, isNot(contains('##')));
  });

  test('failures map to localized messages, never server text', () {
    final en = AppText.forLanguage(AppLanguage.english);
    String message(
      Failure f, [
      LearningResource r = LearningResource.articles,
    ]) => learningFailureMessage(en, f, r);
    expect(message(const NetworkFailure()), en.quizErrorNetwork);
    expect(
      message(const ServerFailure('jwt expired', statusCode: 401)),
      en.quizErrorSession,
    );
    expect(
      message(const ServerFailure('x', statusCode: 403)),
      en.quizErrorForbidden,
    );
    expect(
      message(
        const ServerFailure('x', statusCode: 404),
        LearningResource.article,
      ),
      en.learningArticleNotFound,
    );
    expect(
      message(const ServerFailure('x', statusCode: 422)),
      en.learningErrorInvalid,
    );
    expect(
      message(const ServerFailure('x', statusCode: 429)),
      en.learningErrorRateLimit,
    );
    expect(
      message(const ServerFailure('stack trace', statusCode: 500)),
      en.quizErrorGeneric,
    );
  });

  group('screens', () {
    for (final bangla in [false, true]) {
      final lang = bangla ? 'Bangla' : 'English';

      testWidgets('Learning tab shows categories and recent articles ($lang)', (
        tester,
      ) async {
        final repo = _FakeLearning();
        await _pump(
          tester,
          MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) =>
                    ArticleCategoriesBloc(GetArticleCategories(repo))
                      ..add(const LoadArticleCategories()),
              ),
              BlocProvider(
                create: (_) => ArticlesBloc(
                  GetArticles(repo),
                  scope: const ArticleListScope.all(),
                  pageSize: 3,
                )..add(const LoadArticles()),
              ),
            ],
            child: const LearningScreen(),
          ),
          bangla: bangla,
        );
        expect(find.text(bangla ? 'বিভাগ 1' : 'Category 1'), findsOneWidget);
        // The short first page pulls in the next one.
        expect(find.text(bangla ? 'বিভাগ 2' : 'Category 2'), findsOneWidget);
        expect(find.text(bangla ? 'শিরোনাম a1' : 'Title a1'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('article details render Markdown, not its syntax ($lang)', (
        tester,
      ) async {
        await _pump(
          tester,
          BlocProvider(
            create: (_) =>
                ArticleDetailBloc(GetArticle(_FakeLearning()), articleId: 'a1')
                  ..add(const LoadArticle()),
            child: const ArticleDetailsScreen(),
          ),
          bangla: bangla,
        );
        expect(find.text(bangla ? 'শিরোনাম a1' : 'Title a1'), findsOneWidget);
        expect(
          find.textContaining(
            bangla ? 'ওহির সূচনা' : 'The Descent',
            findRichText: true,
          ),
          findsOneWidget,
        );
        expect(find.textContaining('##', findRichText: true), findsNothing);
        expect(find.textContaining('**', findRichText: true), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('a missing article says so, without Try Again', (tester) async {
      final repo = _FakeLearning()
        ..articleFailure = const ServerFailure('nope', statusCode: 404);
      await _pump(
        tester,
        BlocProvider(
          create: (_) =>
              ArticleDetailBloc(GetArticle(repo), articleId: 'gone')
                ..add(const LoadArticle()),
          child: const ArticleDetailsScreen(),
        ),
      );
      final en = AppText.forLanguage(AppLanguage.english);
      expect(find.text(en.learningArticleNotFound), findsOneWidget);
      expect(find.text(en.tryAgain), findsNothing);
    });

    testWidgets('a search with no results says so', (tester) async {
      final repo = _FakeLearning();
      await _pump(
        tester,
        BlocProvider(
          create: (_) => ArticlesBloc(
            GetArticles(repo),
            scope: const ArticleListScope.category(_category),
          )..add(const LoadArticles()),
          child: const ArticlesScreen(),
        ),
      );
      final en = AppText.forLanguage(AppLanguage.english);
      expect(find.text('Quran & Revelation'), findsWidgets);
      expect(find.text('Revelation history'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'nothing like this');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text(en.learningNoSearchResults), findsOneWidget);
      expect(repo.calls.last, 'category cat1 p1 "nothing like this"');
    });

    testWidgets('a failed list offers Try Again', (tester) async {
      final repo = _FakeLearning()..listFailure = const NetworkFailure();
      await _pump(
        tester,
        BlocProvider(
          create: (_) => ArticlesBloc(
            GetArticles(repo),
            scope: const ArticleListScope.all(),
          )..add(const LoadArticles()),
          child: const ArticlesScreen(),
        ),
      );
      final en = AppText.forLanguage(AppLanguage.english);
      expect(find.text(en.quizErrorNetwork), findsOneWidget);
      repo.listFailure = null;
      await tester.tap(find.text(en.tryAgain));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Title a1'), findsOneWidget);
    });
  });
}
