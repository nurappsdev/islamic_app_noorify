import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
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
import 'package:tuhfatul_muslim/features/home/domain/daily_prayer_times.dart';
import 'package:tuhfatul_muslim/features/home/domain/prayer_theme_schedule.dart';

class _DailyRepository implements AmolTrackingRepository {
  _DailyRepository(this._dailyByDate);

  final Map<String, AmolDailyDashboard> _dailyByDate;

  @override
  Future<Either<Failure, AmolDailyDashboard>> getDaily({
    required String date,
  }) async => Right(_dailyByDate[date]!);

  @override
  Future<Either<Failure, AmolDailyDashboard>> logItem({
    required String logDate,
    required String pillarKey,
    required String itemKey,
  }) async => Right(_dailyByDate[logDate]!);

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

  test('pre-Fajr hours use the prior API date and rotate at Fajr', () {
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

    expect(amolTrackingDateIso(DateTime(2026, 10, 22, 3), times), '2026-10-21');
    expect(
      amolTrackingDateIso(DateTime(2026, 10, 22, 4, 30), times),
      '2026-10-22',
    );
    expect(
      nextAmolTrackingCheck(DateTime(2026, 10, 22, 3), times),
      DateTime(2026, 10, 22, 4, 30),
    );
  });
}
