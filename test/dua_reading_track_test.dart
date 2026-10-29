import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dartz/dartz.dart' show Either, Right;
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tuhfatul_muslim/core/errors/exceptions.dart';
import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/core/storage/session_cleaner.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/data/models/amol_daily_dashboard_model.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/amol_local_projection.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/entities/amol_daily_dashboard.dart';
import 'package:tuhfatul_muslim/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:tuhfatul_muslim/features/dua/data/datasources/dua_reading_local_data_source.dart';
import 'package:tuhfatul_muslim/features/dua/data/datasources/dua_remote_data_source.dart';
import 'package:tuhfatul_muslim/features/dua/data/models/dua_api_models.dart';
import 'package:tuhfatul_muslim/features/dua/data/models/dua_plan_api_models.dart';
import 'package:tuhfatul_muslim/features/dua/data/repositories/dua_reading_repository_impl.dart';
import 'package:tuhfatul_muslim/features/dua/data/services/dua_offline_reading_progress_store.dart';
import 'package:tuhfatul_muslim/features/dua/data/services/dua_read_completion_store.dart';
import 'package:tuhfatul_muslim/features/dua/domain/dua_reading_points.dart';
import 'package:tuhfatul_muslim/features/dua/domain/repositories/dua_reading_repository.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/controllers/dua_reading_tracker.dart';

/// `POST /duas/reading/track` that fails with [fail] while it is set.
class _Remote implements DuaRemoteDataSource {
  final calls = <({String duaId, int seconds, String date})>[];
  Exception? fail;

  void goOffline() => fail = NetworkException();
  void goOnline() => fail = null;

  @override
  Future<void> trackReading({
    required String duaId,
    required int seconds,
    required String date,
  }) async {
    calls.add((duaId: duaId, seconds: seconds, date: date));
    final failure = fail;
    if (failure != null) throw failure;
  }

  @override
  Future<List<DuaFeaturedModel>> getFeatured() => throw UnimplementedError();

  @override
  Future<List<DuaCategoryModel>> getCategories() => throw UnimplementedError();

  @override
  Future<DuaPage> getByCategory(
    String categoryId, {
    int page = 1,
    int limit = 20,
  }) => throw UnimplementedError();

  @override
  Future<DuaFeaturedModel> getDuaById(String id) => throw UnimplementedError();

  @override
  Future<DuaPlanPage> getPlans({
    String? status,
    int page = 1,
    int limit = 10,
  }) => throw UnimplementedError();

  @override
  Future<DuaPlan> createPlan(DuaPlanDraft draft) => throw UnimplementedError();

  @override
  Future<DuaPlanDetail> getPlanDetail(String id) => throw UnimplementedError();

  @override
  Future<void> editPlan(String id, DuaPlanDraft draft) =>
      throw UnimplementedError();

  @override
  Future<void> deletePlan(String id) => throw UnimplementedError();
}

/// The repository as the reader's timer sees it: records what it is handed
/// without any storage or network of its own.
class _FakeRepository implements DuaReadingRepository {
  _FakeRepository({this.signedIn = true});

  bool signedIn;
  final tracked =
      <({String duaId, int seconds, String date, String? sessionId})>[];
  final drafts = <({String sessionId, int seconds})>[];
  final discarded = <String>[];
  final published = <({String sessionId, int seconds})>[];

  @override
  bool get isSignedIn => signedIn;

  @override
  Future<Either<Failure, void>> trackReading({
    required String duaId,
    required int seconds,
    required DateTime date,
    String? sessionId,
  }) async {
    tracked.add((
      duaId: duaId,
      seconds: seconds,
      date: _day(date),
      sessionId: sessionId,
    ));
    return const Right(null);
  }

  @override
  Future<void> saveReadingDraft({
    required String sessionId,
    required String duaId,
    required int seconds,
    required DateTime date,
  }) async => drafts.add((sessionId: sessionId, seconds: seconds));

  @override
  Future<void> discardReadingDraft(String sessionId) async =>
      discarded.add(sessionId);

  @override
  void publishReadingProgress({
    required String sessionId,
    required String duaId,
    required int seconds,
    required DateTime date,
  }) => published.add((sessionId: sessionId, seconds: seconds));

