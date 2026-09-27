import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/core/utils/localized_text.dart';
import 'package:islami_app_noorify/features/dashboard/presentation/bloc/quiz_dashboard_bloc.dart';
import 'package:islami_app_noorify/features/dashboard/presentation/screens/quiz_dashboard_screen.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz_attempt.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz_dashboard.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz_enums.dart';
import 'package:islami_app_noorify/features/quiz/domain/repositories/quiz_repository.dart';
import 'package:islami_app_noorify/features/quiz/domain/usecases/get_quiz_attempt_review.dart';
import 'package:islami_app_noorify/features/quiz/domain/usecases/get_quiz_attempts.dart';
import 'package:islami_app_noorify/features/quiz/domain/usecases/get_quiz_dashboard.dart';
import 'package:islami_app_noorify/features/quiz/domain/usecases/get_quiz_dashboard_comparison.dart';
import 'package:islami_app_noorify/features/quiz/presentation/bloc/quiz_attempt_review_bloc.dart';
import 'package:islami_app_noorify/features/quiz/presentation/bloc/quiz_bloc.dart';
import 'package:islami_app_noorify/features/quiz/presentation/screens/completed_history_screen.dart';
import 'package:islami_app_noorify/features/quiz/presentation/screens/quiz_attempt_review_screen.dart';
import 'package:islami_app_noorify/shared/bloc/language/language_bloc.dart';

const _meta = PaginationMeta(page: 1, limit: 7, total: 7, totalPage: 1);

QuizDashboardDayMetric _day(String date, int attempts) =>
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
      totalPoints: 1.88 * attempts,
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

QuizDashboardData _dashboard() => QuizDashboardData(
  from: '2026-09-20',
  to: '2026-09-26',
  period: QuizDashboardPeriod.weekly,
  days: [for (var d = 20; d <= 26; d++) _day('2026-09-$d', d.isEven ? 1 : 0)],
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
        dashboard: _dashboard(),
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
}) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final language = LanguageBloc();
  if (bangla) language.add(const UpdateLanguage(AppLanguage.bangla));
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, child) => BlocProvider.value(
        value: language,
        child: MaterialApp(home: screen),
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
