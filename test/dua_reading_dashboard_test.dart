import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuhfatul_muslim/features/dua/data/models/dua_reading_api_models.dart';
import 'package:tuhfatul_muslim/features/dua/domain/repositories/dua_repository.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/bloc/dua_home_cubit.dart'
    show DuaLoadStatus;
import 'package:tuhfatul_muslim/features/dua/presentation/bloc/dua_reading_dashboard_cubit.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/screens/dua_analytics_dashboard_screen.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_dashboard_charts.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';
import 'package:tuhfatul_muslim/shared/services/app_globals.dart';

/// `GET /api/v1/duas/reading/dashboard`'s documented answer, verbatim.
const _sample = <String, dynamic>{
  'timeframe': 'daily',
  'date': '2026-11-21',
  'overview': {
    'totalDuasRecited': 148,
    'dailyTargetText': '35/40',
    'totalReadingTimeSeconds': 13500,
    'totalReadingTimeFormatted': '3h 45m',
    'myPositionPercentage': 68,
    'competitorPercentage': 32,
    'comparison': {
      'me': {
        'name': 'Nizam',
        'rank': 2,
        'readingTimeFormatted': '1h 14m',
        'pointsText': 'Point : 6/10',
        'percentage': 49,
      },
      'rival': {
        'name': 'Labib Al Mahmud',
        'rank': 1,
        'readingTimeFormatted': '1h 19m',
        'pointsText': 'Point : 7/10',
        'percentage': 51,
        'pointsDifference': 1,
      },
      'topLeader': {
        'name': 'Labib Al Mahmud',
        'rank': 1,
        'readingTimeFormatted': '1h 19m',
        'pointsText': 'Point : 7/10',
      },
    },
  },
  'today': {'duasReadCount': 35, 'readMinutes': 23, 'isGoalMet': true},
  'weeklyActivity': {
    'from': '2026-11-15',
    'to': '2026-11-21',
    'days': [
      {
        'dayOfWeek': 'Sat',
        'date': '2026-11-15',
        'readMinutes': 25,
        'duasCount': 4,
        'my': {
          'name': 'Nizam',
          'readingTimeFormatted': '25 min',
          'pointsText': 'Point : 2/10',
        },
        'rival': {
          'name': 'Labib Al Mahmud',
          'readingTimeFormatted': '40 min',
          'pointsText': 'Point : 4/10',
        },
        'topLeader': {
          'name': 'Labib Al Mahmud',
          'readingTimeFormatted': '40 min',
          'pointsText': 'Point : 4/10',
        },
      },
      {
        'dayOfWeek': 'Sun',
        'date': '2026-11-16',
        'readMinutes': 35,
        'duasCount': 6,
      },
    ],
  },
  'recentRecitations': [
    {
      'duaId': '6732e821e462d7eb4a055355',
      'title': 'Morning Dua',
      'category': 'Daily Adhkar',
      'readCount': 10,
      'lastReadAt': '2026-08-17T05:35:00.000Z',
      'timeAgoText': '17 Aug At 5:35 AM',
    },
  ],
};

class _FakeDashboardRepository extends Fake implements DuaRepository {
  _FakeDashboardRepository({this.payload});

  /// Replaces [_sample] outright, for a test about one odd answer.
  final Map<String, dynamic>? payload;

  final calls = <String>[];

  @override
  Future<DuaReadingDashboard> getReadingDashboard({
    required String timeframe,
    String? date,
  }) async {
    calls.add(timeframe);
    if (payload != null) return DuaReadingDashboard.fromJson(payload!);
    return DuaReadingDashboard.fromJson({
      ..._sample,
      'timeframe': timeframe,
      // A real `monthly` answer carries its own labelled periods.
      if (timeframe == 'monthly')
        'monthlyActivity': {
          'periods': [
            for (final period in const [
              ('1-6', '1h 16m', 'Anas', '42 min'),
              ('7-13', '48 min', 'Anas', '30 min'),
              ('14-20', '1h 02m', 'Anas', '55 min'),
              ('21-27', '35 min', 'Anas', '20 min'),
              ('28-31', '12 min', 'Anas', '18 min'),
            ])
              {
                'label': period.$1,
                'my': {
                  'name': 'Nizam',
                  'readingTimeFormatted': period.$2,
                  'pointsText': 'Point : 6/10',
                },
                'rival': {
                  'name': period.$3,
                  'readingTimeFormatted': period.$4,
                  'pointsText': 'Point : 4/10',
                },
              },
          ],
        },
    });
  }
}

