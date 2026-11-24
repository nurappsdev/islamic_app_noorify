import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/core/utils/app_color.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_dashboard_charts.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/features/dashboard/presentation/bloc/quiz_dashboard_bloc.dart';
import 'package:tuhfatul_muslim/features/dashboard/presentation/screens/quiz_dashboard_screen.dart';
import 'package:tuhfatul_muslim/features/quiz/domain/entities/quiz.dart';
import 'package:tuhfatul_muslim/features/quiz/domain/entities/quiz_attempt.dart';
import 'package:tuhfatul_muslim/features/quiz/domain/entities/quiz_dashboard.dart';
import 'package:tuhfatul_muslim/features/quiz/domain/entities/quiz_enums.dart';
import 'package:tuhfatul_muslim/features/quiz/domain/repositories/quiz_repository.dart';
import 'package:tuhfatul_muslim/features/quiz/domain/usecases/get_quiz_attempt_review.dart';
import 'package:tuhfatul_muslim/features/quiz/domain/usecases/get_quiz_attempts.dart';
import 'package:tuhfatul_muslim/features/quiz/domain/usecases/get_quiz_dashboard.dart';
import 'package:tuhfatul_muslim/features/quiz/domain/usecases/get_quiz_dashboard_comparison.dart';
import 'package:tuhfatul_muslim/features/quiz/presentation/bloc/quiz_attempt_review_bloc.dart';
import 'package:tuhfatul_muslim/features/quiz/presentation/bloc/quiz_bloc.dart';
import 'package:tuhfatul_muslim/features/quiz/presentation/screens/completed_history_screen.dart';
import 'package:tuhfatul_muslim/features/quiz/presentation/screens/quiz_attempt_review_screen.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';

const _meta = PaginationMeta(page: 1, limit: 7, total: 7, totalPage: 1);

