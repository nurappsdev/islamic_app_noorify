import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuhfatul_muslim/core/errors/exceptions.dart';
import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:tuhfatul_muslim/features/quran/data/datasources/quran_reading_remote_data_source.dart';
import 'package:tuhfatul_muslim/features/quran/data/repositories/quran_reading_repository_impl.dart';
import 'package:tuhfatul_muslim/features/quran/data/services/quran_local_store.dart';
import 'package:tuhfatul_muslim/features/quran/domain/quran_last_read.dart';
import 'package:tuhfatul_muslim/features/quran/domain/quran_reading_dashboard.dart';
import 'package:tuhfatul_muslim/features/quran/domain/quran_reading_history.dart';
import 'package:tuhfatul_muslim/features/quran/domain/quran_reading_progress.dart';
import 'package:tuhfatul_muslim/features/quran/domain/repositories/quran_reading_repository.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/bloc/last_read/last_read_bloc.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/bloc/quran_reading_dashboard/quran_reading_dashboard_cubit.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/controllers/quran_reading_tracker.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/widgets/dashboard/quran_period_dropdown.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tuhfatul_muslim/features/quran/data/services/quran_audio_downloader.dart';
import 'package:tuhfatul_muslim/features/quran/data/services/quran_audio_handler.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/bloc/offline_quran/offline_quran_bloc.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/bloc/reciter/reciter_bloc.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/bloc/surah_audio_download/surah_audio_download_bloc.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/bloc/surah_playback/surah_playback_bloc.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/quran_route_args.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/screens/quran_reading_screen.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/screens/surah_list_screen.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';

import 'quran_content_test.dart' as content;
import 'quran_playback_test.dart' show TestAudio, TestDownloader;

// ---------------------------------------------------------------------------
// Fixtures, shaped like the backend's quran_reading.service responses.
// ---------------------------------------------------------------------------

Map<String, Object?> _day(String date, {int seconds = 720, int ayahs = 40}) => {
  'date': date,
  'readSeconds': seconds,
  'readMinutes': seconds / 60,
  'goalSeconds': 2640,
  'goalMinutes': 44,
  'remainingSeconds': 2640 - seconds,
  'remainingMinutes': (2640 - seconds) / 60,
  'points': 3,
  'maxPoints': 11,
  'percentage': 27,
  'isGoalMet': false,
  'ayahsRead': ayahs,
  'pointsText': 'Point : 3/11',
  'progressText': '12/44 min',
};

Map<String, Object?> _ayah(int surah, int ayah) => {
  'surahNumber': surah,
  'ayahNumber': ayah,
  'ayahKey': '$surah:$ayah',
  'paraNumber': 1,
  'surahNameEnglish': 'Al-Baqarah',
  'surahNameBangla': 'আল-বাকারা',
  'surahNameArabic': 'البقرة',
};

Map<String, Object?> _history({int days = 7}) => {
  'from': '2026-09-23',
  'to': '2026-09-29',
  'days': [for (var i = 0; i < days; i++) _day('2026-09-${(23 + i) % 30 + 1}')],
  'totals': {
    'totalSeconds': 5040,
    'totalMinutes': 84,
    'totalPoints': 21,
    'maxPoints': 77,
    'totalAyahs': 280,
    'daysTracked': 7,
    'daysGoalMet': 2,
    'currentStreak': 1,
    'averageMinutesPerDay': 12,
  },
};

Map<String, Object?> _lastRead({
  String lastReadAt = '2026-09-29T08:30:00.000Z',
}) => {
  '_id': 'p1',
  'userId': 'u1',
  'ayahIndex': 27,
  'surahNumber': 2,
  'ayahNumber': 20,
  'paraNumber': 1,
  'readSeconds': 15,
  'sessionCount': 2,
  'isRead': true,
  'firstReadAt': '2026-09-20T08:00:00.000Z',
  'lastReadAt': lastReadAt,
  'completedAt': '2026-09-20T08:00:03.000Z',
  'createdAt': '2026-09-20T08:00:00.000Z',
  'updatedAt': lastReadAt,
  'ayahKey': '2:20',
  'surahNameEnglish': 'Al-Baqarah',
  'surahNameBangla': 'আল-বাকারা',
  'surahNameArabic': 'البقرة',
  'readMinutes': 0.3,
};

