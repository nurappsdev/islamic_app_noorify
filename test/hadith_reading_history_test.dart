import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/hadith/data/models/hadith_reading_comparison_model.dart';
import 'package:islami_app_noorify/features/hadith/data/models/hadith_reading_history_model.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_reading_comparison.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_reading_history.dart';
import 'package:islami_app_noorify/features/hadith/domain/repositories/hadith_library_repository.dart';
import 'package:islami_app_noorify/features/hadith/domain/usecases/get_hadith_reading_comparison.dart';
import 'package:islami_app_noorify/features/hadith/domain/usecases/get_hadith_reading_history.dart';
import 'package:islami_app_noorify/features/hadith/presentation/bloc/hadith_comparison/hadith_comparison_bloc.dart';
import 'package:islami_app_noorify/features/hadith/presentation/bloc/hadith_dashboard/hadith_dashboard_bloc.dart';

class _FakeRepository implements HadithLibraryRepository {
  final requests = <({String from, String to})>[];
  final comparisonRequests = <({String from, String to})>[];

  @override
  Future<Either<Failure, HadithReadingComparison>> getReadingComparison({
    required String from,
    required String to,
  }) async {
    comparisonRequests.add((from: from, to: to));
    return const Right(
      HadithReadingComparison(comparedWith: 'first_place', competitor: null),
    );
  }

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

  group('hadithMonthRange', () {
    final now = DateTime(2026, 9, 21, 15, 30);

    test('a past month is its 1st to its last day', () {
      final r = hadithMonthRange(DateTime(2026, 8, 15), now: now);
      expect(r.from, DateTime(2026, 8, 1));
      expect(r.to, DateTime(2026, 8, 31));
    });

    test('the current month ends today', () {
      final r = hadithMonthRange(DateTime(2026, 9), now: now);
      expect(r.from, DateTime(2026, 9, 1));
      expect(r.to, DateTime(2026, 9, 21));
    });

    test('knows the length of February, leap year or not', () {
      expect(
        hadithMonthRange(DateTime(2024, 2), now: now).to,
        DateTime(2024, 2, 29),
      );
      expect(
        hadithMonthRange(DateTime(2025, 2), now: now).to,
        DateTime(2025, 2, 28),
      );
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
      expect(m.totals.totalPoints, isNull);
    });

    test('reads points per day and the backend\'s totalPoints', () {
      final m = HadithReadingHistoryModel.fromJson({
        'days': [
          {'date': '2026-09-20', 'points': 10},
          {'date': '2026-09-21', 'totalPoints': 15.5},
          {'date': '2026-09-22'},
        ],
        'totals': {'totalPoints': 100},
      });
      expect(m.days.map((d) => d.points), [10, 15.5, null]);
      expect(m.totals.totalPoints, 100);
    });

    test('sums totalPoints from the days when the totals lack it', () {
      final m = HadithReadingHistoryModel.fromJson({
        'days': [
          {'date': '2026-09-20', 'points': 10},
          {'date': '2026-09-21', 'points': 5},
        ],
      });
      expect(m.totals.totalPoints, 15);
    });
  });