/// `YYYY-MM-DD` for the day [back] days before today.
///
/// The dashboard's weekly window is the seven days ENDING TODAY, so a fixture
/// pinned to a fixed month would fall outside every window the selector ever
/// shows and every bar would read zero.
String _isoDaysAgo(int back) {
  final now = DateTime.now();
  final date = DateTime(now.year, now.month, now.day - back);
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

QuizDashboardDayMetric _day(String date, int attempts, {num? points}) =>
    QuizDashboardDayMetric(
      date: date,
      attempts: attempts,
      totalQuestions: 12 * attempts,
      correctAnswers: 9 * attempts,
      answeredQuestions: 11 * attempts,
      unansweredQuestions: attempts,
      wrongAnswers: 2 * attempts,
      answeredPercentage: 91.67,
      correctPercentage: 75,
      accuracyPercentage: 81.82,
      totalSeconds: 150 * attempts,
      totalMinutes: 2.5 * attempts,
      totalPoints: points ?? 1.88 * attempts,
      bestScorePercentage: 75,
      averageScorePercentage: 75,
    );

const _totals = QuizDashboardTotals(
  attempts: 3,
  totalQuestions: 36,
  correctAnswers: 27,
  answeredQuestions: null, // a legacy attempt in range
  unansweredQuestions: null,
  wrongAnswers: null,
  answeredPercentage: null,
  correctPercentage: 75,
  accuracyPercentage: null,
  totalSeconds: 450,
  totalMinutes: 7.5,
  totalPoints: 5.64,
  bestScorePercentage: 92,
  averageScorePercentage: 75,
  daysTracked: 2,
  currentStreak: 1,
  averageMinutesPerDay: 1.07,
);

QuizDashboardData _dashboard({List<QuizDashboardDayMetric>? days}) =>
    QuizDashboardData(
      from: _isoDaysAgo(6),
      to: _isoDaysAgo(0),
      period: QuizDashboardPeriod.weekly,
      days:
          days ??
          // 1.2 points on the day before yesterday, as the reader described.
          [
            for (var back = 6; back >= 0; back--)
              _day(
                _isoDaysAgo(back),
                back.isEven ? 1 : 0,
                points: back == 2 ? 1.2 : null,
              ),
          ],
      totals: _totals,
      meta: _meta,
    );

QuizComparison _comparison() => QuizComparison(
  from: '2026-09-20',
  to: '2026-09-26',
  period: QuizDashboardPeriod.weekly,
  comparedWith: 'first_place',
  users: [
    for (final (key, rank, me, name) in [
      ('user1', 7, true, 'Me Myself'),
      ('user2', 1, false, 'A Very Long Leaderboard Leader Name'),
    ])
      QuizComparedUser(
        key: key,
        rank: rank,
        isCurrentUser: me,
        userId: key,
        name: name,
        avatarUrl: null,
        totalPoints: me ? 120.5 : 3400,
        // The server sends a day only for a reader active on it, so the
        // rival answers just the one: 2 points the day before yesterday,
        // against my 1.2 there.
        dashboard: me
            ? _dashboard()
            : _dashboard(days: [_day(_isoDaysAgo(2), 1, points: 2)]),
      ),
  ],
  difference: const QuizComparisonDifference(
    attempts: -2,
    totalPoints: -3.5,
    totalMinutes: 4,
    correctPercentage: 6.25,
    isAhead: false,
  ),
  meta: _meta,
);

EvaluatedQuestion _question(String id, QuizAnswerStatus status) =>
    EvaluatedQuestion(
      id: id,
      categoryId: 'c',
      category: null,
      question: LocalizedText(bn: 'প্রশ্ন $id', en: 'Question $id'),
      options: const [
        QuizOption(
          key: 'A',
          text: LocalizedText(bn: '৩', en: '3'),
        ),
        QuizOption(
          key: 'C',
          text: LocalizedText(bn: '৫', en: '5'),
        ),
      ],
      checkedBy: status == QuizAnswerStatus.unanswered ? null : 'A',
      correctAnswerKey: 'C',
      explanation: const LocalizedText(bn: 'ব্যাখ্যা', en: 'Because'),
      difficulty: QuizDifficulty.medium,
      difficultyLabel: const LocalizedText(bn: 'মধ্যম', en: 'Medium'),
      displayOrder: 1,
      isActive: true,
      isCorrect: status == QuizAnswerStatus.correct,
      status: status,
    );

/// Answers every call with canned data.
class _FakeRepository implements QuizRepository {
  @override
  Future<Either<Failure, QuizDashboardData>> getQuizDashboard(
    QuizDashboardFilter filter,
  ) async => Right(_dashboard());

  @override
  Future<Either<Failure, QuizComparison>> getQuizDashboardComparison(
    QuizComparisonFilter filter,
  ) async => Right(_comparison());

  @override
  Future<Either<Failure, QuizComparison>> getQuizDashboardHistoryComparison(
    QuizComparisonFilter filter,
  ) async => Right(_comparison());

  @override
  Future<Either<Failure, QuizAttemptPage>> getAttempts({
    int page = 1,
    int limit = 10,
    QuizAttemptType? attemptType,
  }) async => Right(
    QuizAttemptPage(
      summary: const QuizAttemptSummary(
        attempts: 1,
        bestScorePercentage: 92,
        averageScorePercentage: 92,
      ),
      attempts: [
        QuizAttempt(
          id: 'att1',
          attemptType: QuizAttemptType.daily,
          quizId: 'quiz',
          category: null,
          totalQuestions: 12,
          correctAnswers: 11,
          incorrectAnswers: 1,
          scorePercentage: 92,
          pointsEarned: 2.3,
          maxPoints: 2.5,
          timeSpentSeconds: 180,
          used5050Lifeline: false,
          completedAt: DateTime(2026, 9, 26, 10),
        ),
      ],
      page: 1,
      totalPage: 1,
    ),
  );

  @override
  Future<Either<Failure, QuizAttemptDetail>> getAttemptReview(
    String attemptId,
  ) async {
    final questions = [
      _question('q1', QuizAnswerStatus.correct),
      _question('q2', QuizAnswerStatus.incorrect),
      _question('q3', QuizAnswerStatus.unanswered),
    ];
    return Right(
      QuizAttemptDetail(
        attempt: QuizAttempt(
          id: attemptId,
          attemptType: QuizAttemptType.daily,
          quizId: 'quiz',
          category: null,
          totalQuestions: 3,
          correctAnswers: 1,
          incorrectAnswers: 2,
          scorePercentage: 33,
          pointsEarned: 0.83,
          maxPoints: 2.5,
          timeSpentSeconds: 95,
          used5050Lifeline: false,
          completedAt: DateTime(2026, 9, 26, 8),
        ),
        planId: null,
        portionId: null,
        answeredQuestions: 2,
        unansweredQuestions: 1,
        wrongAnswers: 1,
        answeredPercentage: 66.67,
        correctPercentage: 33.33,
        accuracyPercentage: 50,
        questions: questions,
        review: QuizAttemptReview(
          correct: [questions[0]],
          incorrect: [questions[1]],
          unanswered: [questions[2]],
        ),
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  bool bangla = false,
  Brightness? brightness,
}) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final language = LanguageBloc(initialLanguage: AppLanguage.english);
  if (bangla) language.add(const UpdateLanguage(AppLanguage.bangla));
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, child) => BlocProvider.value(
        value: language,
        // A `Theme` rather than `MaterialApp.darkTheme`: MaterialApp animates
        // a theme change, so a single pump would still report light. Omitting
        // `brightness` leaves the tree exactly as the other tests pump it.
        child: MaterialApp(
          home: brightness == null
              ? screen
              : Theme(
                  data: ThemeData(brightness: brightness),
                  child: screen,
                ),
        ),
      ),
    ),
  );
  // Until the fake repository has answered and every spinner is gone; a
  // fixed number of frames is flaky when the machine is busy.
  for (var i = 0; i < 100; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
  }
}

