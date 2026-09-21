import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/hadith/data/models/hadith_reading_history_model.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_reading_history.dart';
import 'package:islami_app_noorify/features/hadith/domain/repositories/hadith_library_repository.dart';
import 'package:islami_app_noorify/features/hadith/domain/usecases/get_hadith_reading_history.dart';
import 'package:islami_app_noorify/features/hadith/presentation/bloc/hadith_dashboard/hadith_dashboard_bloc.dart';

class _FakeRepository implements HadithLibraryRepository {
  final requests = <({String from, String to})>[];

  @override
  Future<Either<Failure, HadithReadingHistory>> getReadingHistory({
    required String from,
    required String to,
  }) async {
    requests.add((from: from, to: to));
    return const Right(
      HadithReadingHistory(
        days: [],
        totals: HadithReadingTotals(
          totalMinutes: 0,
          hadithsRead: 0,
          pointsText: '',
          progressText: '',
        ),
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('hadithHistoryRange', () {
    final now = DateTime(2026, 9, 21, 15, 30);

    test('daily is today to today', () {
      final r = hadithHistoryRange(HadithHistoryPeriod.daily, now: now);
      expect(r.from, DateTime(2026, 9, 21));
      expect(r.to, DateTime(2026, 9, 21));
    });

    test('weekly is 7 days back to today', () {
      final r = hadithHistoryRange(HadithHistoryPeriod.weekly, now: now);
      expect(r.from, DateTime(2026, 9, 14));
      expect(r.to, DateTime(2026, 9, 21));
    });

    test('monthly is 30 days back to today, across a month boundary', () {
      final r = hadithHistoryRange(HadithHistoryPeriod.monthly, now: now);
      expect(r.from, DateTime(2026, 8, 22));
      expect(r.to, DateTime(2026, 9, 21));
    });
  });

  group('HadithReadingHistoryModel', () {
    test('reads days, totals and the display texts', () {
      final m = HadithReadingHistoryModel.fromJson({
        'days': [
          {
            'date': '2026-09-21T00:00:00.000Z',
            'readMinutes': 12.5,
            'goalMinutes': 30,
            'hadithsRead': 4,
          },
          {
            'date': '2026-09-20',
            'readMinutes': 5,
            'goalMinutes': 30,
            'hadithsRead': 1,
          },
          {'readMinutes': 99}, // no date: skipped
        ],
        'totals': {
          'totalMinutes': 17.5,
          'hadithsRead': 5,
          'pointsText': '50 points',
          'progressText': '58% of goal',
        },
      });
      expect(m.days.map((d) => d.date), [
        DateTime(2026, 9, 20),
        DateTime(2026, 9, 21),
      ]);
      expect(m.days.last.readMinutes, 12.5);
      expect(m.days.last.goalMinutes, 30);
      expect(m.totals.totalMinutes, 17.5);
      expect(m.totals.hadithsRead, 5);
      expect(m.totals.pointsText, '50 points');
      expect(m.totals.progressText, '58% of goal');
    });

    test('derives totals from the days when the backend sends none', () {
      final m = HadithReadingHistoryModel.fromJson({
        'history': [
          {'date': '2026-09-20', 'readMinutes': 5, 'hadithsRead': 1},
          {'date': '2026-09-21', 'readMinutes': 7, 'hadithsRead': 2},
        ],
      });
      expect(m.totals.totalMinutes, 12);
      expect(m.totals.hadithsRead, 3);
      expect(m.totals.pointsText, '');
    });

    test('tolerates an empty payload', () {
      final m = HadithReadingHistoryModel.fromJson(const {});
      expect(m.days, isEmpty);
      expect(m.totals.totalMinutes, 0);
    });
  });

  group('HadithDashboardBloc', () {
    test('sends the period\'s from/to dates to the API', () async {
      final repo = _FakeRepository();
      final bloc = HadithDashboardBloc(GetHadithReadingHistory(repo));
      addTearDown(bloc.close);

      bloc.add(const LoadHadithDashboard(HadithHistoryPeriod.weekly));
      final state = await bloc.stream.firstWhere((s) => !s.isLoading);

      final range = hadithHistoryRange(HadithHistoryPeriod.weekly);
      String f(DateTime d) =>
          '${d.year}-${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';
      expect(repo.requests.single, (from: f(range.from), to: f(range.to)));
      expect(state.period, HadithHistoryPeriod.weekly);
      expect(state.status, HadithDashboardStatus.success);
    });
  });
}