  group('HadithReadingComparisonModel', () {
    // Trimmed from a real /hadiths/reading/history/compare response.
    final data = {
      'from': '2026-09-21',
      'to': '2026-09-21',
      'comparedWith': 'first_place',
      'users': [
        {
          'key': 'user1',
          'rank': 28,
          'isCurrentUser': true,
          'name': 'Abdur Rahman',
          'totalPoints': 375.5,
          'days': [
            {'date': '2026-09-21', 'readMinutes': 5.2, 'points': 1},
          ],
        },
        {
          'key': 'user2',
          'rank': 1,
          'isCurrentUser': false,
          'name': 'Yousuf Ahmed',
          'avatarUrl': 'https://example.com/a.png',
          'totalPoints': 1055,
          'days': [
            {
              'date': '2026-09-21',
              'readMinutes': 12.5,
              'goalMinutes': 30,
              'points': 3,
              'hadithsRead': 2,
            },
          ],
          'totals': {'totalMinutes': 12.5, 'totalPoints': 1055},
        },
      ],
      'difference': {'totalPoints': 1, 'isAhead': true},
    };

    test('takes the reader who is not the current user', () {
      final m = HadithReadingComparisonModel.fromJson(data);
      expect(m.comparedWith, 'first_place');
      final c = m.competitor!;
      expect(c.name, 'Yousuf Ahmed');
      expect(c.rank, 1);
      expect(c.totalPoints, 1055);
      expect(c.days.single.date, DateTime(2026, 9, 21));
      expect(c.days.single.readMinutes, 12.5);
      expect(c.days.single.points, 3);
    });

    test('my own name comes from the entry marked as the current user', () {
      final m = HadithReadingComparisonModel.fromJson(data);
      expect(m.myName, 'Abdur Rahman');
      expect(hadithInitials(m.myName), 'AR');
      expect(m.competitor!.name, 'Yousuf Ahmed');
      expect(m.competitor!.initials, 'YA');
    });

    test('my name is empty without my own entry', () {
      expect(
        HadithReadingComparisonModel.fromJson({
          'users': [
            {'isCurrentUser': false, 'name': 'Other'},
          ],
        }).myName,
        '',
      );
      expect(HadithReadingComparisonModel.fromJson(const {}).myName, '');
    });

    test('initials: one letter per word, at most two, upper case', () {
      expect(hadithInitials('abdur rahman'), 'AR');
      expect(hadithInitials('  Yousuf   Ahmed Khan '), 'YA');
      expect(hadithInitials('Madonna'), 'M');
      expect(hadithInitials(''), '');
    });

    test('initials are the first letters of the name', () {
      final c = HadithReadingComparisonModel.fromJson(data).competitor!;
      expect(c.initials, 'YA');
    });

    test('no competitor when only the current user is returned', () {
      final m = HadithReadingComparisonModel.fromJson({
        'users': [
          {'isCurrentUser': true, 'name': 'Me'},
        ],
      });
      expect(m.competitor, isNull);
      expect(
        HadithReadingComparisonModel.fromJson(const {}).competitor,
        isNull,
      );
    });
  });

  group('HadithComparisonBloc', () {
    test('asks for the same dates as the period', () async {
      final repo = _FakeRepository();
      final bloc = HadithComparisonBloc(GetHadithReadingComparison(repo));
      addTearDown(bloc.close);

      bloc.add(const LoadHadithComparison(HadithHistoryPeriod.monthly));
      final state = await bloc.stream.firstWhere(
        (s) => s.status != HadithComparisonStatus.loading,
      );

      final range = hadithHistoryRange(HadithHistoryPeriod.monthly);
      String f(DateTime d) =>
          '${d.year}-${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';
      expect(repo.comparisonRequests.single, (
        from: f(range.from),
        to: f(range.to),
      ));
      expect(state.status, HadithComparisonStatus.success);
      expect(state.period, HadithHistoryPeriod.monthly);
    });

    test('nothing is requested until the toggle sends an event', () {
      final repo = _FakeRepository();
      final bloc = HadithComparisonBloc(GetHadithReadingComparison(repo));
      addTearDown(bloc.close);
      expect(bloc.state.status, HadithComparisonStatus.initial);
      expect(repo.comparisonRequests, isEmpty);
    });
  });

  group('HadithDashboardBloc with a picked month', () {
    test('asks for that whole month, and the competitor follows', () async {
      final repo = _FakeRepository();
      final dashboard = HadithDashboardBloc(GetHadithReadingHistory(repo));
      final comparison = HadithComparisonBloc(GetHadithReadingComparison(repo));
      addTearDown(dashboard.close);
      addTearDown(comparison.close);

      // A leap-year February long ago, so the result doesn't depend on today.
      final month = DateTime(2020, 2);
      // Listen to both before sending anything: a bloc stream doesn't replay.
      final dashboardDone = dashboard.stream.firstWhere((s) => !s.isLoading);
      final comparisonDone = comparison.stream.firstWhere(
        (s) => s.status != HadithComparisonStatus.loading,
      );
      dashboard.add(
        LoadHadithDashboard(HadithHistoryPeriod.monthly, month: month),
      );
      comparison.add(
        LoadHadithComparison(HadithHistoryPeriod.monthly, month: month),
      );
      final state = await dashboardDone;
      final compared = await comparisonDone;

      const expected = (from: '2020-02-01', to: '2020-02-29');
      expect(repo.requests.single, expected);
      expect(repo.comparisonRequests.single, expected);
      expect(state.month, month);
      expect(compared.month, month);
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