Widget _noTooltip(int index, DuaChartBar bar) => const SizedBox.shrink();

/// The base color of the period heading ("Today's - Average Score : 75%").
///
/// Every [Text] also builds a [RichText], so the screen's own one is picked
/// out by its shape: two spans, the first of them italic.
Color? _headingColor(WidgetTester tester) {
  for (final rich in tester.widgetList<RichText>(find.byType(RichText))) {
    final span = rich.text;
    if (span is TextSpan &&
        span.children?.length == 2 &&
        span.children!.first is TextSpan &&
        (span.children!.first as TextSpan).style?.fontStyle ==
            FontStyle.italic) {
      return span.style?.color;
    }
  }
  return null;
}

/// Scrolls [list] down step by step until [target] is built.
Future<bool> _scrollTo(WidgetTester tester, Finder list, Finder target) async {
  for (var i = 0; i < 30; i++) {
    if (target.evaluate().isNotEmpty) return true;
    await tester.drag(list, const Offset(0, -150));
    await tester.pump();
  }
  return target.evaluate().isNotEmpty;
}

void main() {
  final repo = _FakeRepository();

  Widget dashboard() => MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (_) => QuizDashboardBloc(
          getDashboard: GetQuizDashboard(repo),
          getComparison: GetQuizDashboardComparison(repo),
        )..add(const LoadQuizDashboard()),
      ),
      BlocProvider(
        create: (_) =>
            QuizBloc(GetQuizAttempts(repo))
              ..add(const LoadCompletedQuizHistory()),
      ),
    ],
    child: const QuizDashboardScreen(),
  );

  group('period charts', () {
    // Daily compares two totals, so it keeps the donut; weekly and monthly
    // show the window day by day with the shared bar charts, as the Hadith
    // dashboard does.
    testWidgets('daily keeps the donut, weekly and monthly use bar charts', (
      tester,
    ) async {
      await _pump(tester, dashboard());
      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.byType(DuaWeeklyBarChart), findsNothing);
      expect(find.byType(DuaMonthlyBarChart), findsNothing);

      await tester.tap(find.text('Weekly'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(DuaWeeklyBarChart), findsOneWidget);
      expect(find.byType(DuaMonthlyBarChart), findsNothing);

      await tester.tap(find.text('Monthly'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(DuaMonthlyBarChart), findsOneWidget);
      expect(find.byType(DuaWeeklyBarChart), findsNothing);
    });

    // The fake answers seven dated days, one bar each, labelled by weekday.
    testWidgets('the weekly chart draws one bar per day of the week', (
      tester,
    ) async {
      await _pump(tester, dashboard());
      await tester.tap(find.text('Weekly'));
      await tester.pumpAndSettle();

      final chart = tester.widget<DuaWeeklyBarChart>(
        find.byType(DuaWeeklyBarChart),
      );
      expect(chart.bars.length, 7);
      // Short, Sunday-first labels - a seven-column axis has no room for
      // "Wednesday".
      expect(chart.bars.map((bar) => bar.label), contains('Sun'));
      expect(chart.bars.every((bar) => bar.label.length <= 3), isTrue);
      // _day() gives the even dates of 20-26 September one attempt each, so
      // some bars carry points and some are empty.
      expect(chart.bars.any((bar) => bar.mine > 0), isTrue);
    });

    // Every week of the month, not only the weeks the answer happened to
    // mention: the window decides the rows now, so a quiet week is a real
    // zero row rather than a missing one.
    testWidgets('the monthly chart groups the month into week rows', (
      tester,
    ) async {
      await _pump(tester, dashboard());
      await tester.tap(find.text('Monthly'));
      await tester.pumpAndSettle();

      final chart = tester.widget<DuaMonthlyBarChart>(
        find.byType(DuaMonthlyBarChart),
      );
      final now = DateTime.now();
      final lastDay = DateTime(now.year, now.month + 1, 0).day;
      expect(chart.bars.map((bar) => bar.title), [
        '1-7',
        '8-14',
        '15-21',
        '22-$lastDay',
      ]);
      // The axis prints the row's last day; the span is the tooltip title.
      expect(chart.bars.map((bar) => bar.label), ['7', '14', '21', '$lastDay']);
    });

    // The reader's report: on a day they scored 1.2 and the other reader
    // scored 2, the column came out in their colour alone, with no sign of
    // the gap. Two causes: the series walked only MY days, so a day the
    // rival scored on carried no rival figure at all, and the fractional
    // points were rounded to integers, which flattened the difference.
    testWidgets('a day both readers scored on shows both layers and the gap', (
      tester,
    ) async {
      await _pump(tester, dashboard());
      await tester.tap(find.text('Weekly'));
      await tester.pumpAndSettle();

      final chart = tester.widget<DuaWeeklyBarChart>(
        find.byType(DuaWeeklyBarChart),
      );
      // The seven days of the window, not just the days either reader was
      // active on - the rival's answer carries only one day.
      expect(chart.bars.length, 7);

      // Index 4 is the day before yesterday: mine 1.2, theirs 2.
      final day = chart.bars[4];
      expect(day.mine, 120, reason: '1.2 points, scaled - not rounded to 1');
      expect(day.competitor, 200, reason: "the rival's own 2 points");
      expect(
        day.competitor,
        greaterThan(day.mine),
        reason: 'the taller rival layer is what makes the gap visible',
      );

      // The axis divides the scale back out, so it still reads in points.
      expect(chart.axisLabel, isNotNull);
      expect(chart.axisLabel!(200), '2');
      expect(chart.axisLabel!(50), '0.5');

      // A day only I scored on still carries a real zero for the rival, so
      // the layer is drawn rather than left off.
      expect(chart.bars.every((bar) => bar.competitor >= 0), isTrue);
      expect(chart.bars.where((bar) => bar.competitor > 0), hasLength(1));
    });

    // Rounding used to drop a day under half a point to an empty column.
    testWidgets('a fraction of a point still draws a column', (tester) async {
      await _pump(tester, dashboard());
      await tester.tap(find.text('Weekly'));
      await tester.pumpAndSettle();
      final chart = tester.widget<DuaWeeklyBarChart>(
        find.byType(DuaWeeklyBarChart),
      );
      // 1.2 would have rounded to 1 against a rival's 2; worse, anything
      // below 0.5 became 0. Scaled, every fraction survives.
      expect(chart.bars[4].mine, isNot(1));
      expect(chart.bars[4].mine, greaterThan(0));
    });

    // The bars were drawing in the Dua palette while the legend right above
    // them named this screen's own two colours, so "My Position" meant one
    // green in the legend and a different one in the chart.
    testWidgets('the bars are drawn in this screen\'s own legend colours', (
      tester,
    ) async {
      await _pump(tester, dashboard());
      expect(find.text('My Position'), findsOneWidget);

      await tester.tap(find.text('Weekly'));
      await tester.pumpAndSettle();
      final weekly = tester.widget<DuaWeeklyBarChart>(
        find.byType(DuaWeeklyBarChart),
      );
      expect(weekly.palette.mine.toARGB32(), 0xFF5D896D);
      expect(weekly.palette.competitor.toARGB32(), 0xFFA9B258);
      expect(
        weekly.palette.mine.toARGB32(),
        isNot(DuaChartColors.mine.toARGB32()),
        reason: 'not the Dua palette the charts default to',
      );

      await tester.tap(find.text('Monthly'));
      await tester.pumpAndSettle();
      final monthly = tester.widget<DuaMonthlyBarChart>(
        find.byType(DuaMonthlyBarChart),
      );
      expect(monthly.palette.mine.toARGB32(), 0xFF5D896D);
      expect(monthly.palette.competitor.toARGB32(), 0xFFA9B258);
    });

    // The override is opt-in: anything that does not pass a palette - the Dua
    // and Hadith dashboards - keeps the colours it always had.
    test('the shared charts still default to the Dua palette', () {
      expect(
        DuaChartPalette.dua.mine.toARGB32(),
        DuaChartColors.mine.toARGB32(),
      );
      expect(
        DuaChartPalette.dua.mineStrong.toARGB32(),
        DuaChartColors.mineStrong.toARGB32(),
      );
      expect(
        DuaChartPalette.dua.competitor.toARGB32(),
        DuaChartColors.competitor.toARGB32(),
      );
      expect(
        const DuaWeeklyBarChart(
          bars: [],
          tooltipBuilder: _noTooltip,
        ).palette.mine.toARGB32(),
        DuaChartColors.mine.toARGB32(),
      );
      expect(
        const DuaMonthlyBarChart(
          bars: [],
          tooltipBuilder: _noTooltip,
        ).palette.mine.toARGB32(),
        DuaChartColors.mine.toARGB32(),
      );
    });

    testWidgets('the bar charts render in dark mode too', (tester) async {
      await _pump(tester, dashboard(), brightness: Brightness.dark);
      await tester.tap(find.text('Weekly'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(DuaWeeklyBarChart), findsOneWidget);
    });
  });

  group('dark theme', () {
    // The heading's base style was a hardcoded `Colors.black`, so in dark mode
    // the whole line - the period and the average score - rendered black on a
    // near-black page and read as missing.
    testWidgets('the period heading uses theme ink, not hardcoded black', (
      tester,
    ) async {
      await _pump(tester, dashboard(), brightness: Brightness.dark);
      expect(tester.takeException(), isNull);

      final color = _headingColor(tester);
      expect(color, isNotNull, reason: 'the period heading should be built');
      expect(
        color!.toARGB32(),
        isNot(const Color(0xFF000000).toARGB32()),
        reason: 'black on a dark page is unreadable',
      );
      expect(color.toARGB32(), AppColor.darkTextPrimary.toARGB32());
    });

    // Light mode must be untouched: every mapper returns its argument when the
    // brightness is light, so the design color has to come back unchanged.
    testWidgets('the period heading keeps the design black in light mode', (
      tester,
    ) async {
      await _pump(tester, dashboard(), brightness: Brightness.light);
      expect(
        _headingColor(tester)?.toARGB32(),
        const Color(0xFF000000).toARGB32(),
      );
    });

    testWidgets('the dashboard renders in dark mode without overflowing', (
      tester,
    ) async {
      await _pump(tester, dashboard(), brightness: Brightness.dark);
      expect(tester.takeException(), isNull);
      expect(find.textContaining('Leader'), findsWidgets);
    });
  });

  for (final bangla in [false, true]) {
    final lang = bangla ? 'Bangla' : 'English';

    testWidgets('dashboard renders API data ($lang)', (tester) async {
      await _pump(tester, dashboard(), bangla: bangla);
      expect(tester.takeException(), isNull);
      expect(find.textContaining('Leader'), findsWidgets);
      if (!bangla) {
        // The comparison card is hidden.
        expect(find.text('You'), findsNothing);
        expect(find.text("You're behind"), findsNothing);
      }
      // Scroll the whole page to lay out every section.
      await tester.drag(find.byType(ListView).first, const Offset(0, -3000));
      await tester.pump();
      expect(tester.takeException(), isNull);
      if (!bangla) {
        final list = find.byType(Scrollable).first;
        await tester.drag(list, const Offset(0, 5000));
        await tester.pump();
        // The stats card, the activity chart and the comparison card are
        // hidden, all the way down to the page's end; the history remains.
        expect(
          await _scrollTo(tester, list, find.text('Current Streak')),
          isFalse,
        );
        expect(find.text('Daily Activity'), findsNothing);
        expect(find.text('Comparison'), findsNothing);
        expect(find.text('Best Score'), findsNothing);
        expect(find.text('Daily Quiz'), findsOneWidget);
      }
    });

    testWidgets('competitor popup: name, points and a usable close button '
        '($lang)', (tester) async {
      await _pump(tester, dashboard(), bangla: bangla);
      final name = find.text('A Very Long Leaderboard Leader Name');
      expect(name, findsOneWidget);
      // A long name gets two lines before it is cut short.
      expect(tester.widget<Text>(name).maxLines, 2);
      final close = find.byIcon(Icons.close_rounded);
      expect(close, findsOneWidget);
      // The close button sits wholly inside the card, so nothing clips it.
      final card = find.ancestor(of: name, matching: find.byType(Container));
      final cardRect = tester.getRect(card.last);
      final closeRect = tester.getRect(
        find.ancestor(of: close, matching: find.byType(IconButton)),
      );
      expect(cardRect.contains(closeRect.topLeft), isTrue);
      expect(cardRect.contains(closeRect.bottomRight), isTrue);
      // The points sit right under the name.
      final points = find.descendant(
        of: card.last,
        matching: find.textContaining(' : '),
      );
      expect(
        tester.getTopLeft(points.first).dy - tester.getBottomLeft(name).dy,
        lessThan(20),
      );
      await tester.tap(close);
      await tester.pump();
      expect(name, findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('review renders every status ($lang)', (tester) async {
      await _pump(
        tester,
        BlocProvider(
          create: (_) => QuizAttemptReviewBloc(
            GetQuizAttemptReview(repo),
            attemptId: 'att1',
          )..add(const LoadQuizAttemptReview()),
          child: const QuizAttemptReviewScreen(),
        ),
        bangla: bangla,
      );
      expect(tester.takeException(), isNull);
      expect(
        find.text(bangla ? '১. প্রশ্ন q1' : '1. Question q1'),
        findsOneWidget,
      );
      if (!bangla) {
        // The Incorrect tab lists only the server's incorrect group.
        await tester.tap(find.text('Incorrect (1)'));
        await tester.pump();
        expect(find.text('2. Question q2'), findsOneWidget);
        expect(find.text('1. Question q1'), findsNothing);
        await tester.tap(find.text('Unanswered (1)'));
        await tester.pump();
        expect(find.text('3. Question q3'), findsOneWidget);
        expect(find.text('Not answered'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('history renders without the comparison ($lang)', (
      tester,
    ) async {
      await _pump(
        tester,
        MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) =>
                  QuizBloc(GetQuizAttempts(repo))
                    ..add(const LoadCompletedQuizHistory()),
            ),
          ],
          child: const CompletedHistoryScreen(),
        ),
        bangla: bangla,
      );
      // Like the route, no comparison bloc is provided: the screen must not
      // need one while the card is hidden.
      expect(tester.takeException(), isNull);
      expect(find.textContaining('Leader'), findsNothing);
      // Each attempt carries its date; the summary card is hidden.
      expect(
        find.text(
          bangla
              ? 'দৈনিক কুইজ - ২৬ সেপ্টেম্বর ২০২৬'
              : 'Daily Quiz - 26 September 2026',
        ),
        findsOneWidget,
      );
      if (!bangla) {
        expect(find.text('Best Score'), findsNothing);
        expect(find.text('Average Score'), findsNothing);
      }
    });
  }
}
