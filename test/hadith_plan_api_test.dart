import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami_app_noorify/core/errors/exceptions.dart';
import 'package:islami_app_noorify/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:islami_app_noorify/features/hadith/data/datasources/hadith_library_remote_data_source.dart';
import 'package:islami_app_noorify/features/hadith/data/models/hadith_detail_model.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_plan_draft.dart';

/// Answers every request with a canned body, and remembers the requests.
class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.body, {this.status = 200});

  Object body;
  int status;
  final requests = <RequestOptions>[];

  RequestOptions get last => requests.last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
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
  _FakeLocal(this.token);

  final String? token;

  @override
  String? getToken() => token;

  @override
  bool get hasToken => token != null;

  @override
  Future<void> cacheToken(String token) async {}

  @override
  Future<void> clearToken() async {}
}

const _ok = {'statusCode': 200, 'success': true, 'message': 'ok', 'data': []};

/// A data source over a stubbed connection, signed in as `tkn` unless told
/// otherwise.
({HadithLibraryRemoteDataSourceImpl source, _StubAdapter http}) _setup({
  Object body = _ok,
  int status = 200,
  String? token = 'tkn',
}) {
  final http = _StubAdapter(body, status: status);
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://example.test/api/v1',
      // As the app's own client: read 4xx bodies instead of throwing.
      validateStatus: (s) => s != null && s < 500,
    ),
  )..httpClientAdapter = http;
  return (
    source: HadithLibraryRemoteDataSourceImpl(
      dio: dio,
      local: _FakeLocal(token),
    ),
    http: http,
  );
}

