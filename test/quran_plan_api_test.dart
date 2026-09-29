import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami_app_noorify/core/errors/exceptions.dart';
import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/core/localization/localized_failure_message.dart';
import 'package:islami_app_noorify/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:islami_app_noorify/features/quran/data/datasources/quran_plan_remote_data_source.dart';
import 'package:islami_app_noorify/features/quran/data/repositories/quran_plan_repository_impl.dart';
import 'package:islami_app_noorify/features/quran/domain/quran_plan.dart';
import 'package:islami_app_noorify/features/quran/presentation/quran_text.dart';
import 'package:islami_app_noorify/shared/bloc/language/language_bloc.dart';
import 'package:islami_app_noorify/shared/bloc/language/language_preference.dart';

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

final _sampleCreateResponse = {
  "statusCode": 201,
  "success": true,
  "message": "Quran plan created successfully!",
  "data": {
    "userId": "6ab5f452f04a5bbedaad3f1c",
    "name": "Ramadan khatm",
    "surahNumbers": [],
    "paraNumbers": [],
    "wholeQuran": true,
    "targetDays": 30,
    "startDate": "2026-09-28",
    "status": "in_progress",
    "completedAt": null,
    "isActive": true,
    "_id": "6aba896bc04b7bc85017f487",
    "createdAt": "2026-09-28T15:36:11.096Z",
    "updatedAt": "2026-09-28T15:36:11.096Z",
    "counts": {
      "totalAyahs": 6236,
      "completedAyahs": 20,
      "remainingAyahs": 6216,
      "percentage": 0,
      "isCompleted": false,
      "totalSurahs": 114,
      "totalParas": 30,
    },
    "schedule": {
      "startDate": "2026-09-28",
      "endDate": "2026-10-27",
      "targetDays": 30,
      "dayNumber": 1,
      "daysLeft": 29,
      "ayahsPerDay": 208,
      "expectedAyahs": 208,
      "isOnTrack": false,
      "aheadBy": -188,
      "todayRemainingAyahs": 188,
      "requiredAyahsPerDay": 208,
      "isOverdue": false,
    },
  },
};

final _sampleGetResponse = {
  "statusCode": 200,
  "success": true,
  "message": "Quran plans retrieved successfully!",
  "data": [
    {
      "_id": "6aba896bc04b7bc85017f487",
      "userId": "6ab5f452f04a5bbedaad3f1c",
      "name": "Ramadan khatm",
      "surahNumbers": [],
      "paraNumbers": [],
      "wholeQuran": true,
      "targetDays": 30,
      "startDate": "2026-09-28",
      "status": "in_progress",
      "completedAt": null,
      "isActive": true,
      "createdAt": "2026-09-28T15:36:11.096Z",
      "updatedAt": "2026-09-28T15:36:11.096Z",
      "counts": {
        "totalAyahs": 6236,
        "completedAyahs": 80,
        "remainingAyahs": 6156,
        "percentage": 1,
        "isCompleted": false,
        "totalSurahs": 114,
        "totalParas": 30,
      },
      "schedule": {
        "startDate": "2026-09-28",
        "endDate": "2026-10-27",
        "targetDays": 30,
        "dayNumber": 2,
        "daysLeft": 28,
        "ayahsPerDay": 208,
        "expectedAyahs": 416,
        "isOnTrack": false,
        "aheadBy": -336,
        "todayRemainingAyahs": 336,
        "requiredAyahsPerDay": 213,
        "isOverdue": false,
      },
    },
  ],
  "meta": {
    "page": 1,
    "limit": 10,
    "total": 1,
    "totalPage": 1,
  },
};