final _trackData = {
  'daily': _day('2026-09-29'),
  'trackedAyahs': 20,
  'newlyReadAyahs': 18,
  'from': _ayah(2, 1),
  'to': _ayah(2, 20),
  'ayahs': [
    {
      'surahNumber': 2,
      'ayahNumber': 1,
      'readSeconds': 15,
      'sessionCount': 1,
      'isRead': true,
    },
  ],
  'progress': {
    'surahs': [
      {
        'surahNumber': 2,
        'nameEnglish': 'Al-Baqarah',
        'nameBangla': 'আল-বাকারা',
        'totalAyahs': 286,
        'readAyahs': 20,
        'remainingAyahs': 266,
        'percentage': 7,
        'isCompleted': false,
      },
    ],
    'paras': [
      {
        'paraNumber': 1,
        'totalAyahs': 148,
        'readAyahs': 20,
        'remainingAyahs': 128,
        'percentage': 14,
        'isCompleted': false,
      },
    ],
    'quran': {
      'totalAyahs': 6236,
      'readAyahs': 20,
      'remainingAyahs': 6216,
      'percentage': 0,
      'isCompleted': false,
    },
  },
};

final _dashboardData = {
  'today': {
    ..._day('2026-09-29'),
    'dailyTotalPoints': 18.5,
    'dailyTotalMaxPoints': 40,
  },
  'week': _history(),
  'completion': {
    'totalAyahs': 6236,
    'readAyahs': 20,
    'percentage': 0,
    'surahsCompleted': 1,
    'totalSurahs': 114,
    'parasCompleted': 0,
    'totalParas': 30,
    'nextAyah': _ayah(2, 21),
  },
  'lastRead': _lastRead(),
  'continueFrom': _ayah(2, 21),
  'plans': {'inProgress': 2, 'completed': 1},
};

final _comparisonData = {
  'from': '2026-09-23',
  'to': '2026-09-29',
  'comparedWith': 'first_place',
  'users': [
    {
      'key': 'user1',
      'rank': 5,
      'isCurrentUser': true,
      'userId': 'u1',
      'name': 'Me',
      'totalPoints': 120,
      ..._history(),
    },
    {
      'key': 'user2',
      'rank': 1,
      'isCurrentUser': false,
      'userId': 'u2',
      'name': 'Abdul Bari',
      'avatarUrl': null,
      'totalPoints': 400.5,
      ..._history(),
    },
  ],
  'difference': {
    'totalPoints': -7,
    'totalMinutes': -20.5,
    'totalAyahs': -40,
    'daysGoalMet': -1,
    'isAhead': false,
  },
};

Map<String, Object?> _ok(Object data) => {
  'statusCode': 200,
  'success': true,
  'message': 'ok',
  'data': data,
};

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

/// Answers every request with [body], and remembers the requests.
class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.body, {this.status = 200});

  Object body;
  int status;
  DioExceptionType? fail;
  final requests = <RequestOptions>[];

  RequestOptions get last => requests.last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final failure = fail;
    if (failure != null) {
      throw DioException(requestOptions: options, type: failure);
    }
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

({QuranReadingRemoteDataSourceImpl source, _StubAdapter http}) _remote(
  Object body, {
  int status = 200,
}) {
  final http = _StubAdapter(body, status: status);
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://example.test/api/v1',
      validateStatus: (s) => s != null && s < 500,
    ),
  )..httpClientAdapter = http;
  return (
    source: QuranReadingRemoteDataSourceImpl(
      dio: dio,
      local: _FakeLocal('tkn'),
    ),
    http: http,
  );
}

typedef _Track = ({int surah, int from, int to, int seconds, DateTime date});

/// A repository that records tracks and serves canned reads.
class _FakeRepository implements QuranReadingRepository {
  _FakeRepository({this.signedIn = true});

  bool signedIn;
  final tracks = <_Track>[];
  Completer<void>? holdTrack;
  bool failTrack = false;
  Either<Failure, QuranLastRead> lastRead = Right(
    QuranLastRead.fromJson({'lastRead': null, 'continueFrom': _ayah(1, 1)}),
  );
  final historyWindows = <({int days, DateTime? from, DateTime? to})>[];
  final _tracked = StreamController<void>.broadcast();

  @override
  bool get isSignedIn => signedIn;

