import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dartz/dartz.dart' show Either;
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tuhfatul_muslim/core/errors/exceptions.dart';
import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:tuhfatul_muslim/features/quran/data/datasources/quran_reading_local_data_source.dart';
import 'package:tuhfatul_muslim/features/quran/data/datasources/quran_reading_remote_data_source.dart';
import 'package:tuhfatul_muslim/features/quran/data/repositories/quran_reading_repository_impl.dart';
import 'package:tuhfatul_muslim/features/quran/domain/quran_last_read.dart';
import 'package:tuhfatul_muslim/features/quran/domain/quran_reading_dashboard.dart';
import 'package:tuhfatul_muslim/features/quran/domain/quran_reading_history.dart';
import 'package:tuhfatul_muslim/features/quran/domain/quran_reading_progress.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/controllers/quran_reading_sync.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/controllers/quran_reading_tracker.dart';

typedef _Call = ({String? id, int surah, int seconds, String date});

/// `POST /quran/reading/track` that fails with [fail] while it is set.
class _Remote implements QuranReadingRemoteDataSource {
  final calls = <_Call>[];
  Exception? fail;
  Completer<void>? hold;

  void goOffline() => fail = NetworkException();
  void goOnline() => fail = null;

  @override
  Future<QuranReadingTrackResult> trackReading({
    required int surahNumber,
    required int fromAyah,
    required int toAyah,
    required int seconds,
    required String date,
    String? requestId,
  }) async {
    calls.add((
      id: requestId,
      surah: surahNumber,
      seconds: seconds,
      date: date,
    ));
    await hold?.future;
    final failure = fail;
    if (failure != null) throw failure;
    return QuranReadingTrackResult.fromJson(const {});
  }

  @override
  Future<QuranReadingDashboard> getDashboard() => throw UnimplementedError();

  @override
  Future<QuranReadingHistory> getHistory({
    required int days,
    String? from,
    String? to,
  }) => throw UnimplementedError();

  @override
  Future<QuranReadingComparison> getComparison({
    required int days,
    String? from,
    String? to,
  }) => throw UnimplementedError();

  @override
  Future<QuranLastRead> getLastRead() => throw UnimplementedError();
}

/// A clock the test moves by hand.
class _Clock {
  DateTime now = DateTime(2026, 10, 19, 23, 50);
  void advance(int seconds) => now = now.add(Duration(seconds: seconds));
}

/// What waits on the device, read as a later launch would.
Future<List<PendingQuranReading>> _saved() =>
    QuranReadingLocalDataSourceImpl().pending();

QuranReadingRepositoryImpl _repository(_Remote remote, {String? launch}) =>
    QuranReadingRepositoryImpl(
      remote,
      local: QuranReadingLocalDataSourceImpl(),
      isSignedIn: () => true,
      launch: launch,
    );