({QuranPlanRemoteDataSourceImpl source, _StubAdapter http}) _setup({
  Object body = const {'statusCode': 200, 'success': true, 'data': []},
  int status = 200,
  String? token = 'sample_token_xyz',
}) {
  final http = _StubAdapter(body, status: status);
  final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api/v1'))
    ..httpClientAdapter = http;
  final local = _FakeLocal(token);
  final source = QuranPlanRemoteDataSourceImpl(dio: dio, local: local);
  return (source: source, http: http);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QuranPlanRemoteDataSource', () {
    test('createPlan sends POST and parses counts & schedule', () async {
      final env = _setup(body: _sampleCreateResponse, status: 201);
      final plan = await env.source.createPlan(
        const CreateQuranPlanRequest(
          name: 'Ramadan khatm',
          wholeQuran: true,
          targetDays: 30,
        ),
      );

      expect(env.http.last.method, 'POST');
      expect(env.http.last.path, '/quran/plans');
      expect(env.http.last.headers['Authorization'], 'Bearer sample_token_xyz');
      expect(env.http.last.data, {
        'name': 'Ramadan khatm',
        'wholeQuran': true,
        'targetDays': 30,
      });

      expect(plan.id, '6aba896bc04b7bc85017f487');
      expect(plan.name, 'Ramadan khatm');
      expect(plan.targetDays, 30);
      expect(plan.days, 30);
      expect(plan.wholeQuran, isTrue);
      expect(plan.counts.totalAyahs, 6236);
      expect(plan.counts.completedAyahs, 20);
      expect(plan.counts.remainingAyahs, 6216);
      expect(plan.schedule.dayNumber, 1);
      expect(plan.schedule.daysLeft, 29);
      expect(plan.schedule.ayahsPerDay, 208);
      expect(plan.schedule.aheadBy, -188);
      expect(plan.schedule.isOverdue, isFalse);
    });

    test('getPlans sends status & pagination and parses meta', () async {
      final env = _setup(body: _sampleGetResponse);
      final response = await env.source.getPlans(
        status: 'in_progress',
        page: 1,
        limit: 10,
      );

      expect(env.http.last.method, 'GET');
      expect(env.http.last.path, '/quran/plans');
      expect(env.http.last.queryParameters, {
        'status': 'in_progress',
        'page': 1,
        'limit': 10,
      });

      expect(response.plans.length, 1);
      final plan = response.plans.first;
      expect(plan.counts.completedAyahs, 80);
      expect(plan.schedule.dayNumber, 2);
      expect(response.meta.page, 1);
      expect(response.meta.total, 1);
      expect(response.meta.totalPage, 1);
      expect(response.meta.hasMore, isFalse);
    });

    test('createPlan throws ServerException on 409 duplicate name', () async {
      final env = _setup(
        body: {
          'statusCode': 409,
          'success': false,
          'message': 'You already have a plan with this name',
        },
        status: 409,
      );

      expect(
        () => env.source.createPlan(
          const CreateQuranPlanRequest(
            name: 'Duplicate Plan',
            targetDays: 30,
          ),
        ),
        throwsA(
          isA<ServerException>().having(
            (e) => e.statusCode,
            'statusCode',
            409,
          ).having(
            (e) => e.message,
            'message',
            'You already have a plan with this name',
          ),
        ),
      );
    });

    test('updatePlan sends PATCH with planId', () async {
      final env = _setup(body: _sampleCreateResponse);
      final updated = await env.source.updatePlan(
        'plan_123',
        const UpdateQuranPlanRequest(status: 'completed'),
      );

      expect(env.http.last.method, 'PATCH');
      expect(env.http.last.path, '/quran/plans/plan_123');
      expect(env.http.last.data, {'status': 'completed'});
      expect(updated.id, isNotEmpty);
    });
  });

  group('QuranPlanRepositoryImpl', () {
    test('caches getPlans within cache duration', () async {
      final env = _setup(body: _sampleGetResponse);
      final repo = QuranPlanRepositoryImpl(
        env.source,
        isSignedIn: () => true,
        cacheFor: const Duration(minutes: 5),
      );

      final r1 = await repo.getPlans(status: 'in_progress');
      expect(r1.isRight(), isTrue);
      expect(env.http.requests.length, 1);

      final r2 = await repo.getPlans(status: 'in_progress');
      expect(r2.isRight(), isTrue);
      // Cached: no new network request made
      expect(env.http.requests.length, 1);

      // Force refresh bypasses cache
      final r3 = await repo.getPlans(status: 'in_progress', forceRefresh: true);
      expect(r3.isRight(), isTrue);
      expect(env.http.requests.length, 2);
    });

    test('invalidates cache on plan creation', () async {
      final env = _setup(body: _sampleGetResponse);
      final repo = QuranPlanRepositoryImpl(
        env.source,
        isSignedIn: () => true,
        cacheFor: const Duration(minutes: 5),
      );

      await repo.getPlans(status: 'in_progress');
      expect(env.http.requests.length, 1);

      env.http.body = _sampleCreateResponse;
      env.http.status = 201;

      await repo.createPlan(
        const CreateQuranPlanRequest(name: 'New Plan', targetDays: 30),
      );
      expect(env.http.requests.length, 2);

      // Now getPlans refetches because cache was cleared
      env.http.body = _sampleGetResponse;
      env.http.status = 200;
      await repo.getPlans(status: 'in_progress');
      expect(env.http.requests.length, 3);
    });

    test('guards against 409 ServerFailure', () async {
      final env = _setup(
        body: {
          'statusCode': 409,
          'success': false,
          'message': 'You already have a plan with this name',
        },
        status: 409,
      );
      final repo = QuranPlanRepositoryImpl(env.source, isSignedIn: () => true);

      final result = await repo.createPlan(
        const CreateQuranPlanRequest(name: 'Duplicate', targetDays: 30),
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect((failure as ServerFailure).statusCode, 409);
          expect(failure.rawMessage, 'You already have a plan with this name');
          expect(failure.message, 'এই নামে আপনার ইতোমধ্যে একটি কুরআন প্ল্যান রয়েছে।');
        },
        (_) => fail('Should not succeed'),
      );
    });
  });

  group('Localization & Duplicate plan error', () {
    test('localizeFailureMessage maps 409 duplicate plan message in English', () {
      LanguagePreference.current = AppLanguage.english;
      final localized = localizeFailureMessage(
        'You already have a plan with this name',
      );
      expect(localized, 'You already have a Quran plan with this name.');
    });

    test('localizeFailureMessage maps 409 duplicate plan message in Bangla', () {
      LanguagePreference.current = AppLanguage.bangla;
      final localized = localizeFailureMessage(
        'You already have a plan with this name',
      );
      expect(localized, 'এই নামে আপনার ইতোমধ্যে একটি কুরআন প্ল্যান রয়েছে।');
    });

    test('QuranText provides English and Bangla plan strings', () {
      expect(QuranText.english.quranPlan, 'Quran Plan');
      expect(QuranText.bangla.quranPlan, 'কুরআন প্ল্যান');

      expect(QuranText.english.targetDays, 'Target Days');
      expect(QuranText.bangla.targetDays, 'লক্ষ্য দিন');

      expect(QuranText.english.onTrack, 'On Track');
      expect(QuranText.bangla.onTrack, 'সময়সূচি অনুযায়ী');

      expect(QuranText.english.behindSchedule, 'Behind Schedule');
      expect(QuranText.bangla.behindSchedule, 'সময়সূচি থেকে পিছিয়ে');

      expect(QuranText.english.overdue, 'Overdue');
      expect(QuranText.bangla.overdue, 'সময়সীমা অতিক্রম হয়েছে');
    });
  });
}