  @override
  Stream<void> get onReadingTracked => _tracked.stream;

  @override
  Future<Either<Failure, QuranReadingTrackResult>> trackReading({
    required int surahNumber,
    required int fromAyah,
    required int toAyah,
    required int seconds,
    required DateTime date,
  }) async {
    tracks.add((
      surah: surahNumber,
      from: fromAyah,
      to: toAyah,
      seconds: seconds,
      date: date,
    ));
    await holdTrack?.future;
    if (failTrack) return const Left(NetworkFailure());
    _tracked.add(null);
    return Right(QuranReadingTrackResult.fromJson(_trackData));
  }

  @override
  Future<Either<Failure, QuranReadingDashboard>> getDashboard() async =>
      Right(QuranReadingDashboard.fromJson(_dashboardData));

  @override
  Future<Either<Failure, QuranReadingHistory>> getReadingHistory({
    int days = kQuranReadingHistoryDays,
    DateTime? from,
    DateTime? to,
  }) async {
    historyWindows.add((days: days, from: from, to: to));
    return Right(QuranReadingHistory.fromJson(_history(days: days)));
  }

  @override
  Future<Either<Failure, QuranReadingComparison>> getReadingComparison({
    int days = kQuranReadingHistoryDays,
    DateTime? from,
    DateTime? to,
  }) async => Right(QuranReadingComparison.fromJson(_comparisonData));

  @override
  Future<Either<Failure, QuranLastRead>> getLastRead() async => lastRead;
}

/// Audio already on the device, without touching the database.
class _Downloader extends TestDownloader {
  @override
  Future<AudioDownloadProgress> surahStatus({
    required int reciterId,
    required int surahNo,
    required int totalAyah,
  }) async => AudioDownloadProgress(totalAyah, totalAyah);
}

/// A clock the test moves by hand.
class _Clock {
  DateTime now = DateTime(2026, 9, 29, 10);
  void advance(int seconds) => now = now.add(Duration(seconds: seconds));
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  group('parsing', () {
    test('track response', () {
      final result = QuranReadingTrackResult.fromJson(_trackData);
      expect(result.daily.readSeconds, 720);
      expect(result.daily.readMinutes, 12);
      expect(result.daily.goalMinutes, 44);
      expect(result.daily.points, 3);
      expect(result.daily.date, DateTime(2026, 9, 29));
      expect(result.trackedAyahs, 20);
      expect(result.newlyReadAyahs, 18);
      expect(result.from?.ayahKey, '2:1');
      expect(result.to?.ayahNumber, 20);
      expect(result.ayahs.single.sessionCount, 1);
      expect(result.surahs.single.nameBangla, 'আল-বাকারা');
      expect(result.surahs.single.remainingAyahs, 266);
      expect(result.paras.single.paraNumber, 1);
      expect(result.quran.totalAyahs, 6236);
    });

    test('dashboard response', () {
      final dashboard = QuranReadingDashboard.fromJson(_dashboardData);
      expect(dashboard.today.dailyTotalPoints, 18.5);
      expect(dashboard.today.dailyTotalMaxPoints, 40);
      expect(dashboard.week.days, hasLength(7));
      expect(dashboard.week.totals.currentStreak, 1);
      expect(dashboard.week.totals.averageMinutesPerDay, 12);
      expect(dashboard.completion.surahsCompleted, 1);
      expect(dashboard.completion.totalParas, 30);
      expect(dashboard.completion.nextAyah?.ayahKey, '2:21');
      expect(dashboard.lastRead?.id, 'p1');
      expect(dashboard.lastRead?.lastReadAt, DateTime.utc(2026, 9, 29, 8, 30));
      expect(dashboard.continueFrom?.ayahNumber, 21);
      expect(dashboard.plans.inProgress, 2);
    });

    test('history and comparison responses', () {
      final history = QuranReadingHistory.fromJson(_history());
      expect(history.from, DateTime(2026, 9, 23));
      expect(history.totals.daysGoalMet, 2);

      final comparison = QuranReadingComparison.fromJson(_comparisonData);
      expect(comparison.comparedWith, 'first_place');
      expect(comparison.currentUser?.rank, 5);
      expect(comparison.competitor?.name, 'Abdul Bari');
      expect(comparison.competitor?.avatarUrl, isNull);
      expect(comparison.competitor?.totalPoints, 400.5);
      expect(comparison.competitor?.days, hasLength(7));
      expect(comparison.difference?.totalMinutes, -20.5);
      expect(comparison.difference?.isAhead, isFalse);
    });

    test('comparison with nobody to compare against', () {
      final solo = QuranReadingComparison.fromJson({
        ..._comparisonData,
        'comparedWith': null,
        'users': [(_comparisonData['users']! as List).first],
        'difference': null,
      });
      expect(solo.comparedWith, isNull);
      expect(solo.competitor, isNull);
      expect(solo.difference, isNull);
    });

    test('last-read response, before and after any reading', () {
      final read = QuranLastRead.fromJson({
        'lastRead': _lastRead(),
        'continueFrom': _ayah(2, 21),
      });
      expect(read.lastRead?.ayahKey, '2:20');
      expect(read.lastRead?.readMinutes, 0.3);
      expect(read.lastRead?.completedAt, isNotNull);
      expect(read.continueFrom?.ayahNumber, 21);

      final fresh = QuranLastRead.fromJson({
        'lastRead': null,
        'continueFrom': _ayah(1, 1),
      });
      expect(fresh.lastRead, isNull);
      expect(fresh.continueFrom?.surahNumber, 1);
    });
  });