void main() {
  group('GET /hadiths/plans', () {
    test('asks for the in-progress plans, signed in, and reads them', () async {
      final t = _setup(
        body: {
          'statusCode': 200,
          'success': true,
          'data': [
            {
              '_id': 'p1',
              'name': 'euur',
              'targetDays': 20,
              'status': 'in_progress',
              'counts': {
                'totalHadiths': 7,
                'completedHadiths': 0,
                'percentage': 0,
                'isCompleted': false,
              },
            },
          ],
          'meta': {'page': 1, 'limit': 10, 'total': 1, 'totalPage': 1},
        },
      );

      final page = await t.source.getPlans(
        status: 'in_progress',
        page: 1,
        limit: 10,
      );

      expect(t.http.last.method, 'GET');
      expect(t.http.last.path, '/hadiths/plans');
      expect(t.http.last.queryParameters, {
        'status': 'in_progress',
        'page': 1,
        'limit': 10,
      });
      expect(t.http.last.headers['Authorization'], 'Bearer tkn');
      expect(page.plans.single.name, 'euur');
      expect(page.plans.single.totalHadiths, 7);
    });

    test('without a status it asks for every plan', () async {
      final t = _setup();
      await t.source.getPlans(page: 2, limit: 10);
      expect(t.http.last.queryParameters, {'page': 2, 'limit': 10});
    });
  });

  group('GET /hadiths/plans/{id}/hadiths', () {
    test('asks for that plan, signed in, page by page', () async {
      final t = _setup();
      await t.source.getHadiths(planId: 'plan-9', page: 3, limit: 50);

      expect(t.http.last.method, 'GET');
      expect(t.http.last.path, '/hadiths/plans/plan-9/hadiths');
      expect(t.http.last.queryParameters, {'page': 3, 'limit': 50});
      expect(t.http.last.headers['Authorization'], 'Bearer tkn');
    });

    test('reads hadiths nested under "hadith" or "hadithId"', () async {
      final t = _setup(
        body: {
          'success': true,
          'data': [
            {
              'isRead': true,
              'hadith': {'_id': 'h1', 'hadithNumber': 11, 'textBangla': 'a'},
            },
            {
              'isRead': false,
              'hadithId': {'_id': 'h2', 'hadithNumber': 12, 'textBangla': 'b'},
            },
          ],
          'meta': {'page': 1, 'totalPage': 1, 'total': 2},
        },
      );

      final page = await t.source.getHadiths(planId: 'p', page: 1, limit: 50);

      expect(page.hadiths.map((h) => h.id), ['h1', 'h2']);
      expect(page.hadiths.map((h) => h.hadithNumber), [11, 12]);
      expect(page.hadiths.first.textBangla, 'a');
    });

    test('reads hadiths that come flat, with the read state beside them', () {
      final flat = unwrapPlanHadith({
        '_id': 'h3',
        'hadithNumber': 13,
        'isRead': true,
      });
      expect(HadithDetailModel.fromJson(flat).id, 'h3');
      expect(HadithDetailModel.fromJson(flat).hadithNumber, 13);
    });

    test('a book or a sub-category still uses the public list', () async {
      final t = _setup();
      await t.source.getHadiths(subCategoryId: 'sc1', page: 1, limit: 50);

      expect(t.http.last.path, '/hadiths');
      expect(t.http.last.queryParameters['subCategoryId'], 'sc1');
      // Public: no login needed, so none is sent.
      expect(t.http.last.headers.containsKey('Authorization'), isFalse);
    });

    test('an unknown plan is a 404 with the API message', () async {
      final t = _setup(
        status: 404,
        body: {'success': false, 'message': 'Plan not found'},
      );
      await expectLater(
        t.source.getHadiths(planId: 'nope', page: 1, limit: 50),
        throwsA(
          isA<ServerException>()
              .having((e) => e.message, 'message', 'Plan not found')
              .having((e) => e.statusCode, 'status', 404),
        ),
      );
    });
  });

  group('PATCH /hadiths/plans/{id}', () {
    test('sends only what changed, signed in', () async {
      final t = _setup();

      await t.source.updatePlan('p1', name: 'New name', targetDays: 15);
      expect(t.http.last.method, 'PATCH');
      expect(t.http.last.path, '/hadiths/plans/p1');
      expect(t.http.last.data, {'name': 'New name', 'targetDays': 15});
      expect(t.http.last.headers['Authorization'], 'Bearer tkn');

      await t.source.updatePlan('p1', name: 'Only name');
      expect(t.http.last.data, {'name': 'Only name'});

      await t.source.updatePlan('p1', targetDays: 40);
      expect(t.http.last.data, {'targetDays': 40});
    });

    test('a taken name is a 409 with the API message', () async {
      final t = _setup(
        status: 409,
        body: {
          'success': false,
          'message': 'A plan with this name already exists',
        },
      );
      await expectLater(
        t.source.updatePlan('p1', name: 'taken'),
        throwsA(
          isA<ServerException>()
              .having(
                (e) => e.message,
                'message',
                'A plan with this name already exists',
              )
              .having((e) => e.statusCode, 'status', 409),
        ),
      );
    });
  });

  group('DELETE /hadiths/plans/{id}', () {
    test('deletes that plan, signed in', () async {
      final t = _setup();
      await t.source.deletePlan('p1');

      expect(t.http.last.method, 'DELETE');
      expect(t.http.last.path, '/hadiths/plans/p1');
      expect(t.http.last.headers['Authorization'], 'Bearer tkn');
    });

    test('an already-deleted plan is a 404 with the API message', () async {
      final t = _setup(
        status: 404,
        body: {'success': false, 'message': 'Plan not found'},
      );
      await expectLater(
        t.source.deletePlan('gone'),
        throwsA(
          isA<ServerException>().having(
            (e) => e.message,
            'message',
            'Plan not found',
          ),
        ),
      );
    });
  });

  group('POST /hadiths/plans (unchanged by the shared request helper)', () {
    test('still sends the plan with the target days', () async {
      final t = _setup();
      await t.source.createPlan(
        const HadithPlanDraft(
          name: 'My plan',
          bookId: 'b1',
          categoryIds: ['c1'],
          targetDays: 30,
        ),
      );

      expect(t.http.last.method, 'POST');
      expect(t.http.last.path, '/hadiths/plans');
      expect(t.http.last.data, {
        'name': 'My plan',
        'bookId': 'b1',
        'categoryIds': ['c1'],
        'targetDays': 30,
      });
      expect(t.http.last.headers['Authorization'], 'Bearer tkn');
    });

    test('signed out, no token is sent', () async {
      final t = _setup(token: null);
      await t.source.deletePlan('p1');
      expect(t.http.last.headers.containsKey('Authorization'), isFalse);
    });
  });
}