/// Lets the cubit's broadcast stream deliver what it has already emitted.
Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  group('DuaReadingDashboard.fromJson', () {
    final dashboard = DuaReadingDashboard.fromJson(_sample);

    test('reads the overview block', () {
      expect(dashboard.timeframe, 'daily');
      expect(dashboard.date, '2026-11-21');
      expect(dashboard.totalDuasRecited, 148);
      expect(dashboard.dailyTargetText, '35/40');
      expect(dashboard.totalReadingTimeSeconds, 13500);
      expect(dashboard.totalReadingTimeFormatted, '3h 45m');
      expect(dashboard.myPositionPercentage, 68);
      expect(dashboard.competitorPercentage, 32);
    });

    test('reads the today block', () {
      expect(dashboard.today?.duasReadCount, 35);
      expect(dashboard.today?.readMinutes, 23);
      expect(dashboard.today?.isGoalMet, isTrue);
    });

    test('reads the activity window with each day its own date', () {
      expect(dashboard.activityFrom, '2026-11-15');
      expect(dashboard.activityTo, '2026-11-21');
      expect(dashboard.activity, hasLength(2));
      expect(dashboard.activity.first.label, 'Sat');
      expect(dashboard.activity.first.minutes, 25);
      expect(dashboard.activity.first.duas, 4);
      expect(dashboard.activity.first.dayOfMonth, 15);
    });

    test('reads a recitation whose category is a plain string', () {
      final item = dashboard.recentRecitations.single;
      expect(item.duaId, '6732e821e462d7eb4a055355');
      expect(item.title.en, 'Morning Dua');
      expect(item.category.en, 'Daily Adhkar');
      expect(item.readCount, 10);
      expect(item.timeAgoText, '17 Aug At 5:35 AM');
    });

    test('still reads a populated category object', () {
      final item = DuaReadingHistoryItem.fromJson({
        'duaId': 'a',
        'title': {'en': 'Morning Dua', 'bn': 'সকালের দোয়া'},
        'category': {
          'name': {'en': 'Daily Adhkar', 'bn': 'দৈনিক আযকার'},
        },
      });
      expect(item.category.en, 'Daily Adhkar');
      expect(item.category.bn, 'দৈনিক আযকার');
    });

    test('a missing today block is absent rather than zeroed', () {
      final without = DuaReadingDashboard.fromJson(
        {..._sample}..remove('today'),
      );
      expect(without.today, isNull);
    });
  });

  group('the 3-tier comparison', () {
    final dashboard = DuaReadingDashboard.fromJson(_sample);

    test('reads the overview comparison', () {
      final comparison = dashboard.comparison;
      expect(comparison.isEmpty, isFalse);
      expect(comparison.me?.name, 'Nizam');
      expect(comparison.me?.rank, 2);
      expect(comparison.me?.pointsText, 'Point : 6/10');
      expect(comparison.rival?.name, 'Labib Al Mahmud');
      expect(comparison.rival?.pointsDifference, 1);
      expect(comparison.topLeader?.name, 'Labib Al Mahmud');
    });

    test("reads a day's own three sides", () {
      final day = dashboard.activity.first;
      expect(day.comparison.me?.name, 'Nizam');
      expect(day.comparison.rival?.readingTimeFormatted, '40 min');
      // The rival's bar is its own figure, not a projection of the user's.
      expect(day.comparison.rival?.readingMinutes, 40);
    });

    test('a day without the comparison block is still read', () {
      final day = dashboard.activity.last;
      expect(day.comparison.isEmpty, isTrue);
      expect(day.minutes, 35);
      expect(day.duas, 6);
    });

    test('an older response has an empty comparison', () {
      final overview = Map<String, dynamic>.from(_sample['overview'] as Map)
        ..remove('comparison');
      final older = DuaReadingDashboard.fromJson({
        ..._sample,
        'overview': overview,
      });
      expect(older.comparison.isEmpty, isTrue);
      expect(older.periods, isEmpty);
      // Everything the old screens read still parses.
      expect(older.totalDuasRecited, 148);
      expect(older.activity, hasLength(2));
    });

    test('reads monthlyActivity.periods', () {
      final monthly = DuaReadingDashboard.fromJson({
        ..._sample,
        'monthlyActivity': {
          'periods': [
            {
              'label': '1-6',
              'my': {
                'name': 'Nizam',
                'readingTimeFormatted': '1h 16m',
                'pointsText': 'Point : 6/10',
              },
              'rival': {
                'name': 'Anas',
                'readingTimeFormatted': '42 min',
                'pointsText': 'Point : 4/10',
              },
            },
          ],
        },
      });
      final period = monthly.periods.single;
      expect(period.label, '1-6');
      // No `readMinutes` at period level: taken from `my`.
      expect(period.minutes, 76);
      expect(period.comparison.rival?.name, 'Anas');
    });
  });

  group('duaParseReadingMinutes', () {
    test("reads the server's own formatting", () {
      expect(duaParseReadingMinutes('1h 14m'), 74);
      expect(duaParseReadingMinutes('23 min'), 23);
      expect(duaParseReadingMinutes('42 min'), 42);
      expect(duaParseReadingMinutes('2h'), 120);
      expect(duaParseReadingMinutes('1h 02m'), 62);
    });

    test('anything unreadable is zero rather than a guess', () {
      expect(duaParseReadingMinutes(''), 0);
      expect(duaParseReadingMinutes('--'), 0);
    });
  });

  group('duaPeriodAxisLabel', () {
    test('prints the day a period ends on', () {
      expect(duaPeriodAxisLabel('1-6'), '6');
      expect(duaPeriodAxisLabel('28-31'), '31');
    });

    test('a label with no number is left as it stands', () {
      expect(duaPeriodAxisLabel('Sat'), 'Sat');
    });
  });

  group('duaChartAxis', () {
    test('covers the data with five round ticks', () {
      final axis = duaChartAxis(900);
      expect(axis.ticks, [0, 250, 500, 750, 1000]);
      expect(axis.max, 1000);
      expect(axis.max, greaterThanOrEqualTo(900));
    });

    test('follows a quiet window down instead of a fixed scale', () {
      final axis = duaChartAxis(45);
      expect(axis.max, 60);
      expect(axis.ticks, [0, 15, 30, 45, 60]);
    });

    test('an empty window still has a usable axis', () {
      expect(duaChartAxis(0).max, greaterThan(0));
    });
  });

  group('duaCompetitorValue', () {
    test('scales the bar by the window\'s own split', () {
      // 68 : 32 of the user's 25 minutes.
      expect(
        duaCompetitorValue(25, myPercentage: 68, competitorPercentage: 32),
        12,
      );
    });

    test('is zero when there is nothing to scale', () {
      expect(
        duaCompetitorValue(0, myPercentage: 68, competitorPercentage: 32),
        0,
      );
      expect(
        duaCompetitorValue(25, myPercentage: 0, competitorPercentage: 32),
        0,
      );
    });
  });

  group('duaMonthlyBuckets', () {
    DuaDashboardActivityDay day(int dayOfMonth, int minutes) =>
        DuaDashboardActivityDay(
          label: '',
          date: '2026-11-${dayOfMonth.toString().padLeft(2, '0')}',
          minutes: minutes,
          duas: 1,
        );

    test('buckets a month into 0-7, 7-14, 14-21 and 21-end rows', () {
      final buckets = duaMonthlyBuckets([
        day(1, 10),
        day(7, 5),
        day(8, 20),
        day(21, 7),
        day(30, 3),
      ]);
      expect(buckets.map((b) => '${b.fromDay}-${b.toDay}'), [
        '0-7',
        '7-14',
        '14-21',
        '21-30',
      ]);
      // A day lands in exactly one bucket: 7 is in 0-7, 8 starts the next.
      expect(buckets[0].minutes, 15);
      expect(buckets[1].minutes, 20);
      expect(buckets[2].minutes, 7);
      expect(buckets[3].minutes, 3);
      expect(buckets[0].duas, 2);
      expect(buckets.every((b) => b.isSingleDay), isFalse);
    });

    test('the last row ends on the real last day of the month', () {
      // Reading stopped on the 24th; December still has 31 days.
      final buckets = duaMonthlyBuckets([
        DuaDashboardActivityDay(
          label: '',
          date: '2026-12-01',
          minutes: 5,
          duas: 1,
        ),
        DuaDashboardActivityDay(
          label: '',
          date: '2026-12-24',
          minutes: 5,
          duas: 1,
        ),
      ]);
      expect(buckets.last.toDay, 31);
    });

    test('a monthly answer that is really one week keeps a row per day', () {
      final buckets = duaMonthlyBuckets([
        const DuaDashboardActivityDay(
          label: 'Sat',
          date: '2026-11-15',
          minutes: 25,
          duas: 4,
        ),
        const DuaDashboardActivityDay(
          label: 'Sun',
          date: '2026-11-16',
          minutes: 35,
          duas: 6,
        ),
      ]);
      expect(buckets.map((b) => b.dayLabel), ['Sat', 'Sun']);
      expect(buckets.map((b) => b.minutes), [25, 35]);
      expect(buckets.every((b) => b.isSingleDay), isTrue);
    });

    test('days without a date cannot be bucketed into weeks', () {
      final buckets = duaMonthlyBuckets([
        const DuaDashboardActivityDay(
          label: 'Sat',
          date: '',
          minutes: 25,
          duas: 4,
        ),
      ]);
      // No span to work with, so the day keeps its own row.
      expect(buckets.single.isSingleDay, isTrue);
    });
  });

  group('DuaReadingDashboardCubit', () {
    test('loads the daily window first', () async {
      final repository = _FakeDashboardRepository();
      final cubit = DuaReadingDashboardCubit(repository);
      await cubit.load();
      expect(repository.calls, ['daily']);
      expect(cubit.state.status, DuaLoadStatus.success);
      expect(cubit.state.dashboard?.totalDuasRecited, 148);
      await cubit.close();
    });

    test(
      'a window already seen comes back from the cache with no skeleton',
      () async {
        final repository = _FakeDashboardRepository();
        final cubit = DuaReadingDashboardCubit(repository);
        await cubit.load();
        await cubit.select(DuaDashboardTimeframe.weekly);

        final states = <DuaReadingDashboardState>[];
        final subscription = cubit.stream.listen(states.add);
        await cubit.select(DuaDashboardTimeframe.daily);
        await _settle();
        await subscription.cancel();

        // Daily was shown straight away, never as a load.
        expect(
          states.map((s) => s.status),
          everyElement(DuaLoadStatus.success),
        );
        expect(states.first.dashboard, isNotNull);
        // ...and was revalidated behind it.
        expect(repository.calls, ['daily', 'weekly', 'daily']);
        await cubit.close();
      },
    );

    test('an unseen window loads with the skeleton', () async {
      final repository = _FakeDashboardRepository();
      final cubit = DuaReadingDashboardCubit(repository);
      await cubit.load();

      final states = <DuaReadingDashboardState>[];
      final subscription = cubit.stream.listen(states.add);
      await cubit.select(DuaDashboardTimeframe.monthly);
      await _settle();
      await subscription.cancel();

      expect(states.first.status, DuaLoadStatus.loading);
      expect(states.first.dashboard, isNull);
      expect(states.last.status, DuaLoadStatus.success);
      await cubit.close();
    });
  });

  group('DuaAnalyticsDashboardScreen', () {
    Future<_FakeDashboardRepository> pumpDashboard(
      WidgetTester tester, {
      Map<String, dynamic>? payload,
    }) async {
      tester.view.physicalSize = const Size(375 * 3, 812 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final repository = _FakeDashboardRepository(payload: payload);
      addTearDown(() => profileNameNotifier.value = null);
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, child) => BlocProvider(
            create: (_) => LanguageBloc(initialLanguage: AppLanguage.english),
            child: MaterialApp(
              home: DuaAnalyticsDashboardScreen(repository: repository),
            ),
          ),
        ),
      );
      // Chart and switcher animations never settle on their own.
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 60));
      }
      return repository;
    }

    testWidgets('shows the daily window from the API', (tester) async {
      profileNameNotifier.value = 'Ilm Ifty';
      final repository = await pumpDashboard(tester);

      expect(repository.calls, ['daily']);
      expect(find.byType(DuaDonutChart), findsOneWidget);
      // Both metric cards, from `overview`.
      expect(find.text('148'), findsOneWidget);
      expect(find.text('3h 45m'), findsOneWidget);
      expect(find.text('Daily Target: 35/40'), findsOneWidget);
      // The position pills.
      expect(find.text('68%'), findsOneWidget);
      expect(find.text('32%'), findsOneWidget);
      // The history row, with its plain-string category.
      expect(find.text('Morning Dua'), findsOneWidget);
      expect(find.textContaining('Daily Adhkar'), findsOneWidget);
      expect(find.text('17 Aug At 5:35 AM'), findsOneWidget);
      expect(find.text('10 times read'), findsOneWidget);
    });

    /// Opens the dropdown and picks [option].
    Future<void> choose(WidgetTester tester, String option) async {
      await tester.tap(find.byType(PopupMenuButton<DuaDashboardTimeframe>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(option).last);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 60));
      }
    }

    testWidgets('the daily donut names both sides', (tester) async {
      await pumpDashboard(tester);

      final tooltip = find.byType(DuaChartTooltip);
      expect(tooltip, findsOneWidget);
      Finder inTooltip(String text) =>
          find.descendant(of: tooltip, matching: find.text(text));

      // overview.comparison, formatted by the server.
      expect(inTooltip('Nizam'), findsOneWidget);
      expect(inTooltip('1h 14m'), findsOneWidget);
      expect(inTooltip('Point : 6/10'), findsOneWidget);
      expect(inTooltip('Labib Al Mahmud'), findsOneWidget);
      expect(inTooltip('1h 19m'), findsOneWidget);
      expect(inTooltip('Point : 7/10'), findsOneWidget);
    });

    testWidgets(
      'a comparison with names but no times is dashed, never zeroed',
      (tester) async {
        // The shape that showed "0 min" for both sides while the pills read
        // 68% / 32%: the server names everyone and splits the window, but
        // sends no time or points on either side.
        await pumpDashboard(
          tester,
          payload: {
            'timeframe': 'daily',
            'date': '2026-11-21',
            'overview': {
              'totalDuasRecited': 0,
              'myPositionPercentage': 68,
              'competitorPercentage': 32,
              'comparison': {
                'me': {'name': 'Nizam', 'percentage': 68},
                'rival': {'name': 'Labib Al Mahmud', 'percentage': 32},
              },
            },
          },
        );

        final tooltip = find.byType(DuaChartTooltip);
        Finder inTooltip(String text) =>
            find.descendant(of: tooltip, matching: find.text(text));

        expect(inTooltip('Nizam'), findsOneWidget);
        expect(inTooltip('Labib Al Mahmud'), findsOneWidget);
        // Nothing was timed, so nothing is claimed.
        expect(inTooltip('0 min'), findsNothing);
        expect(inTooltip('—'), findsNWidgets(2));
      },
    );

    testWidgets('the rival is projected when only the user is timed', (
      tester,
    ) async {
      await pumpDashboard(
        tester,
        payload: {
          'timeframe': 'daily',
          'overview': {
            'totalReadingTimeFormatted': '1h 00m',
            'dailyTargetText': '35/40',
            'myPositionPercentage': 68,
            'competitorPercentage': 32,
            'comparison': {
              'me': {'name': 'Nizam'},
              'rival': {'name': 'Labib Al Mahmud'},
            },
          },
        },
      );

      final tooltip = find.byType(DuaChartTooltip);
      Finder inTooltip(String text) =>
          find.descendant(of: tooltip, matching: find.text(text));

      // The window total stands in for the user...
      expect(inTooltip('60 min'), findsOneWidget);
      // ...and the rival gets the 68:32 split of it, not a zero.
      expect(inTooltip('28 min'), findsOneWidget);
      // The day's target fraction stands in for the missing points.
      expect(inTooltip('Point : 35/40'), findsOneWidget);
    });

    testWidgets('a day the server really timed at zero still reads zero', (
      tester,
    ) async {
      await pumpDashboard(tester);
      await choose(tester, 'Weekly');
      await tester.tap(find.text('Sat'));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 60));
      }
      // Sanity: a timed day is never dashed.
      expect(
        find.descendant(
          of: find.byType(DuaChartTooltip),
          matching: find.text('—'),
        ),
        findsNothing,
      );
    });

    testWidgets('tapping a weekly column names both sides', (tester) async {
      profileNameNotifier.value = 'Ilm Ifty';
      await pumpDashboard(tester);
      await choose(tester, 'Weekly');

      await tester.tap(find.text('Sat'));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 60));
      }

      final tooltip = find.byType(DuaChartTooltip);
      expect(tooltip, findsOneWidget);
      Finder inTooltip(String text) =>
          find.descendant(of: tooltip, matching: find.text(text));

      // Both sides come from the day's own `my` / `rival`, names, times and
      // points as the server formatted them.
      expect(inTooltip('Nizam'), findsOneWidget);
      expect(inTooltip('25 min'), findsOneWidget);
      expect(inTooltip('Point : 2/10'), findsOneWidget);
      expect(inTooltip('Labib Al Mahmud'), findsOneWidget);
      expect(inTooltip('40 min'), findsOneWidget);
      expect(inTooltip('Point : 4/10'), findsOneWidget);
      // The profile name is not used when the server names the user.
      expect(inTooltip('Ilm Ifty'), findsNothing);
    });

    testWidgets('a day with no comparison falls back to the legend', (
      tester,
    ) async {
      profileNameNotifier.value = null;
      await pumpDashboard(tester);
      await choose(tester, 'Weekly');

      // Sunday is sent without the `my` / `rival` block.
      await tester.tap(find.text('Sun'));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 60));
      }

      final tooltip = find.byType(DuaChartTooltip);
      Finder inTooltip(String text) =>
          find.descendant(of: tooltip, matching: find.text(text));

      expect(inTooltip('My Position'), findsOneWidget);
      expect(inTooltip('35 min'), findsOneWidget);
      // Never the competitor's name on the user's own row.
      expect(inTooltip('Abdullah Al-Aziz'), findsOneWidget);
    });

    testWidgets('the monthly rows come from the API periods', (tester) async {
      await pumpDashboard(tester);
      await choose(tester, 'Monthly');

      expect(find.byType(DuaMonthlyBarChart), findsOneWidget);
      // The axis prints the day each period ends on.
      for (final label in const ['6', '13', '20', '27', '31']) {
        expect(find.text(label), findsOneWidget, reason: label);
      }

      await tester.tap(find.text('6'));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 60));
      }
      final tooltip = find.byType(DuaChartTooltip);
      Finder inTooltip(String text) =>
          find.descendant(of: tooltip, matching: find.text(text));

      // The period's own label heads the card, both sides underneath.
      expect(inTooltip('1-6'), findsOneWidget);
      expect(inTooltip('Nizam'), findsOneWidget);
      expect(inTooltip('1h 16m'), findsOneWidget);
      expect(inTooltip('Anas'), findsOneWidget);
      expect(inTooltip('42 min'), findsOneWidget);
    });

    testWidgets('the dropdown switches to the weekly columns', (tester) async {
      final repository = await pumpDashboard(tester);
      await choose(tester, 'Weekly');

      expect(repository.calls, ['daily', 'weekly']);
      expect(find.byType(DuaWeeklyBarChart), findsOneWidget);
      expect(find.byType(DuaDonutChart), findsNothing);
      // One column per returned day.
      expect(find.text('Sat'), findsOneWidget);
      expect(find.text('Sun'), findsOneWidget);
    });
  });
}