  group('remote data source', () {
    test('track sends the session with the login token', () async {
      final setup = _remote(_ok(_trackData));
      final result = await setup.source.trackReading(
        surahNumber: 2,
        fromAyah: 1,
        toAyah: 20,
        seconds: 300,
        date: '2026-09-29',
      );
      expect(setup.http.last.method, 'POST');
      expect(setup.http.last.path, '/quran/reading/track');
      expect(setup.http.last.headers['Authorization'], 'Bearer tkn');
      expect(setup.http.last.data, {
        'surahNumber': 2,
        'fromAyah': 1,
        'toAyah': 20,
        'seconds': 300,
        'date': '2026-09-29',
      });
      expect(result.trackedAyahs, 20);
    });

    test('history and comparison take a configurable window', () async {
      final setup = _remote(_ok(_history(days: 30)));
      final history = await setup.source.getHistory(days: 30);
      expect(setup.http.last.path, '/quran/reading/history');
      expect(setup.http.last.queryParameters, {'days': 30});
      expect(history.days, hasLength(30));

      setup.http.body = _ok(_comparisonData);
      await setup.source.getComparison(
        days: 7,
        from: '2026-09-01',
        to: '2026-09-07',
      );
      expect(setup.http.last.path, '/quran/reading/history/compare');
      expect(setup.http.last.queryParameters, {
        'days': 7,
        'from': '2026-09-01',
        'to': '2026-09-07',
      });
    });

    test('dashboard and last read', () async {
      final setup = _remote(_ok(_dashboardData));
      expect((await setup.source.getDashboard()).plans.completed, 1);
      expect(setup.http.last.path, '/quran/reading/dashboard');
      expect(setup.http.last.method, 'GET');

      setup.http.body = _ok({
        'lastRead': _lastRead(),
        'continueFrom': _ayah(2, 21),
      });
      expect((await setup.source.getLastRead()).lastRead?.ayahNumber, 20);
      expect(setup.http.last.path, '/quran/reading/last-read');
    });

    test(
      'maps 401 / 404 / 422 / 500, timeouts, offline and bad bodies',
      () async {
        for (final status in [401, 403, 404, 422]) {
          final setup = _remote({
            'success': false,
            'message': 'Nope $status',
            'errorSources': [],
          }, status: status);
          await expectLater(
            setup.source.getDashboard(),
            throwsA(
              isA<ServerException>()
                  .having((e) => e.statusCode, 'status', status)
                  .having((e) => e.message, 'message', 'Nope $status'),
            ),
          );
        }

        final server = _remote({'success': false}, status: 500);
        await expectLater(
          server.source.getDashboard(),
          throwsA(isA<ServerException>()),
        );

        final slow = _remote(_ok(_dashboardData))
          ..http.fail = DioExceptionType.receiveTimeout;
        await expectLater(
          slow.source.getDashboard(),
          throwsA(isA<NetworkException>()),
        );
        final offline = _remote(_ok(_dashboardData))
          ..http.fail = DioExceptionType.connectionError;
        await expectLater(
          offline.source.getDashboard(),
          throwsA(isA<NetworkException>()),
        );

        final malformed = _remote({'success': true, 'data': 'oops'});
        await expectLater(
          malformed.source.getDashboard(),
          throwsA(isA<ParsingException>()),
        );
      },
    );
  });

