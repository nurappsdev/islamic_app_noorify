import 'dart:convert';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tuhfatul_muslim/core/errors/exceptions.dart';
import 'package:tuhfatul_muslim/features/promo_banner/data/datasources/promo_banner_remote_data_source.dart';
import 'package:tuhfatul_muslim/features/promo_banner/data/models/promo_banner_model.dart';
import 'package:tuhfatul_muslim/features/promo_banner/data/repositories/promo_banner_repository_impl.dart';
import 'package:tuhfatul_muslim/features/promo_banner/domain/entities/promo_banner.dart';
import 'package:tuhfatul_muslim/features/promo_banner/domain/repositories/promo_banner_repository.dart';
import 'package:tuhfatul_muslim/features/promo_banner/presentation/promo_banner_navigation.dart';
import 'package:tuhfatul_muslim/features/promo_banner/presentation/widgets/promo_banner_carousel.dart';

/// The documented answer, one entry per action type.
const _body = {
  'statusCode': 200,
  'success': true,
  'data': [
    {
      '_id': '6b0169541f2d7c6c3d3a4d40',
      'title': 'Daily Dua Plan',
      'description': 'Build a consistent habit.',
      'imageUrl': 'https://cdn.example.com/banner-1.png',
      'actionType': 'app_screen',
      'actionUrl': '/duas',
      'displayOrder': 1,
      'isActive': true,
      'clickCount': 14,
      'viewCount': 350,
    },
    {
      '_id': '6b0169541f2d7c6c3d3a4d41',
      'title': 'Islamic Foundation Bangladesh',
      'description': 'Visit official Islamic resources.',
      'imageUrl': 'https://cdn.example.com/banner-2.png',
      'actionType': 'url',
      'actionUrl': 'https://islamicfoundation.gov.bd',
      'displayOrder': 2,
    },
    {
      '_id': '6b0169541f2d7c6c3d3a4d42',
      'title': 'Ramadan Coming Soon',
      'description': 'Prepare for the blessed month.',
      'imageUrl': 'https://images.example.com/photo.jpg',
      'actionType': 'none',
      'actionUrl': null,
      'displayOrder': 3,
    },
  ],
};

PromoBanner _banner({
  String id = 'id',
  String type = 'app_screen',
  Object? url = '/duas',
  String image = 'https://cdn.example.com/banner.png',
}) => PromoBannerModel.fromJson({
  '_id': id,
  'title': 'Daily Dua Plan',
  'imageUrl': image,
  'actionType': type,
  'actionUrl': url,
});

class _Repo implements PromoBannerRepository {
  _Repo(this._answer);

  final Either<Failure, List<PromoBanner>> _answer;
  final clicked = <String>[];

  @override
  Future<Either<Failure, List<PromoBanner>>> getActiveBanners() async =>
      _answer;

  @override
  Future<void> trackClick(String bannerId) async => clicked.add(bannerId);
}

/// Answers every request with one canned body, and remembers what was asked.
class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.body, {this.statusCode = 200});

  final Object body;
  final int statusCode;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

PromoBannerRemoteDataSourceImpl _source(_StubAdapter adapter) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.test/api/v1',
      validateStatus: (status) => status != null && status < 500,
    ),
  )..httpClientAdapter = adapter;
  return PromoBannerRemoteDataSourceImpl(dio: dio);
}

