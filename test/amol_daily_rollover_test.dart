import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuhfatul_muslim/core/errors/exceptions.dart';
import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/amol_prayer_gate.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/amol_tracking_day.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/entities/amol_daily_dashboard.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/entities/amol_daily_summary.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/entities/amol_item.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/entities/amol_pillar.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/repositories/amol_tracking_repository.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/usecases/delete_amol_item.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/usecases/get_amol_daily.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/usecases/log_amol_item.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/presentation/bloc/amol_daily/amol_daily_bloc.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/presentation/state/amol_day_clock.dart';
import 'package:tuhfatul_muslim/features/home/data/datasources/home_remote_data_source.dart';
import 'package:tuhfatul_muslim/features/home/data/models/home_dashboard_model.dart';
import 'package:tuhfatul_muslim/features/home/data/repositories/home_repository_impl.dart';
import 'package:tuhfatul_muslim/features/home/domain/daily_prayer_times.dart';
import 'package:tuhfatul_muslim/features/home/domain/entities/home_dashboard.dart';
import 'package:tuhfatul_muslim/features/home/domain/prayer_theme_schedule.dart';
import 'package:tuhfatul_muslim/features/home/domain/repositories/home_repository.dart';
import 'package:tuhfatul_muslim/features/home/domain/usecases/get_home_dashboard.dart';
import 'package:tuhfatul_muslim/features/home/presentation/bloc/home_dashboard/home_dashboard_bloc.dart';

class _DailyRepository implements AmolTrackingRepository {
  _DailyRepository(this._dailyByDate);

  final Map<String, AmolDailyDashboard> _dailyByDate;
  final logged = <({String logDate, String itemKey})>[];

  @override
  Future<Either<Failure, AmolDailyDashboard>> getDaily({
    required String date,
  }) async => Right(_dailyByDate[date]!);

  @override
  Future<Either<Failure, AmolDailyDashboard>> logItem({
    required String logDate,
    required String pillarKey,
    required String itemKey,
  }) async {
    logged.add((logDate: logDate, itemKey: itemKey));
    return Right(_dailyByDate[logDate]!);
  }

  @override
  Future<Either<Failure, AmolDailyDashboard>> deleteItem({
    required String logDate,
    required String pillarKey,
    required String itemKey,
  }) async => Right(_dailyByDate[logDate]!);
  @override
  Future<({int sent, int pending})> syncPending({
    AmolDailyDashboard? known,
  }) async => (sent: 0, pending: 0);
}

AmolDailyDashboard _daily(String date, {bool completed = false}) =>
    AmolDailyDashboard(
      dateFormatted: date,
      dateIso: date,
      earnedPoints: completed ? 1 : 0,
      maxPoints: 1,
      completionPercentage: completed ? 100 : 0,
      summary: AmolDailySummary(
        totalEarnedPoints: completed ? 1 : 0,
        totalPossiblePoints: 1,
        percentage: completed ? 100 : 0,
        pointsText: '',
      ),
      pillars: [
        AmolPillar(
          pillarKey: 'nafl_salat',
          title: 'Nafl Salat',
          titleBn: 'Nafl Salat',
          earnedPoints: completed ? 1 : 0,
          maxPoints: 1,
          percentage: completed ? 100 : 0,
          formattedSubtext: completed ? '1/1' : '0/1',
          items: [
            AmolItem(
              itemKey: 'tahajjud',
              title: 'Tahajjud',
              titleBn: 'Tahajjud',
              points: completed ? 1 : 0,
              maxPoints: 1,
              isCompleted: completed,
            ),
          ],
        ),
      ],
    );

Future<void> _load(AmolDailyBloc bloc, String date) async {
  final loaded = bloc.stream.firstWhere(
    (state) => state.hasData && state.dashboard!.dateIso == date,
  );
  bloc.add(LoadAmolDaily(date));
  await loaded;
}