  group('repository', () {
    test(
      'caches reads, shares requests in flight, clears after a track',
      () async {
        final setup = _remote(_ok(_dashboardData));
        final repository = QuranReadingRepositoryImpl(
          setup.source,
          isSignedIn: () => true,
        );
        final tracked = <void>[];
        final sub = repository.onReadingTracked.listen(tracked.add);
        addTearDown(sub.cancel);

        final together = await Future.wait([
          repository.getDashboard(),
          repository.getDashboard(),
        ]);
        expect(together.every((r) => r.isRight()), isTrue);
        expect(setup.http.requests, hasLength(1));
        await repository.getDashboard();
        expect(setup.http.requests, hasLength(1), reason: 'served from cache');

        setup.http.body = _ok(_trackData);
        final result = await repository.trackReading(
          surahNumber: 2,
          fromAyah: 1,
          toAyah: 20,
          seconds: 300,
          date: DateTime(2026, 9, 5, 23, 59),
        );
        expect(result.isRight(), isTrue);
        expect((setup.http.last.data as Map)['date'], '2026-09-05');
        await _settle();
        expect(tracked, hasLength(1));

        setup.http.body = _ok(_dashboardData);
        await repository.getDashboard();
        expect(setup.http.requests, hasLength(3), reason: 'cache was cleared');
      },
    );

    test('turns failures into Failures and does not cache them', () async {
      final setup = _remote({
        'success': false,
        'message': 'Denied',
      }, status: 401);
      final repository = QuranReadingRepositoryImpl(
        setup.source,
        isSignedIn: () => true,
      );
      final first = await repository.getLastRead();
      expect(
        first.fold((f) => f, (_) => null),
        isA<ServerFailure>().having((f) => f.statusCode, 'status', 401),
      );
      await repository.getLastRead();
      expect(setup.http.requests, hasLength(2));
    });
  });

  group('reading tracker', () {
    late _Clock clock;
    late _FakeRepository repository;
    late QuranReadingTracker tracker;

    setUp(() {
      clock = _Clock();
      repository = _FakeRepository();
      tracker = QuranReadingTracker(repository, now: () => clock.now);
    });

    test('one report for consecutive pages of a Surah, on leaving', () async {
      tracker.show(2, 1, 5);
      clock.advance(120);
      tracker.show(2, 6, 12); // next page
      clock.advance(180);
      expect(repository.tracks, isEmpty);
      await tracker.dispose();
      expect(repository.tracks, hasLength(1));
      final track = repository.tracks.single;
      expect(
        [track.surah, track.from, track.to, track.seconds],
        [2, 1, 12, 300],
      );
      expect(track.date, DateTime(2026, 9, 29, 10));
    });

    test('background reports once; resume counts only new time', () async {
      tracker.show(2, 1, 20);
      clock.advance(300);
      await tracker.pause();
      expect(repository.tracks.single.seconds, 300);
      clock.advance(600); // in the background: not counted
      tracker.resume();
      clock.advance(60);
      await tracker.dispose();
      await tracker.dispose(); // twice: no duplicate
      expect([for (final t in repository.tracks) t.seconds], [300, 60]);
      expect(repository.tracks.last.from, 1);
    });

    test('overlapping flushes never send the same seconds twice', () async {
      repository.holdTrack = Completer<void>();
      tracker.show(1, 1, 7);
      clock.advance(90);
      final pausing = tracker.pause();
      final leaving = tracker.dispose();
      final flushing = tracker.flush();
      repository.holdTrack!.complete();
      await Future.wait([pausing, leaving, flushing]);
      expect(repository.tracks, hasLength(1));
      expect(repository.tracks.single.seconds, 90);
    });

    test('a jump elsewhere reports the session so far', () async {
      tracker.show(2, 1, 5);
      clock.advance(40);
      tracker.show(2, 250, 255); // jumped (filter)
      await _settle();
      expect(repository.tracks.single.to, 5);
      clock.advance(30);
      tracker.show(3, 1, 9); // another Surah
      await _settle();
      expect(repository.tracks.last.surah, 2);
      expect(repository.tracks.last.from, 250);
    });

    test('skips glances, signed-out readers; caps one report', () async {
      tracker.show(2, 1, 5);
      clock.advance(3);
      await tracker.flush();
      expect(repository.tracks, isEmpty);

      repository.signedIn = false;
      clock.advance(100);
      await tracker.flush();
      expect(repository.tracks, isEmpty);

      repository.signedIn = true;
      clock.advance(5000);
      await tracker.flush();
      expect(repository.tracks.single.seconds, 3600);
    });

    test('a failed report never breaks reading', () async {
      repository.failTrack = true;
      tracker.show(2, 1, 5);
      clock.advance(60);
      await tracker.flush();
      tracker.show(2, 6, 10);
      expect(tracker.debugSession?.to, 10);
    });
  });

