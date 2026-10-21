import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tuhfatul_muslim/core/errors/exceptions.dart';
import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/core/storage/session_cleaner.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/data/amol_day_snapshot_store.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/data/amol_pending_actions_store.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/data/datasources/amol_tracking_remote_data_source.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/data/models/amol_daily_dashboard_model.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/data/repositories/amol_tracking_repository_impl.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/amol_local_projection.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/entities/amol_daily_dashboard.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/presentation/controllers/amol_sync.dart';

/// `GET /amol/tracker/daily`'s payload for [date], with [done] ticked: two
/// tick-mark items under Fardh Prayer plus one entry item under Quran, whose
/// subtext is a duration the app can't recompute.
Map<String, dynamic> dayJson(String date, {Set<String> done = const {}}) {
  num pts(String key) => done.contains(key) ? 1 : 0;
  final fardh = ['fajr', 'dhuhr'];
  final earned = fardh.fold<num>(0, (sum, key) => sum + pts(key));
  return {
    'dateFormatted': '12 Ramadan',
    'dateIso': date,
    'earnedPoints': earned,
    'maxPoints': 10,
    'completionPercentage': earned / 10 * 100,
    'summary': {
      'totalEarnedPoints': earned,
      'totalPossiblePoints': 10,
      'percentage': earned / 10 * 100,
      'pointsText': 'Point : $earned/10',
    },
    'pillars': [
      {
        'pillarKey': 'fardh_prayer',
        'title': 'Fardh Prayer',
        'titleBn': 'ফরজ নামাজ',
        'earnedPoints': earned,
        'maxPoints': 2,
        'percentage': earned / 2 * 100,
        'formattedSubtext': '${done.where(fardh.contains).length}/2',
        'items': [
          for (final key in fardh)
            {
              'itemKey': key,
              'title': key,
              'titleBn': key,
              'points': pts(key),
              'maxPoints': 1,
              'isCompleted': done.contains(key),
            },
        ],
      },
      {
        'pillarKey': 'quran',
        'title': 'Quran',
        'titleBn': 'কুরআন',
        'earnedPoints': done.contains('quran_tilawat') ? 3 : 0,
        'maxPoints': 8,
        'percentage': done.contains('quran_tilawat') ? 37.5 : 0,
        'formattedSubtext': '1hr 37min',
        'items': [
          {
            'itemKey': 'quran_tilawat',
            'title': 'Quran',
            'titleBn': 'কুরআন',
            'points': done.contains('quran_tilawat') ? 3 : 0,
            'maxPoints': 8,
            'isCompleted': done.contains('quran_tilawat'),
          },
        ],
      },
    ],
  };
}

AmolDailyDashboard day(String date, {Set<String> done = const {}}) =>
    AmolDailyDashboardModel.fromJson(dayJson(date, done: done));

/// A stand-in server: holds what is logged per date, can be switched offline,
/// and counts every call so a test can prove nothing was sent twice.
class FakeRemote implements AmolTrackingRemoteDataSource {
  FakeRemote({this.offline = false, this.snapshots});

  bool offline;
  bool rejectWrites = false;

  /// Written like the real data source does, so the repository has something
  /// to fall back on once it goes offline.
  final AmolDaySnapshotStore? snapshots;

  final Map<String, Set<String>> completed = {};

  /// Every attempt, reaching the server or not.
  final List<String> calls = [];

  /// Writes the server actually accepted.
  int applied = 0;

  int get logs => calls.where((c) => c.startsWith('log')).length;
  int get deletes => calls.where((c) => c.startsWith('delete')).length;
  int get gets => calls.where((c) => c.startsWith('get')).length;

  Set<String> _done(String date) => completed.putIfAbsent(date, () => {});

  Future<AmolDailyDashboardModel> _answer(String date) async {
    final json = dayJson(date, done: _done(date));
    await snapshots?.write(json);
    return AmolDailyDashboardModel.fromJson(json);
  }