void main() {
  test('new daily load clears yesterday completion overrides', () async {
    const yesterday = '2026-10-21';
    const today = '2026-10-22';
    final repository = _DailyRepository({
      yesterday: _daily(yesterday),
      today: _daily(today),
    });
    final bloc = AmolDailyBloc(
      GetAmolDaily(repository),
      LogAmolItem(repository),
      DeleteAmolItem(repository),
    );
    addTearDown(bloc.close);

    await _load(bloc, yesterday);
    final logged = bloc.stream.firstWhere(
      (state) =>
          state.hasData &&
          state.loggingItemKeys.isEmpty &&
          state.isItemChecked('tahajjud', false),
    );
    bloc.add(
      const LogAmolDailyItem(
        logDate: yesterday,
        pillarKey: 'nafl_salat',
        itemKey: 'tahajjud',
      ),
    );
    await logged;
    expect(bloc.state.completionOverrides, {'tahajjud': true});

    await _load(bloc, today);

    expect(bloc.state.dashboard!.dateIso, today);
    expect(bloc.state.dashboard!.completionPercentage, 0);
    expect(bloc.state.completionOverrides, isEmpty);
    expect(bloc.state.isItemChecked('tahajjud', false), isFalse);
  });

  test('Tahajjud can be logged at 3 AM for the new civil day', () {
    const times = DailyPrayerTimes(
      dateKey: '2026-10-22',
      readableDate: '',
      hijriDate: '',
      fajr: PrayerClockTime(hour: 4, minute: 30),
      sunrise: PrayerClockTime(hour: 6, minute: 0),
      dhuhr: PrayerClockTime(hour: 12, minute: 0),
      asr: PrayerClockTime(hour: 15, minute: 30),
      maghrib: PrayerClockTime(hour: 17, minute: 45),
      sunset: PrayerClockTime(hour: 17, minute: 45),
      isha: PrayerClockTime(hour: 19, minute: 0),
    );

    expect(
      canLogAmolPrayerItem(
        now: DateTime(2026, 10, 22, 3),
        trackingDate: DateTime(2026, 10, 22),
        pillarKey: 'nafl_salat',
        itemKey: 'tahajjud',
        times: times,
      ),
      isTrue,
    );
  });

  group('the tracking day', () {
    test('is the local calendar day, from midnight to midnight', () {
      // The first second of the day, the small hours, and the last second:
      // one and the same day.
      expect(amolTrackingDateIso(DateTime(2026, 10, 22)), '2026-10-22');
      expect(amolTrackingDateIso(DateTime(2026, 10, 22, 3)), '2026-10-22');
      expect(
        amolTrackingDateIso(DateTime(2026, 10, 22, 23, 59, 59)),
        '2026-10-22',
      );
      // And midnight is the new one.
      expect(amolTrackingDateIso(DateTime(2026, 10, 23)), '2026-10-23');
    });

    test('rolls over at the next midnight, month and year included', () {
      expect(
        nextAmolTrackingCheck(DateTime(2026, 10, 22, 3)),
        DateTime(2026, 10, 23),
      );
      expect(
        nextAmolTrackingCheck(DateTime(2026, 10, 22, 23, 59, 59)),
        DateTime(2026, 10, 23),
      );
      expect(
        nextAmolTrackingCheck(DateTime(2026, 10, 31, 20)),
        DateTime(2026, 11, 1),
      );
      expect(
        nextAmolTrackingCheck(DateTime(2026, 12, 31, 20)),
        DateTime(2027, 1, 1),
      );
    });
  });

  group('the shared day clock', () {
    test('announces the new day once the clock passes midnight', () {
      var now = DateTime(2026, 10, 22, 23, 59, 30);
      final clock = AmolDayClock(now: () => now, watchLifecycle: false);
      addTearDown(clock.dispose);
      final announced = <String>[];
      clock.addListener(() => announced.add(clock.date));

      expect(clock.date, '2026-10-22');

      // Still the same day: nothing to tell anyone.
      now = DateTime(2026, 10, 22, 23, 59, 59);
      clock.refresh();
      expect(announced, isEmpty);

      now = DateTime(2026, 10, 23, 0, 0, 1);
      clock.refresh();
      expect(announced, ['2026-10-23']);
      expect(clock.date, '2026-10-23');

      // One announcement per day, however often it is asked.
      clock.refresh();
      expect(announced, ['2026-10-23']);
    });

    test('catches up after the device slept through midnight', () {
      var now = DateTime(2026, 10, 22, 22);
      final clock = AmolDayClock(now: () => now, watchLifecycle: false);
      addTearDown(clock.dispose);

      // Two days of sleep, then a resume.
      now = DateTime(2026, 10, 24, 9);
      clock.refresh();

      expect(clock.date, '2026-10-24');
    });
  });

  test('a day that has closed can no longer be ticked', () async {
    const yesterday = '2026-10-21';
    const today = '2026-10-22';
    final repository = _DailyRepository({
      yesterday: _daily(yesterday),
      today: _daily(today),
    });
    final bloc = AmolDailyBloc(
      GetAmolDaily(repository),
      LogAmolItem(repository),
      DeleteAmolItem(repository),
    );
    addTearDown(bloc.close);

    await _load(bloc, today);
    repository.logged.clear();

    // Midnight has passed; a tap still carrying yesterday's date is dropped
    // rather than logged against it — or against today.
    bloc.add(
      const LogAmolDailyItem(
        logDate: yesterday,
        pillarKey: 'nafl_salat',
        itemKey: 'tahajjud',
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(repository.logged, isEmpty);
    expect(bloc.state.completionOverrides, isEmpty);
    expect(bloc.state.isItemChecked('tahajjud', false), isFalse);
  });

  group('the Home dashboard', () {
    test('drops yesterday\'s numbers when the day has rolled over', () async {
      var now = DateTime(2026, 10, 22, 23, 50);
      final repository = _StubHomeRepository();
      final bloc = HomeDashboardBloc(
        GetHomeDashboard(repository),
        now: () => now,
      );
      addTearDown(bloc.close);

      bloc.add(const LoadHomeDashboard());
      await bloc.stream.firstWhere((state) => state.hasData);
      expect(bloc.state.dashboard!.userSummary.totalPointsToday, 7);

      // After midnight the fetch fails (offline). Yesterday's 7 points must
      // not stay on screen, even though this is a silent refresh.
      now = DateTime(2026, 10, 23, 0, 0, 5);
      repository.failure = const NetworkFailure('offline');
      bloc.add(const LoadHomeDashboard(silent: true));
      await bloc.stream.firstWhere((state) => !state.hasData);

      expect(bloc.state.hasData, isFalse);
    });

    test('a dashboard cached yesterday is not served today', () async {
      SharedPreferences.setMockInitialValues({});
      final today = DateTime(2026, 10, 22, 9);
      await HomeRemoteDataSourceImpl.cache.save({
        'userSummary': {'fullName': 'A', 'totalPointsToday': 7},
      }, at: today.subtract(const Duration(days: 1)));

      final offline = HomeRepositoryImpl(_OfflineRemote(), now: () => today);
      expect((await offline.getDashboard()).isLeft(), isTrue);

      // Cached today, it is still the right answer while offline.
      await HomeRemoteDataSourceImpl.cache.save({
        'userSummary': {'fullName': 'A', 'totalPointsToday': 3},
      }, at: today);
      final result = await offline.getDashboard();
      expect(
        result.getOrElse(() => throw 'no dashboard').userSummary.fullName,
        'A',
      );
    });
  });
}

class _StubHomeRepository implements HomeRepository {
  Failure? failure;

  @override
  Future<Either<Failure, HomeDashboard>> getDashboard() async {
    final failed = failure;
    if (failed != null) return Left(failed);
    return Right(
      HomeDashboardModel.fromJson({
        'userSummary': {'fullName': 'A', 'totalPointsToday': 7},
      }),
    );
  }
}

class _OfflineRemote implements HomeRemoteDataSource {
  @override
  Future<HomeDashboardModel> getDashboard() async =>
      throw NetworkException('offline');
}