  group('continue reading', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    Future<LastReadState> load(_FakeRepository repository) async {
      final store = await QuranLocalStore.create();
      await store.recordSurahOpened(
        surahNo: 1,
        surahName: 'Al-Fatiha',
        ayahNo: 3,
      );
      final bloc = LastReadBloc(store: store, repository: repository)
        ..add(const LoadLastRead());
      addTearDown(bloc.close);
      return bloc.stream
          .firstWhere((s) => !s.isLoading && s.entry != null)
          .then((_) async {
            await _settle();
            await _settle();
            return bloc.state;
          });
    }

    test('opens the ayah after the account\'s newer last read', () async {
      final repository = _FakeRepository()
        ..lastRead = Right(
          QuranLastRead.fromJson({
            'lastRead': _lastRead(
              lastReadAt: DateTime.now()
                  .add(const Duration(minutes: 5))
                  .toUtc()
                  .toIso8601String(),
            ),
            'continueFrom': _ayah(2, 21),
          }),
        );
      final state = await load(repository);
      expect(state.entry?.surahNo, 2);
      expect(state.entry?.ayahNo, 20);
      expect([state.target?.surahNo, state.target?.ayahNo], [2, 21]);
    });

    test('keeps the device\'s record when it is the latest', () async {
      final repository = _FakeRepository()
        ..lastRead = Right(
          QuranLastRead.fromJson({
            'lastRead': _lastRead(lastReadAt: '2020-01-01T00:00:00.000Z'),
            'continueFrom': _ayah(2, 21),
          }),
        );
      final state = await load(repository);
      expect([state.target?.surahNo, state.target?.ayahNo], [1, 3]);
    });

    test('signed out: the device\'s record only', () async {
      final state = await load(_FakeRepository(signedIn: false));
      expect([state.target?.surahNo, state.target?.ayahNo], [1, 3]);
    });
  });

  group('dashboard cubit', () {
    test('loads the dashboard with the period\'s history', () async {
      final repository = _FakeRepository();
      final cubit = QuranReadingDashboardCubit(repository);
      addTearDown(cubit.close);
      await cubit.load();
      expect(cubit.state.status, QuranReadingDashboardStatus.loaded);
      expect(cubit.state.dashboard?.completion.surahsCompleted, 1);
      expect(cubit.state.history?.days, hasLength(7));
      expect(cubit.state.comparison?.competitor?.name, 'Abdul Bari');
      expect(repository.historyWindows.last.days, 7);
    });

    test('a picked month asks for that calendar window', () async {
      final repository = _FakeRepository();
      final cubit = QuranReadingDashboardCubit(
        repository,
        now: () => DateTime(2026, 9, 29),
      );
      addTearDown(cubit.close);
      await cubit.selectPeriod(
        QuranDashboardPeriod.monthly,
        month: DateTime(2026, 8),
      );
      final window = repository.historyWindows.last;
      expect(window.from, DateTime(2026, 8));
      expect(window.to, DateTime(2026, 8, 31));
      expect(window.days, 31);

      await cubit.selectPeriod(
        QuranDashboardPeriod.monthly,
        month: DateTime(2026, 9),
      );
      expect(repository.historyWindows.last.to, DateTime(2026, 9, 29));
    });

    test('signed out asks to sign in without calling the API', () async {
      final repository = _FakeRepository(signedIn: false);
      final cubit = QuranReadingDashboardCubit(repository);
      addTearDown(cubit.close);
      await cubit.load();
      expect(cubit.state.status, QuranReadingDashboardStatus.signedOut);
      expect(repository.historyWindows, isEmpty);
    });

    test('reloads after a tracked reading', () async {
      final repository = _FakeRepository();
      final cubit = QuranReadingDashboardCubit(repository);
      addTearDown(cubit.close);
      await cubit.load();
      final before = repository.historyWindows.length;
      await repository.trackReading(
        surahNumber: 1,
        fromAyah: 1,
        toAyah: 7,
        seconds: 60,
        date: DateTime(2026, 9, 29),
      );
      await _settle();
      await _settle();
      expect(repository.historyWindows.length, greaterThan(before));
    });
  });

  group('in the app', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    testWidgets('the reader reports what was read on background and exit', (
      tester,
    ) async {
      final clock = _Clock();
      final repository = _FakeRepository();
      final tracker = QuranReadingTracker(repository, now: () => clock.now);
      final audio = TestAudio();
      quranAudioHandler = audio;
      addTearDown(audio.completed.close);
      final downloader = _Downloader();
      // Ayahs 1-5 are Mushaf page 2, the rest page 3.
      final adapter = content.Adapter((r) {
        if (r.path.endsWith('/translations')) return content.ok([]);
        if (!r.path.endsWith('/ayahs')) return content.ok(content.surah);
        final from = r.queryParameters['from'] as int;
        final to = r.queryParameters['to'] as int;
        return content.page([
          for (var n = from; n <= to; n++)
            {...content.ayah(n), 'pageNumber': n <= 5 ? 2 : 3},
        ]);
      });
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => LanguageBloc(initialLanguage: AppLanguage.english),
            ),
            BlocProvider(create: (_) => ReciterBloc()),
            BlocProvider(
              create: (_) =>
                  SurahPlaybackBloc(audio: audio, downloader: downloader),
            ),
            BlocProvider(
              create: (_) => SurahAudioDownloadBloc(downloader: downloader),
            ),
          ],
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (_, _) => MaterialApp(
              home: QuranReadingScreen(
                args: const SurahRouteArgs(surahNo: 2, surahName: 'Al-Baqarah'),
                contentService: content.service(adapter),
                readingTracker: tracker,
              ),
            ),
          ),
        ),
      );
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(tracker.debugSession?.to, 5);
      expect(repository.tracks, isEmpty, reason: 'nothing sent while reading');

      // Two minutes of reading, then the app goes to the background.
      clock.advance(120);
      // Devices step through each state on the way to the background.
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pump();
      expect(repository.tracks, hasLength(1));
      final first = repository.tracks.single;
      expect(
        [first.surah, first.from, first.to, first.seconds],
        [2, 1, 5, 120],
      );

      // Time in the background doesn't count; after coming back it does.
      clock.advance(900);
      for (final state in [
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pump();
      clock.advance(45);

      // Leaving the reader reports the rest, once.
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect([for (final t in repository.tracks) t.seconds], [120, 45]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Continue Reading opens the ayah after the last one read', (
      tester,
    ) async {
      final repository = _FakeRepository()
        ..lastRead = Right(
          QuranLastRead.fromJson({
            'lastRead': _lastRead(
              lastReadAt: DateTime.now().toUtc().toIso8601String(),
            ),
            'continueFrom': _ayah(2, 21),
          }),
        );
      SurahRouteArgs? opened;
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => LanguageBloc(initialLanguage: AppLanguage.english),
            ),
            BlocProvider(
              create: (_) =>
                  LastReadBloc(repository: repository)
                    ..add(const LoadLastRead()),
            ),
            BlocProvider(create: (_) => OfflineQuranBloc()),
          ],
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (_, _) => MaterialApp(
              home: const SurahListScreen(),
              onGenerateRoute: (settings) {
                opened = settings.arguments as SurahRouteArgs?;
                return MaterialPageRoute<void>(
                  builder: (_) => const Scaffold(),
                );
              },
            ),
          ),
        ),
      );
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      // The banner shows the last ayah read...
      expect(find.text('Al-Baqarah'), findsWidgets);
      await tester.tap(find.text('Al-Baqarah').first);
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      // ...and continues from the one after it.
      expect([opened?.surahNo, opened?.ayahNo], [2, 21]);
    });
  });
}