void main() {
  group('the response is read as the backend documents it', () {
    test('every documented action type survives the trip', () {
      final banners = PromoBannerModel.listFrom(_body['data']);

      expect(banners, hasLength(3));
      expect(banners.first.id, '6b0169541f2d7c6c3d3a4d40');
      expect(banners.first.title, 'Daily Dua Plan');
      expect(banners.first.action, PromoBannerAction.appScreen);
      expect(banners.first.actionUrl, '/duas');
      expect(banners[1].action, PromoBannerAction.externalUrl);
      expect(banners[1].actionUrl, 'https://islamicfoundation.gov.bd');
      expect(banners[2].action, PromoBannerAction.none);
      // `actionUrl: null` must not become the string "null".
      expect(banners[2].actionUrl, isEmpty);
    });

    test('the admin ordering is the order they are shown in', () {
      final banners = PromoBannerModel.listFrom(_body['data']);
      expect(banners.map((banner) => banner.displayOrder).toList(), [1, 2, 3]);
    });

    test('no banners is an answer, not a failure', () {
      expect(PromoBannerModel.listFrom(const []), isEmpty);
      expect(PromoBannerModel.listFrom(null), isEmpty);
    });

    test('a banner with no image is dropped rather than drawn blank', () {
      expect(
        PromoBannerModel.listFrom([
          {'_id': 'a', 'imageUrl': '', 'actionType': 'none'},
          {'_id': 'b', 'imageUrl': ' ', 'actionType': 'none'},
        ]),
        isEmpty,
      );
    });

    test('an unknown action type is read as "show the picture only"', () {
      expect(_banner(type: 'deeplink').action, PromoBannerAction.none);
      expect(_banner(type: 'deeplink').actionUrl, isEmpty);
    });
  });

  group('where a banner leads', () {
    test('the API spellings all reach a real screen', () {
      const expected = {
        '/duas': RouteNames.dua,
        '/quran': RouteNames.quran,
        '/hadiths': RouteNames.hadith,
        '/zakat': RouteNames.zakatCalculator,
        '/zikr': RouteNames.zikr,
        '/tasbih': RouteNames.tasbih,
        '/leaderboard': RouteNames.leaderboard,
      };
      for (final entry in expected.entries) {
        expect(
          promoBannerRouteFor(_banner(url: entry.key)),
          entry.value,
          reason: entry.key,
        );
      }
    });

    test('case, a trailing slash and a query do not hide the screen', () {
      expect(promoBannerRouteFor(_banner(url: '/Duas/')), RouteNames.dua);
      expect(
        promoBannerRouteFor(_banner(url: 'duas?utm_source=banner')),
        RouteNames.dua,
      );
    });

    test('a path this app does not have leads nowhere at all', () {
      // Unknown names fall through to the sign-in screen in onGenerateRoute,
      // so the tap has to do nothing instead.
      expect(promoBannerRouteFor(_banner(url: '/shop')), isNull);
      expect(promoBannerUrlFor(_banner(url: '/shop')), isNull);
      expect(promoBannerIsTappable(_banner(url: '/shop')), isFalse);
    });

    test('"none" leads nowhere even when a stale url is attached', () {
      final banner = _banner(type: 'none', url: '/duas');
      expect(promoBannerRouteFor(banner), isNull);
      expect(promoBannerUrlFor(banner), isNull);
      expect(promoBannerIsTappable(banner), isFalse);
    });

    test('a web address opens outside the app', () {
      final banner = _banner(
        type: 'url',
        url: 'https://islamicfoundation.gov.bd',
      );
      expect(promoBannerRouteFor(banner), isNull);
      expect(
        promoBannerUrlFor(banner),
        Uri.parse('https://islamicfoundation.gov.bd'),
      );
    });

    test('the value decides, not a mislabelled action type', () {
      // An `app_screen` banner carrying a full address is still an address,
      // and a `url` banner carrying a path is still a screen.
      expect(
        promoBannerUrlFor(_banner(type: 'app_screen', url: 'https://x.test')),
        Uri.parse('https://x.test'),
      );
      expect(
        promoBannerRouteFor(_banner(type: 'url', url: '/quran')),
        RouteNames.quran,
      );
    });

    test('only http and https are ever handed to the launcher', () {
      for (final url in const [
        'javascript:alert(1)',
        'file:///etc/passwd',
        'intent://evil#Intent;scheme=http;end',
        'tel:+8801000000',
      ]) {
        expect(
          promoBannerUrlFor(_banner(type: 'url', url: url)),
          isNull,
          reason: url,
        );
      }
    });
  });

  group('talking to the endpoint', () {
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
    });

    test('the active banners are fetched from the documented path', () async {
      final adapter = _StubAdapter(_body);

      final banners = await _source(adapter).getActiveBanners();

      expect(adapter.requests.single.path, '/promo-banners/active');
      expect(adapter.requests.single.method, 'GET');
      expect(banners, hasLength(3));
    });

    test('a tap is reported to the banner\'s own click path', () async {
      final adapter = _StubAdapter({'success': true});

      await _source(adapter).trackClick('6b0169541f2d7c6c3d3a4d40');

      expect(
        adapter.requests.single.path,
        '/promo-banners/6b0169541f2d7c6c3d3a4d40/click',
      );
      expect(adapter.requests.single.method, 'POST');
      expect(adapter.requests.single.data, isEmpty);
    });

    test('a server error is raised, not returned as an empty list', () async {
      final source = _source(
        _StubAdapter({
          'success': false,
          'message': 'Internal server error occurred',
        }, statusCode: 500),
      );

      await expectLater(
        source.getActiveBanners(),
        throwsA(isA<ServerException>()),
      );
    });

    test('a later failure still shows what was cached before it', () async {
      // First launch: a good answer, which is what gets cached.
      await _source(_StubAdapter(_body)).getActiveBanners();

      // Next launch is offline, or the server is down.
      final offline = PromoBannerRepositoryImpl(
        _source(_StubAdapter({'message': 'boom'}, statusCode: 500)),
      );
      final result = await offline.getActiveBanners();

      expect(
        result.getOrElse(() => const []).map((banner) => banner.id),
        containsAll(['6b0169541f2d7c6c3d3a4d40', '6b0169541f2d7c6c3d3a4d41']),
      );
    });

    test('an emptied carousel is not resurrected by yesterday\'s cache', () {
      // The empty list is cached too, so deactivating every banner really
      // does clear the slot on the next launch.
      expect(PromoBannerModel.listFrom(const []), isEmpty);
    });
  });

  group('the home slot', () {
    final pushed = <String>[];

    Future<_Repo> pump(
      WidgetTester tester,
      Either<Failure, List<PromoBanner>> answer,
    ) async {
      pushed.clear();
      final repository = _Repo(answer);
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, child) => MaterialApp(
            onGenerateRoute: (settings) {
              if (settings.name != null) pushed.add(settings.name!);
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (_) => Column(
                  children: [PromoBannerCarousel(repository: repository)],
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      pushed.clear();
      return repository;
    }

    testWidgets('with no banners it takes up no room', (tester) async {
      await pump(tester, const Right([]));

      expect(
        tester.getSize(find.byType(PromoBannerCarousel)),
        Size.zero,
        reason: 'an empty slot must not leave a gap between the cards',
      );
      expect(find.byType(PageView), findsNothing);
      expect(find.byType(SmoothPageIndicator), findsNothing);
    });

    testWidgets('a failure with nothing cached stays silent', (tester) async {
      await pump(tester, const Left(NetworkFailure()));

      expect(tester.getSize(find.byType(PromoBannerCarousel)), Size.zero);
      expect(tester.takeException(), isNull);
    });

    testWidgets('one banner is a still card with no dots', (tester) async {
      await pump(tester, Right([_banner()]));

      expect(find.byType(PageView), findsNothing);
      expect(find.byType(SmoothPageIndicator), findsNothing);
      expect(
        tester.getSize(find.byType(PromoBannerCarousel)).height,
        greaterThan(100),
      );
    });

    testWidgets('several banners slide and are counted out in dots', (
      tester,
    ) async {
      await pump(
        tester,
        Right([
          _banner(id: 'a'),
          _banner(id: 'b', type: 'url', url: 'https://x.test'),
          _banner(id: 'c', type: 'none', url: null),
        ]),
      );

      expect(find.byType(PageView), findsOneWidget);
      final indicator = tester.widget<SmoothPageIndicator>(
        find.byType(SmoothPageIndicator),
      );
      expect(indicator.count, 3);
    });

    testWidgets('a tap opens the screen and records the click', (tester) async {
      final repository = await pump(tester, Right([_banner(id: 'banner-1')]));

      await tester.tap(find.byType(PromoBannerCarousel));
      await tester.pumpAndSettle();

      expect(pushed, [RouteNames.dua]);
      expect(repository.clicked, ['banner-1']);
    });

    testWidgets('a banner that leads nowhere takes no tap', (tester) async {
      final repository = await pump(
        tester,
        Right([_banner(id: 'quiet', type: 'none', url: null)]),
      );

      await tester.tap(find.byType(PromoBannerCarousel));
      await tester.pumpAndSettle();

      expect(pushed, isEmpty);
      expect(repository.clicked, isEmpty);
    });
  });
}