Future<Either<Failure, QuranReadingTrackResult>> _track(
  QuranReadingRepositoryImpl repository, {
  int seconds = 300,
  String? sessionId,
  DateTime? date,
}) => repository.trackReading(
  surahNumber: 2,
  fromAyah: 1,
  toAyah: 20,
  seconds: seconds,
  date: date ?? DateTime(2026, 10, 19, 23, 50),
  sessionId: sessionId,
);

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('online reading is sent once and nothing is left waiting', () async {
    final remote = _Remote();
    final repository = _repository(remote);
    final tracked = <void>[];
    final sub = repository.onReadingTracked.listen(tracked.add);
    addTearDown(sub.cancel);

    expect((await _track(repository)).isRight(), isTrue);
    await _settle();

    expect(remote.calls, hasLength(1));
    expect(remote.calls.single.date, '2026-10-19');
    expect(remote.calls.single.id, isNotNull);
    expect(tracked, hasLength(1));
    expect(await _saved(), isEmpty);
  });

  test(
    'offline reading is kept with its date and sent once back online',
    () async {
      final remote = _Remote()..goOffline();
      final repository = _repository(remote);

      final result = await _track(repository, seconds: 420);
      expect(result.fold((f) => f, (_) => null), isA<NetworkFailure>());
      final saved = await _saved();
      expect(saved, hasLength(1));
      expect(saved.single.seconds, 420);
      expect(saved.single.date, '2026-10-19');

      // Still offline: nothing is lost and nothing piles up.
      expect(await repository.syncPendingReadings(), (sent: 0, pending: 1));
      expect(await _saved(), hasLength(1));

      remote.goOnline();
      final tracked = <void>[];
      final sub = repository.onReadingTracked.listen(tracked.add);
      addTearDown(sub.cancel);
      expect(await repository.syncPendingReadings(), (sent: 1, pending: 0));
      await _settle();
      expect(tracked, hasLength(1), reason: 'reading screens reload');
      expect(await _saved(), isEmpty);

      // Synced: a later sync sends nothing again.
      final before = remote.calls.length;
      expect(await repository.syncPendingReadings(), (sent: 0, pending: 0));
      expect(remote.calls, hasLength(before));
      // Every attempt carried the same report id.
      expect(remote.calls.map((c) => c.id).toSet(), hasLength(1));
      expect(remote.calls.last.seconds, 420);
    },
  );

  test('the next online report sends what waited, each once', () async {
    final remote = _Remote()..goOffline();
    final repository = _repository(remote);
    await _track(repository, seconds: 100, date: DateTime(2026, 10, 17, 9));
    await _track(repository, seconds: 200, date: DateTime(2026, 10, 18, 9));

    remote.goOnline();
    await _track(repository, seconds: 300);
    await repository.syncPendingReadings();
    // The run started by the report, then this one, have both settled.
    await repository.syncPendingReadings();

    final delivered = remote.calls.skip(2).toList();
    expect(
      [for (final c in delivered) (c.date, c.seconds)],
      [('2026-10-19', 300), ('2026-10-17', 100), ('2026-10-18', 200)],
    );
    expect(await _saved(), isEmpty);
  });

  test('concurrent syncs never send a report twice', () async {
    final remote = _Remote()..goOffline();
    final repository = _repository(remote);
    await _track(repository, seconds: 100);
    await _track(repository, seconds: 200);
    remote
      ..goOnline()
      ..calls.clear()
      ..hold = Completer<void>();

    final syncs = [
      repository.syncPendingReadings(),
      repository.syncPendingReadings(),
      repository.syncPendingReadings(),
    ];
    remote.hold!.complete();
    await Future.wait(syncs);
    await repository.syncPendingReadings();

    expect([for (final c in remote.calls) c.seconds], [100, 200]);
    expect(await _saved(), isEmpty);
  });

  test('a report the server may already have is not resent', () async {
    final remote = _Remote()
      ..fail = NetworkException('The request timed out.', true);
    final repository = _repository(remote);
    await _track(repository);
    expect(await _saved(), isEmpty);
    remote.goOnline();
    await repository.syncPendingReadings();
    expect(remote.calls, hasLength(1));
  });

  test(
    'refused reports are dropped; server errors retry, then give up',
    () async {
      final remote = _Remote()..fail = ServerException('Bad', statusCode: 400);
      final repository = _repository(remote);
      await _track(repository);
      expect(await _saved(), isEmpty, reason: 'it will never be accepted');

      remote.fail = ServerException('Down', statusCode: 503);
      await _track(repository);
      for (var i = 0; i < 3; i++) {
        await repository.syncPendingReadings();
      }
      expect((await _saved()).single.attempts, 4);
      await repository.syncPendingReadings();
      expect(await _saved(), isEmpty, reason: 'given up after 5 attempts');

      // An expired session is not the report's fault: it waits.
      remote.fail = ServerException('Expired', statusCode: 401);
      await _track(repository);
      for (var i = 0; i < 6; i++) {
        await repository.syncPendingReadings();
      }
      expect((await _saved()).single.attempts, 0);
    },
  );

  test('a signed-out device sends nothing', () async {
    final remote = _Remote()..goOffline();
    await _track(_repository(remote));
    remote.goOnline();
    final signedOut = QuranReadingRepositoryImpl(
      remote,
      local: QuranReadingLocalDataSourceImpl(),
      isSignedIn: () => false,
    );
    expect(await signedOut.syncPendingReadings(), (sent: 0, pending: 0));
    expect(await _saved(), hasLength(1));
  });

  group('with the tracker', () {
    late _Clock clock;
    late _Remote remote;

    setUp(() {
      clock = _Clock();
      remote = _Remote()..goOffline();
    });

    QuranReadingTracker tracker(QuranReadingRepositoryImpl repository) =>
        QuranReadingTracker(repository, now: () => clock.now, saveEvery: null);

    test('offline reading time is kept and sent once on reconnect', () async {
      final repository = _repository(remote);
      final reader = tracker(repository);
      reader.show(2, 1, 5);
      clock.advance(120);
      reader.show(2, 6, 12);
      clock.advance(180);
      await reader.dispose();

      final saved = (await _saved()).single;
      expect([saved.surahNumber, saved.fromAyah, saved.toAyah], [2, 1, 12]);
      expect(saved.seconds, 300);
      expect(saved.date, '2026-10-19', reason: 'the day it was read');
      expect(saved.draft, isFalse);

      remote.goOnline();
      await repository.syncPendingReadings();
      await repository.syncPendingReadings();
      expect(remote.calls.where((c) => c.seconds == 300), hasLength(2));
      expect(remote.calls.map((c) => c.id).toSet(), hasLength(1));
      expect(await _saved(), isEmpty);
    });

    test('drafts are replaced by the report: the time counts once', () async {
      remote.goOnline();
      final repository = _repository(remote);
      final reader = tracker(repository);
      reader.show(1, 1, 7);
      clock.advance(40);
      await reader.saveDraft();
      clock.advance(40);
      await reader.saveDraft();
      expect((await _saved()).single.seconds, 80);
      expect((await _saved()).single.draft, isTrue);
      // This launch's draft is a session still being read: not sent.
      await repository.syncPendingReadings();
      expect(remote.calls, isEmpty);

      clock.advance(20);
      await reader.dispose();
      expect([for (final c in remote.calls) c.seconds], [100]);
      expect(await _saved(), isEmpty);
    });

    test(
      'a session cut off by the app closing is sent on the next launch',
      () async {
        final firstLaunch = _repository(remote, launch: 'first');
        final reader = tracker(firstLaunch);
        reader.show(36, 1, 12);
        clock.advance(95);
        await reader.saveDraft();
        // The app is killed here: no pause, no dispose.

        remote.goOnline();
        final nextLaunch = _repository(remote, launch: 'next');
        expect(await nextLaunch.syncPendingReadings(), (sent: 1, pending: 0));
        expect(remote.calls.single.surah, 36);
        expect(remote.calls.single.seconds, 95);
        expect(await _saved(), isEmpty);
      },
    );

    test('a glance leaves no draft behind', () async {
      final repository = _repository(remote);
      final reader = tracker(repository);
      reader.show(2, 1, 5);
      clock.advance(3);
      await reader.saveDraft();
      await reader.dispose();
      expect(await _saved(), isEmpty);
    });

    test('signing out mid-session drops its draft', () async {
      var signedIn = true;
      final repository = QuranReadingRepositoryImpl(
        remote,
        local: QuranReadingLocalDataSourceImpl(),
        isSignedIn: () => signedIn,
      );
      final reader = tracker(repository);
      reader.show(2, 1, 5);
      clock.advance(60);
      await reader.saveDraft();
      expect(await _saved(), hasLength(1));
      signedIn = false;
      await reader.dispose();
      await _settle();
      expect(await _saved(), isEmpty);
    });
  });

  test('the request carries the report id as its idempotency key', () async {
    final requests = <RequestOptions>[];
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1'))
      ..httpClientAdapter = _Adapter(requests);
    final remote = QuranReadingRemoteDataSourceImpl(dio: dio, local: _Token());
    await remote.trackReading(
      surahNumber: 2,
      fromAyah: 1,
      toAyah: 5,
      seconds: 60,
      date: '2026-10-19',
      requestId: 'abc',
    );
    expect(requests.single.headers['Idempotency-Key'], 'abc');
    expect(requests.single.headers['Authorization'], 'Bearer tkn');
  });

  group('sync', () {
    test(
      'retries while reading waits; reloads Amol once some is sent',
      () async {
        final remote = _Remote()..goOffline();
        final repository = _repository(remote);
        await _track(repository);
        var reloads = 0;
        final sync = QuranReadingSync(
          repository,
          retryAfter: const [Duration(hours: 1)],
          onSent: () => reloads++,
        );
        addTearDown(sync.dispose);

        await sync.sync();
        expect(sync.debugRetryScheduled, isTrue);
        expect(reloads, 0);

        remote.goOnline();
        await sync.sync();
        expect(sync.debugRetryScheduled, isFalse);
        expect(reloads, 1);
        expect(await _saved(), isEmpty);
      },
    );
  });

  test('the device copy survives a corrupt entry', () async {
    SharedPreferences.setMockInitialValues({
      QuranReadingLocalDataSourceImpl.key: jsonEncode([
        {'id': 'bad'},
        {
          'id': 'ok',
          'surahNumber': 1,
          'fromAyah': 1,
          'toAyah': 7,
          'seconds': 60,
          'date': '2026-10-18',
        },
      ]),
    });
    expect((await _saved()).map((r) => r.id), ['ok']);
  });
}

class _Token implements AuthLocalDataSource {
  @override
  String? getToken() => 'tkn';
  @override
  bool get hasToken => true;
  @override
  Future<void> cacheToken(String token) async {}
  @override
  Future<void> clearToken() async {}
}

class _Adapter implements HttpClientAdapter {
  _Adapter(this.requests);
  final List<RequestOptions> requests;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode({'success': true, 'data': <String, Object>{}}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