  @override
  Future<AmolDailyDashboardModel> getDaily({required String date}) async {
    calls.add('get:$date');
    if (offline) throw NetworkException();
    return _answer(date);
  }

  @override
  Future<AmolDailyDashboardModel> logItem({
    required String logDate,
    required String pillarKey,
    required String itemKey,
  }) async {
    calls.add('log:$logDate:$itemKey');
    if (offline) throw NetworkException();
    if (rejectWrites) throw ServerException('refused', statusCode: 400);
    _done(logDate).add(itemKey);
    applied++;
    return _answer(logDate);
  }

  @override
  Future<AmolDailyDashboardModel> deleteItem({
    required String logDate,
    required String pillarKey,
    required String itemKey,
  }) async {
    calls.add('delete:$logDate:$itemKey');
    if (offline) throw NetworkException();
    if (rejectWrites) throw ServerException('refused', statusCode: 400);
    _done(logDate).remove(itemKey);
    applied++;
    return _answer(logDate);
  }
}

void main() {
  late AmolPendingActionsStore queue;
  late AmolDaySnapshotStore snapshots;
  late FakeRemote remote;
  late AmolTrackingRepositoryImpl repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    queue = AmolPendingActionsStore();
    snapshots = AmolDaySnapshotStore();
    remote = FakeRemote(snapshots: snapshots);
    repository = AmolTrackingRepositoryImpl(
      remote,
      pending: queue,
      snapshots: snapshots,
    );
  });

  PendingAmolAction action(
    String date,
    String itemKey, {
    bool isLog = true,
    String pillarKey = 'fardh_prayer',
    DateTime? at,
  }) => PendingAmolAction(
    isLog: isLog,
    logDate: date,
    pillarKey: pillarKey,
    itemKey: itemKey,
    at: at ?? DateTime.now(),
  );

  group('projection', () {
    test('an offline tick shows done, and moves points and progress', () {
      final projected = projectAmolDay(day('2026-10-21'), [
        action('2026-10-21', 'fajr'),
      ]);

      final fardh = projected.pillars.first;
      expect(fardh.items.first.isCompleted, isTrue);
      expect(fardh.items.first.points, 1);
      expect(fardh.earnedPoints, 1);
      expect(fardh.formattedSubtext, '1/2');
      expect(projected.summary.totalEarnedPoints, 1);
      expect(projected.summary.pointsText, 'Point : 1/10');
      expect(projected.completionPercentage, 10);
      expect(projected.pendingItemKeys, {'fajr'});
      expect(projected.isPending('fajr'), isTrue);
    });

    test('an offline untick clears it again', () {
      final projected = projectAmolDay(day('2026-10-21', done: {'fajr'}), [
        action('2026-10-21', 'fajr', isLog: false),
      ]);

      expect(projected.pillars.first.items.first.isCompleted, isFalse);
      expect(projected.pillars.first.earnedPoints, 0);
      expect(projected.summary.totalEarnedPoints, 0);
      expect(projected.pendingItemKeys, {'fajr'});
    });

    test('another day\'s actions are ignored', () {
      final projected = projectAmolDay(day('2026-10-21'), [
        action('2026-10-20', 'fajr'),
      ]);

      expect(projected.pillars.first.items.first.isCompleted, isFalse);
      expect(projected.pendingItemKeys, isEmpty);
    });

    test('an entry pillar is never projected: logging it adds an entry', () {
      final projected = projectAmolDay(day('2026-10-21'), [
        action('2026-10-21', 'quran_tilawat', pillarKey: 'quran'),
      ]);

      final quran = projected.pillars.last;
      expect(quran.items.first.isCompleted, isFalse);
      expect(quran.formattedSubtext, '1hr 37min');
      expect(projected.pendingItemKeys, isEmpty);
    });

    test('a blank day keeps the checklist and drops every number', () {
      final blank = blankAmolDay(
        day('2026-10-20', done: {'fajr', 'dhuhr', 'quran_tilawat'}),
        '2026-10-21',
      );

      expect(blank.dateIso, '2026-10-21');
      expect(blank.pillars.length, 2);
      expect(blank.pillars.first.items.map((i) => i.itemKey), [
        'fajr',
        'dhuhr',
      ]);
      expect(blank.pillars.first.items.every((i) => !i.isCompleted), isTrue);
      expect(blank.pillars.first.items.first.maxPoints, 1);
      expect(blank.pillars.first.formattedSubtext, '0/2');
      // Yesterday's Quran minutes must not be credited to the new day.
      expect(blank.pillars.last.earnedPoints, 0);
      expect(blank.pillars.last.formattedSubtext, '');
      expect(blank.summary.totalEarnedPoints, 0);
      expect(blank.completionPercentage, 0);
    });

    test('the day total never exceeds its maximum', () {
      var seeded = day('2026-10-21');
      seeded = seeded.copyWith(
        pillars: [
          seeded.pillars.first.copyWith(earnedPoints: 40),
          seeded.pillars.last.copyWith(earnedPoints: 40),
        ],
      );
      final projected = projectAmolDay(seeded, [action('2026-10-21', 'fajr')]);

      expect(projected.earnedPoints, 10);
      expect(projected.completionPercentage, 100);
    });
  });

  group('queue', () {
    test('the same item on two days is two records, not one', () async {
      // The Fajr boundary: ticked late on the 20th, then again on the 21st.
      await queue.save(action('2026-10-20', 'fajr'));
      await queue.save(action('2026-10-21', 'fajr'));

      final all = await queue.load();
      expect(all.length, 2);
      expect(all.map((a) => a.logDate), ['2026-10-20', '2026-10-21']);
      expect(await queue.pendingDates(), ['2026-10-20', '2026-10-21']);
    });

    test('re-ticking the same item on the same day replaces it', () async {
      await queue.save(action('2026-10-21', 'fajr'));
      await queue.save(action('2026-10-21', 'fajr', isLog: false));

      final all = await queue.load();
      expect(all.length, 1);
      expect(all.single.isLog, isFalse);
    });

    test('overlapping writes never lose one another', () async {
      await Future.wait([
        for (var i = 0; i < 20; i++) queue.save(action('2026-10-21', 'item$i')),
      ]);

      expect((await queue.load()).length, 20);
    });

    test('removing one leaves the other day alone', () async {
      await queue.save(action('2026-10-20', 'fajr'));
      await queue.save(action('2026-10-21', 'fajr'));
      await queue.remove('2026-10-21|fardh_prayer|fajr');

      expect((await queue.load()).single.logDate, '2026-10-20');
    });

    test('an action the server keeps refusing is given up on', () async {
      final one = action('2026-10-21', 'fajr');
      await queue.save(one);

      for (var i = 1; i < AmolPendingActionsStore.maxRejections; i++) {
        expect(await queue.recordRejection(one), isTrue);
      }
      expect(await queue.recordRejection(one), isFalse);
      expect(await queue.load(), isEmpty);
    });

    test('it survives the app being closed, and ages out', () async {
      await queue.save(action('2026-10-21', 'fajr'));
      await queue.save(action('2000-01-01', 'dhuhr', at: DateTime(2000)));

      // A fresh store, as if the app had restarted.
      final reopened = await AmolPendingActionsStore().load();
      expect(reopened.map((a) => a.itemKey), ['fajr']);
    });

    test('pendingItemKeys answers per day', () async {
      await queue.save(action('2026-10-21', 'fajr'));
      await queue.save(action('2026-10-20', 'dhuhr'));

      expect(await queue.pendingItemKeys('2026-10-21'), {'fajr'});
      expect(await queue.pendingItemKeys('2026-10-19'), isEmpty);
    });
  });

  group('repository, offline', () {
    test(
      'a tick with no network succeeds, is kept, and reads as pending',
      () async {
        await repository.getDaily(date: '2026-10-21');
        remote.offline = true;

        final result = await repository.logItem(
          logDate: '2026-10-21',
          pillarKey: 'fardh_prayer',
          itemKey: 'fajr',
        );

        final dashboard = result.getOrElse(() => throw 'expected a day');
        expect(dashboard.pillars.first.items.first.isCompleted, isTrue);
        expect(dashboard.pendingItemKeys, {'fajr'});
        expect(dashboard.summary.totalEarnedPoints, 1);
        expect((await queue.load()).single.itemKey, 'fajr');
      },
    );

    test('the tick is still there after a restart', () async {
      await repository.getDaily(date: '2026-10-21');
      remote.offline = true;
      await repository.logItem(
        logDate: '2026-10-21',
        pillarKey: 'fardh_prayer',
        itemKey: 'fajr',
      );

      // Everything rebuilt from storage, as on a cold start, still offline.
      final restarted = AmolTrackingRepositoryImpl(
        FakeRemote(offline: true),
        pending: AmolPendingActionsStore(),
        snapshots: AmolDaySnapshotStore(),
      );
      final result = await restarted.getDaily(date: '2026-10-21');

      final dashboard = result.getOrElse(() => throw 'expected a day');
      expect(dashboard.pillars.first.items.first.isCompleted, isTrue);
      expect(dashboard.pendingItemKeys, {'fajr'});
    });

    test('a new Fajr-to-Fajr day offline is empty but tickable', () async {
      await repository.getDaily(date: '2026-10-20');
      remote.offline = true;

      final result = await repository.getDaily(date: '2026-10-21');

      final dashboard = result.getOrElse(() => throw 'expected a day');
      expect(dashboard.dateIso, '2026-10-21');
      expect(dashboard.pillars.first.items.length, 2);
      expect(dashboard.summary.totalEarnedPoints, 0);
    });

    test('a day the device has never seen stays a failure', () async {
      remote.offline = true;

      final result = await repository.getDaily(date: '2026-10-21');

      expect(result.isLeft(), isTrue);
    });

    test('an entry pillar is not queued offline', () async {
      remote.offline = true;

      final result = await repository.logItem(
        logDate: '2026-10-21',
        pillarKey: 'quran',
        itemKey: 'quran_tilawat',
      );

      expect(result.isLeft(), isTrue);
      expect(await queue.load(), isEmpty);
    });

    test('a server refusal is reported and not queued for replay', () async {
      remote.rejectWrites = true;

      final result = await repository.logItem(
        logDate: '2026-10-21',
        pillarKey: 'fardh_prayer',
        itemKey: 'fajr',
      );

      expect(result.isLeft(), isTrue);
      result.fold((f) => expect(f, isA<ServerFailure>()), (_) => fail('right'));
      expect(await queue.load(), isEmpty);
    });
  });

  group('sync', () {
    test('what was ticked offline reaches the server, once', () async {
      await repository.getDaily(date: '2026-10-21');
      remote.offline = true;
      await repository.logItem(
        logDate: '2026-10-21',
        pillarKey: 'fardh_prayer',
        itemKey: 'fajr',
      );
      remote.offline = false;
      remote.calls.clear();

      final result = await repository.syncPending();

      expect(result.sent, 1);
      expect(result.pending, 0);
      expect(remote.logs, 1);
      expect(remote.completed['2026-10-21'], {'fajr'});
      expect(await queue.load(), isEmpty);
    });

    test('a tick whose response was lost is not sent again', () async {
      // The POST landed; only its answer never came back, so it is queued.
      remote.completed['2026-10-21'] = {'fajr'};
      await queue.save(action('2026-10-21', 'fajr'));
      remote.calls.clear();

      final result = await repository.syncPending();

      // Compared against the server, there is nothing left to do.
      expect(result.sent, 0);
      expect(remote.logs, 0);
      expect(await queue.load(), isEmpty);
    });

    test('an untick made offline is sent as a delete', () async {
      remote.completed['2026-10-21'] = {'fajr'};
      await queue.save(action('2026-10-21', 'fajr', isLog: false));

      final result = await repository.syncPending();

      expect(result.sent, 1);
      expect(remote.deletes, 1);
      expect(remote.completed['2026-10-21'], isEmpty);
    });

    test(
      'two days of offline ticks both land, under their own dates',
      () async {
        await queue.save(action('2026-10-20', 'fajr'));
        await queue.save(action('2026-10-21', 'fajr'));

        final result = await repository.syncPending();

        expect(result.sent, 2);
        expect(remote.completed['2026-10-20'], {'fajr'});
        expect(remote.completed['2026-10-21'], {'fajr'});
        expect(await queue.load(), isEmpty);
      },
    );

    test('still offline: nothing is sent and nothing is lost', () async {
      await queue.save(action('2026-10-21', 'fajr'));
      remote.offline = true;

      final result = await repository.syncPending();

      expect(result.sent, 0);
      expect(result.pending, 1);
      expect(remote.logs, 0);
      expect((await queue.load()).single.itemKey, 'fajr');
    });

    test(
      'one refused action does not block the rest, and is dropped',
      () async {
        await queue.save(action('2026-10-21', 'fajr'));
        remote.rejectWrites = true;

        for (var i = 0; i < AmolPendingActionsStore.maxRejections; i++) {
          await repository.syncPending();
        }

        expect(await queue.load(), isEmpty);

        // The queue still works afterwards.
        remote.rejectWrites = false;
        await queue.save(action('2026-10-21', 'dhuhr'));
        expect((await repository.syncPending()).sent, 1);
      },
    );

    test('a reload syncs by itself, without anyone asking', () async {
      await repository.getDaily(date: '2026-10-21');
      remote.offline = true;
      await repository.logItem(
        logDate: '2026-10-21',
        pillarKey: 'fardh_prayer',
        itemKey: 'fajr',
      );
      remote.offline = false;

      final result = await repository.getDaily(date: '2026-10-21');

      final dashboard = result.getOrElse(() => throw 'expected a day');
      expect(await queue.load(), isEmpty);
      expect(dashboard.pendingItemKeys, isEmpty);
      expect(dashboard.pillars.first.items.first.isCompleted, isTrue);
      // The offline attempt plus one replay — logged on the server exactly
      // once.
      expect(remote.applied, 1);
    });
  });

  group('AmolSync', () {
    test('nothing is sent while signed out', () async {
      await queue.save(action('2026-10-21', 'fajr'));
      final sync = AmolSync(
        repository,
        retryAfter: const [Duration(minutes: 5)],
        isSignedIn: () => false,
        onSent: () {},
      );
      addTearDown(sync.dispose);

      await sync.sync();

      expect(remote.logs, 0);
      expect((await queue.load()).length, 1);
      // It will come back to it.
      expect(sync.debugRetryScheduled, isTrue);
    });

    test('signed in, it sends and then stops retrying', () async {
      await queue.save(action('2026-10-21', 'fajr'));
      var sent = 0;
      final sync = AmolSync(
        repository,
        retryAfter: const [Duration(minutes: 5)],
        isSignedIn: () => true,
        onSent: () => sent++,
      );
      addTearDown(sync.dispose);

      await sync.sync();

      expect(remote.logs, 1);
      expect(sent, 1);
      expect(await queue.load(), isEmpty);
      expect(sync.debugRetryScheduled, isFalse);
    });

    test('still offline, it keeps the queue and tries again later', () async {
      await queue.save(action('2026-10-21', 'fajr'));
      remote.offline = true;
      final sync = AmolSync(
        repository,
        retryAfter: const [Duration(minutes: 5)],
        isSignedIn: () => true,
        onSent: () => fail('nothing was sent'),
      );
      addTearDown(sync.dispose);

      await sync.sync();

      expect((await queue.load()).length, 1);
      expect(sync.debugRetryScheduled, isTrue);
    });
  });

  test('sign-out clears the offline queue and the cached days', () {
    // Otherwise one account's unsent ticks would be logged under the next.
    expect(SessionCleaner.userPrefKeys, contains(AmolPendingActionsStore.key));
    expect(SessionCleaner.userPrefKeys, contains(AmolDaySnapshotStore.key));
  });
}