  @override
  Future<({int sent, int pending})> syncPendingReadings() async =>
      (sent: 0, pending: 0);
}

class _StubAdapter implements HttpClientAdapter {
  RequestOptions? request;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody.fromString(
      jsonEncode({'success': true, 'message': 'Read tracked', 'data': null}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _SignedInLocal implements AuthLocalDataSource {
  @override
  String? getToken() => 'test-token';

  @override
  bool get hasToken => true;

  @override
  Future<void> cacheToken(String token) async {}

  @override
  Future<void> clearToken() async {}
}

/// A clock the test moves by hand.
class _Clock {
  DateTime now = DateTime(2026, 10, 29, 9, 30);
  void advance(int seconds) => now = now.add(Duration(seconds: seconds));
}

String _day(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// What waits on the device, read as a later launch would.
Future<List<PendingDuaReading>> _saved() =>
    DuaReadingLocalDataSourceImpl().pending();

DuaReadingRepositoryImpl _repository(
  _Remote remote, {
  String? launch,
  DuaOfflineReadingProgressStore? offlineProgress,
}) => DuaReadingRepositoryImpl(
  remote,
  local: DuaReadingLocalDataSourceImpl(),
  isSignedIn: () => true,
  launch: launch,
  offlineProgress: offlineProgress,
);

Future<Either<Failure, void>> _track(
  DuaReadingRepositoryImpl repository, {
  int seconds = 300,
  String? sessionId,
}) => repository.trackReading(
  duaId: 'dua-1',
  seconds: seconds,
  date: DateTime(2026, 10, 29, 9, 30),
  sessionId: sessionId,
);

DuaReadingTracker _tracker(
  DuaReadingRepository repository,
  _Clock clock, {
  Duration? saveEvery,
  DuaReadCompletionStore? completion,
}) => DuaReadingTracker(
  repository,
  duaId: 'dua-1',
  now: () => clock.now,
  saveEvery: saveEvery,
  completion: completion ?? DuaReadCompletionStore(),
);

/// `GET /amol/tracker/daily`'s payload for [date] as the live API sends it,
/// with the Dua pillar reporting [duaMinutes] in its own `entry` block (half
/// a point per five minutes, one point at most).
AmolDailyDashboard _amolDay(String date, {int duaMinutes = 0}) {
  final duaPoints = ((duaMinutes ~/ 5).clamp(0, 2)) * 0.5;
  return AmolDailyDashboardModel.fromJson({
    'dateFormatted': '17 Jumada al-Ula',
    'dateIso': date,
    'earnedPoints': duaPoints,
    'maxPoints': 10,
    'completionPercentage': duaPoints / 10 * 100,
    'summary': {
      'totalEarnedPoints': duaPoints,
      'totalPossiblePoints': 10,
      'percentage': duaPoints / 10 * 100,
      'pointsText': 'Point : $duaPoints/10',
    },
    'pillars': [
      {
        'pillarKey': 'dua',
        'title': 'Dua',
        'titleBn': 'দোয়া',
        'earnedPoints': duaPoints,
        'maxPoints': 1,
        'percentage': duaPoints / 1 * 100,
        'formattedSubtext': '$duaPoints/1',
        'items': [
          {
            'itemKey': 'dua_reading',
            'title': 'Dua',
            'titleBn': 'দোয়া',
            'points': duaPoints,
            'maxPoints': 1,
            'isCompleted': false,
            'entry': {
              'unit': 'minutes',
              'entrySize': 5,
              'entryPoints': 0.5,
              'maxEntries': 2,
              'entries': duaMinutes ~/ 5,
              'amount': duaMinutes,
              'targetAmount': 10,
            },
          },
        ],
      },
    ],
  });
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('the points rule', () {
    test('half a point per five minutes, one point a day at most', () {
      expect(duaReadingPointsForSeconds(0), 0);
      expect(duaReadingPointsForSeconds(29), 0);
      expect(duaReadingPointsForSeconds(4 * 60 + 59), 0);
      expect(duaReadingPointsForSeconds(5 * 60), 0.5);
      expect(duaReadingPointsForSeconds(9 * 60), 0.5);
      expect(duaReadingPointsForSeconds(10 * 60), 1);
      // Nothing more is earned past ten minutes.
      expect(duaReadingPointsForSeconds(45 * 60), kDuaReadingMaxDailyPoints);
    });

    test('short visits spread over a day earn the same as one long one', () {
      // 30 + 40 + 230 seconds of separate visits is five minutes of reading,
      // so the day owes half a point: the rule is applied to the total, not
      // to each visit.
      expect(duaReadingPointsForSeconds(30 + 40 + 230), 0.5);
    });
  });

  group('reporting a visit', () {
    test('an online visit is sent once and nothing is left waiting', () async {
      final remote = _Remote();
      final result = await _track(_repository(remote), seconds: 300);

      expect(result.isRight(), isTrue);
      expect(remote.calls, [
        (duaId: 'dua-1', seconds: 300, date: '2026-10-29'),
      ]);
      expect(await _saved(), isEmpty);
    });

    test('a visit read offline waits on the device, then is sent', () async {
      final remote = _Remote()..goOffline();
      final repository = _repository(remote);

      final result = await _track(repository, seconds: 120);
      expect(result.isLeft(), isTrue);
      final waiting = await _saved();
      expect(waiting.single.seconds, 120);
      expect(waiting.single.duaId, 'dua-1');
      expect(waiting.single.date, '2026-10-29');

      remote.goOnline();
      expect(await repository.syncPendingReadings(), (sent: 1, pending: 0));
      expect(remote.calls, hasLength(2));
      expect(await _saved(), isEmpty);
    });

    test('the same visit is never reported twice at once', () async {
      final remote = _Remote();
      final repository = _repository(remote);

      final results = await Future.wait([
        _track(repository, seconds: 300, sessionId: 'visit-1'),
        _track(repository, seconds: 300, sessionId: 'visit-1'),
      ]);

      expect(remote.calls, hasLength(1));
      expect(results.where((r) => r.isLeft()), hasLength(1));
    });

    test(
      'a report the server refuses is dropped, not retried for ever',
      () async {
        final remote = _Remote()
          ..fail = ServerException('Dua not found', statusCode: 404);
        final repository = _repository(remote);

        await _track(repository, seconds: 300);

        expect(await _saved(), isEmpty);
        expect(await repository.syncPendingReadings(), (sent: 0, pending: 0));
        expect(remote.calls, hasLength(1));
      },
    );

    test('a draft left by an earlier launch is sent on the next one', () async {
      final remote = _Remote();
      final earlier = _repository(remote, launch: 'launch-1');
      await earlier.saveReadingDraft(
        sessionId: 'visit-1',
        duaId: 'dua-1',
        seconds: 240,
        date: DateTime(2026, 10, 28, 22, 10),
      );
      // Its own launch leaves the draft alone: that visit may still be open.
      expect(await earlier.syncPendingReadings(), (sent: 0, pending: 0));
      expect(remote.calls, isEmpty);

      final next = _repository(remote, launch: 'launch-2');
      expect(await next.syncPendingReadings(), (sent: 1, pending: 0));
      expect(remote.calls, [
        (duaId: 'dua-1', seconds: 240, date: '2026-10-28'),
      ]);
      expect(await _saved(), isEmpty);
    });

    test('nothing is sent for a guest', () async {
      final remote = _Remote();
      final repository = DuaReadingRepositoryImpl(
        remote,
        local: DuaReadingLocalDataSourceImpl(),
        isSignedIn: () => false,
      );

      await repository.saveReadingDraft(
        sessionId: 'visit-1',
        duaId: 'dua-1',
        seconds: 300,
        date: DateTime(2026, 10, 29),
      );

      expect(await _saved(), isEmpty);
      expect(await repository.syncPendingReadings(), (sent: 0, pending: 0));
      expect(remote.calls, isEmpty);
    });

    test('the request is a POST of duaId, seconds and date', () async {
      final adapter = _StubAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1'))
        ..httpClientAdapter = adapter;
      final source = DuaRemoteDataSourceImpl(dio: dio, local: _SignedInLocal());

      await source.trackReading(
        duaId: 'dua-1',
        seconds: 300,
        date: '2026-10-29',
      );

      expect(adapter.request?.method, 'POST');
      expect(adapter.request?.path, '/duas/reading/track');
      expect(adapter.request?.data, {
        'duaId': 'dua-1',
        'seconds': 300,
        'date': '2026-10-29',
      });
      expect(adapter.request?.headers['Authorization'], 'Bearer test-token');
    });
  });

  group('the reader timer', () {
    test('a visit under half a minute is not reported', () async {
      final repository = _FakeRepository();
      final clock = _Clock();
      final tracker = _tracker(repository, clock)..start();

      clock.advance(25);
      expect(tracker.elapsedSeconds, 25);
      expect(tracker.canComplete, isFalse);

      await tracker.finish();
      expect(repository.tracked, isEmpty);
      // And no later launch may send it either.
      expect(repository.discarded, hasLength(1));
      tracker.dispose();
    });

    test('the checkbox reports the visit once and stops the timer', () async {
      final repository = _FakeRepository();
      final clock = _Clock();
      final tracker = _tracker(repository, clock)..start();

      clock.advance(40);
      expect(tracker.canComplete, isTrue);
      expect(await tracker.complete(), isTrue);

      expect(repository.tracked.single.seconds, 40);
      expect(repository.tracked.single.duaId, 'dua-1');
      expect(repository.tracked.single.date, '2026-10-29');
      expect(tracker.isCompleted, isTrue);
      expect(tracker.isRunning, isFalse);

      // The timer has stopped for good, and leaving afterwards adds nothing.
      clock.advance(120);
      expect(tracker.elapsedSeconds, 40);
      await tracker.finish();
      expect(repository.tracked, hasLength(1));
      tracker.dispose();
    });

    test('leaving the screen reports the visit on its own', () async {
      final repository = _FakeRepository();
      final clock = _Clock();
      final tracker = _tracker(repository, clock)..start();

      clock.advance(90);
      await tracker.finish();

      expect(repository.tracked.single.seconds, 90);
      expect(repository.discarded, isEmpty);
      tracker.dispose();
    });

    test(
      'a second visit starts from zero and reports only its own time',
      () async {
        final repository = _FakeRepository();
        final clock = _Clock();

        final first = _tracker(repository, clock)..start();
        clock.advance(70);
        await first.finish();
        first.dispose();

        final second = _tracker(repository, clock)..start();
        expect(second.elapsedSeconds, 0);
        clock.advance(45);
        await second.finish();
        second.dispose();

        expect([for (final call in repository.tracked) call.seconds], [70, 45]);
        // Two reports, two ids: the second can never replace the first.
        expect(
          repository.tracked.first.sessionId,
          isNot(repository.tracked.last.sessionId),
        );
      },
    );

    test('time in the background is not reading time', () async {
      final repository = _FakeRepository();
      final clock = _Clock();
      final tracker = _tracker(repository, clock)..start();

      clock.advance(20);
      tracker.pause();
      clock.advance(600);
      tracker.resume();
      clock.advance(15);

      expect(tracker.elapsedSeconds, 35);
      await tracker.finish();
      expect(repository.tracked.single.seconds, 35);
      tracker.dispose();
    });

    test('a guest reads without anything being reported', () async {
      final repository = _FakeRepository(signedIn: false);
      final clock = _Clock();
      final tracker = _tracker(repository, clock)..start();

      clock.advance(60);
      // The checkbox is offered, but checking it cannot mark the dua read:
      // the screen asks the guest to sign in instead.
      expect(tracker.canComplete, isTrue);
      expect(await tracker.complete(), isFalse);
      await tracker.finish();

      expect(tracker.isCompleted, isFalse);
      expect(repository.tracked, isEmpty);
      expect(repository.drafts, isEmpty);
      tracker.dispose();
    });

    test(
      'the visit is saved on the device while it is still being read',
      () async {
        final repository = _FakeRepository();
        final clock = _Clock();
        final tracker = _tracker(repository, clock)..start();

        clock.advance(45);
        await tracker.saveDraft();

        expect(repository.drafts.single.seconds, 45);
        // The draft and the report share one id, so the report replaces it.
        await tracker.finish();
        expect(
          repository.tracked.single.sessionId,
          repository.drafts.single.sessionId,
        );
        tracker.dispose();
      },
    );
  });

  group('the Amol projection', () {
    test('offline dua time earns half a point at five minutes', () {
      final projected = projectOfflineDuaReading(
        _amolDay('2026-10-29'),
        additionalSeconds: 5 * 60,
      );

      final dua = projected.pillars.single;
      expect(dua.earnedPoints, 0.5);
      expect(dua.entry?.amount, 5);
      expect(dua.formattedSubtext, '0.5/1');
      expect(projected.summary.pointsText, 'Point : 0.5/10');
    });

    test('a visit crosses a boundary the day had already part of', () {
      // Four minutes are recorded, one more is read offline: together they
      // are the five minutes that earn the half point.
      final projected = projectOfflineDuaReading(
        _amolDay('2026-10-29', duaMinutes: 4),
        additionalSeconds: 60,
      );

      expect(projected.pillars.single.earnedPoints, 0.5);
      expect(projected.pillars.single.entry?.amount, 5);
    });

    test('ten minutes earn the full point, and more earns nothing', () {
      final full = projectOfflineDuaReading(
        _amolDay('2026-10-29'),
        additionalSeconds: 10 * 60,
      );
      expect(full.pillars.single.earnedPoints, 1);
      expect(full.pillars.single.entry?.amount, 10);

      final beyond = projectOfflineDuaReading(
        _amolDay('2026-10-29', duaMinutes: 10),
        additionalSeconds: 20 * 60,
      );
      expect(beyond.pillars.single.earnedPoints, kDuaReadingMaxDailyPoints);
    });

    test('a day with nothing read locally is left as the server sent it', () {
      final server = _amolDay('2026-10-29', duaMinutes: 7);
      final projected = projectOfflineDuaReading(server, additionalSeconds: 0);

      expect(projected.pillars.single.earnedPoints, 0.5);
      expect(projected.pillars.single.entry?.amount, 7);
    });
  });

  group('the local projection store', () {
    test('sums the day and drops what the server already counts', () async {
      final store = DuaOfflineReadingProgressStore(
        DuaReadingLocalDataSourceImpl(),
      );
      const today = '2026-10-29';
      store.upsert(
        const PendingDuaReading(
          id: 'a',
          duaId: 'dua-1',
          seconds: 120,
          date: today,
        ),
      );
      store.upsert(
        const PendingDuaReading(
          id: 'b',
          duaId: 'dua-2',
          seconds: 200,
          date: today,
        ),
      );
      store.upsert(
        const PendingDuaReading(
          id: 'c',
          duaId: 'dua-3',
          seconds: 60,
          date: '2026-10-28',
        ),
      );

      expect(store.secondsFor(today), 320);

      store.markAcknowledged(
        const PendingDuaReading(
          id: 'a',
          duaId: 'dua-1',
          seconds: 120,
          date: today,
        ),
      );
      expect(store.acknowledgedIdsFor(today), {'a'});
      // Still counted until a fresh daily response contains it.
      expect(store.secondsFor(today), 320);
      expect(store.secondsFor(today, acknowledgedInBaseline: const {'a'}), 200);

      store.remove('b');
      expect(store.secondsFor(today, acknowledgedInBaseline: const {'a'}), 0);
    });

    test('a report of the previous launch is restored', () async {
      SharedPreferences.setMockInitialValues({
        DuaReadingLocalDataSourceImpl.key: jsonEncode([
          const PendingDuaReading(
            id: 'a',
            duaId: 'dua-1',
            seconds: 150,
            date: '2026-10-29',
          ).toJson(),
        ]),
      });

      final store = DuaOfflineReadingProgressStore(
        DuaReadingLocalDataSourceImpl(),
      );
      await store.restore();

      expect(store.secondsFor('2026-10-29'), 150);
    });
  });

  group('a dua stays read', () {
    test('the checkbox is remembered on the next visit', () async {
      final repository = _FakeRepository();
      final clock = _Clock();
      final completion = DuaReadCompletionStore();

      final first = _tracker(repository, clock, completion: completion)
        ..start();
      clock.advance(40);
      expect(await first.complete(), isTrue);
      await first.finish();
      first.dispose();

      // A later launch reads the same record from the device.
      final restored = DuaReadCompletionStore();
      await restored.restore();
      expect(restored.isCompleted('dua-1'), isTrue);
      expect(restored.secondsFor('dua-1'), 40);

      final second = _tracker(repository, clock, completion: restored)..start();
      expect(second.isCompleted, isTrue);
      expect(second.isRunning, isFalse);
      expect(second.canComplete, isFalse);
      // The duration that was recorded, not a timer starting again.
      expect(second.elapsedSeconds, 40);

      clock.advance(600);
      expect(second.elapsedSeconds, 40);
      await second.finish();
      second.dispose();

      // Only the first visit was ever reported.
      expect(repository.tracked, hasLength(1));
      expect(repository.drafts, isEmpty);
      expect(repository.discarded, isEmpty);
    });

    test('a record loaded after the screen opened stops the timer', () async {
      SharedPreferences.setMockInitialValues({
        DuaReadCompletionStore.key: '{"dua-1":95}',
      });
      final repository = _FakeRepository();
      final clock = _Clock();
      final completion = DuaReadCompletionStore();

      // Nothing is loaded yet: this is the first screen of a cold start.
      final tracker = _tracker(repository, clock, completion: completion)
        ..start();
      await completion.restore();
      await Future<void>.delayed(Duration.zero);

      expect(tracker.isCompleted, isTrue);
      expect(tracker.isRunning, isFalse);
      expect(tracker.elapsedSeconds, 95);

      clock.advance(300);
      await tracker.finish();
      tracker.dispose();
      expect(repository.tracked, isEmpty);
      expect(repository.discarded, isEmpty);
    });

    test('leaving without checking the box leaves it unchecked', () async {
      final repository = _FakeRepository();
      final clock = _Clock();
      final completion = DuaReadCompletionStore();

      final tracker = _tracker(repository, clock, completion: completion)
        ..start();
      clock.advance(90);
      await tracker.finish();
      tracker.dispose();

      // The visit counts towards the day, but the dua is not marked read.
      expect(repository.tracked.single.seconds, 90);
      expect(completion.isCompleted('dua-1'), isFalse);
      final restored = DuaReadCompletionStore();
      await restored.restore();
      expect(restored.isCompleted('dua-1'), isFalse);
    });

    test('nothing is remembered when the report was refused', () async {
      final repository = _FakeRepository(signedIn: false);
      final clock = _Clock();
      final completion = DuaReadCompletionStore();

      final tracker = _tracker(repository, clock, completion: completion)
        ..start();
      clock.advance(60);
      expect(await tracker.complete(), isFalse);
      tracker.dispose();

      expect(completion.isCompleted('dua-1'), isFalse);
    });

    test('one dua marked read never erases another', () async {
      SharedPreferences.setMockInitialValues({
        DuaReadCompletionStore.key: '{"dua-9":120}',
      });
      final store = DuaReadCompletionStore();
      await store.markCompleted('dua-1', seconds: 45);

      final restored = DuaReadCompletionStore();
      await restored.restore();
      expect(restored.secondsFor('dua-9'), 120);
      expect(restored.secondsFor('dua-1'), 45);
    });

    test('an unreadable record simply leaves every dua unread', () async {
      SharedPreferences.setMockInitialValues({
        DuaReadCompletionStore.key: 'not json',
      });
      final store = DuaReadCompletionStore();
      await store.restore();
      expect(store.isRestored, isTrue);
      expect(store.isCompleted('dua-1'), isFalse);
    });

    test('signing out forgets which duas were read', () async {
      expect(SessionCleaner.userPrefKeys, contains(DuaReadCompletionStore.key));

      final store = DuaReadCompletionStore();
      await store.markCompleted('dua-1', seconds: 45);
      store.clear();
      expect(store.isCompleted('dua-1'), isFalse);

      // The next session reads the key the cleaner emptied.
      SharedPreferences.setMockInitialValues({});
      await store.restore();
      expect(store.isCompleted('dua-1'), isFalse);
    });
  });

  test('signing out clears the dua reading still waiting', () {
    expect(
      SessionCleaner.userPrefKeys,
      contains(DuaReadingLocalDataSourceImpl.key),
    );
  });
}
