import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/core/storage/hive_service.dart';
import 'package:islami_app_noorify/core/utils/localized_text.dart';
import 'package:islami_app_noorify/features/planner/domain/entities/quiz_plan.dart';
import 'package:islami_app_noorify/features/planner/domain/repositories/quiz_plan_repository.dart';
import 'package:islami_app_noorify/features/planner/domain/usecases/abandon_quiz_plan.dart';
import 'package:islami_app_noorify/features/planner/domain/usecases/create_quiz_plan.dart';
import 'package:islami_app_noorify/features/planner/domain/usecases/get_planned_questions.dart';
import 'package:islami_app_noorify/features/planner/domain/usecases/get_quiz_plan.dart';
import 'package:islami_app_noorify/features/planner/domain/usecases/get_quiz_plans.dart';
import 'package:islami_app_noorify/features/planner/domain/usecases/start_quiz_plan.dart';
import 'package:islami_app_noorify/features/planner/domain/usecases/submit_planned_quiz.dart';
import 'package:islami_app_noorify/features/planner/domain/usecases/update_quiz_plan.dart';
import 'package:islami_app_noorify/features/planner/presentation/bloc/create_quiz_plan_bloc.dart';
import 'package:islami_app_noorify/features/planner/presentation/bloc/planned_quiz_bloc.dart';
import 'package:islami_app_noorify/features/planner/presentation/bloc/planner_bloc.dart';
import 'package:islami_app_noorify/features/planner/presentation/bloc/quiz_plan_detail_bloc.dart';
import 'package:islami_app_noorify/features/planner/presentation/screens/create_plan_screen.dart';
import 'package:islami_app_noorify/features/planner/presentation/screens/planned_quiz_result_screen.dart';
import 'package:islami_app_noorify/features/planner/presentation/screens/planned_quiz_screen.dart';
import 'package:islami_app_noorify/features/planner/presentation/screens/planner_detail_screen.dart';
import 'package:islami_app_noorify/features/planner/presentation/screens/planner_screen.dart';
import 'package:islami_app_noorify/features/planner/presentation/widgets/quiz_plan_widgets.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz_category.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz_dashboard.dart';
import 'package:islami_app_noorify/features/quiz/domain/entities/quiz_enums.dart';
import 'package:islami_app_noorify/features/quiz/domain/repositories/quiz_repository.dart';
import 'package:islami_app_noorify/features/quiz/domain/usecases/get_quiz_categories.dart';
import 'package:islami_app_noorify/shared/bloc/language/language_bloc.dart';

const _name = LocalizedText(bn: 'হাদিস ও সুন্নাহ', en: 'Hadith & Sunnah');

QuizPlanPortion _portion(int order, {bool done = false}) => QuizPlanPortion(
  id: 'p$order',
  order: order,
  categoryId: 'cat1',
  categoryName: _name,
  difficulty: null,
  totalQuestions: 15,
  isCompleted: done,
  attemptId: done ? 'att$order' : null,
  scorePercentage: done ? 92 : null,
  completedAt: done ? DateTime(2026, 9, 26, 12) : null,
);

QuizPlan _plan(String id, QuizPlanStatus status, {String? name}) {
  final portions = [
    _portion(1, done: status != QuizPlanStatus.planned),
    _portion(2),
  ];
  return QuizPlan(
    id: id,
    name: name ?? 'A Rather Long Evening Practice Plan Name',
    scheduledAt: DateTime(2026, 9, 30, 18),
    startedAt: status == QuizPlanStatus.planned ? null : DateTime(2026, 9, 26),
    createdAt: DateTime(2026, 9, 26),
    status: status,
    rawStatus: status.apiValue.isEmpty ? 'paused' : status.apiValue,
    totalQuizzes: 2,
    completedQuizzes: status == QuizPlanStatus.planned ? 0 : 1,
    remainingQuizzes: status == QuizPlanStatus.planned ? 2 : 1,
    totalQuestions: 30,
    completionPercentage: status == QuizPlanStatus.planned ? 0 : 50,
    portions: portions,
  );
}

PlannedQuestion _question(int order) => PlannedQuestion(
  id: 'q$order',
  categoryId: 'cat1',
  question: LocalizedText(bn: 'প্রশ্ন $order', en: 'Question $order'),
  options: const [
    QuizOption(
      key: 'A',
      text: LocalizedText(bn: 'ক', en: 'a'),
    ),
    QuizOption(
      key: 'B',
      text: LocalizedText(bn: 'খ', en: 'b'),
    ),
  ],
  difficulty: QuizDifficulty.easy,
  checkedBy: null,
  portionId: 'p1',
  questionOrder: order,
);

class _FakePlans implements QuizPlanRepository {
  @override
  Future<Either<Failure, QuizPlanPage>> getPlans({
    int page = 1,
    int limit = 10,
  }) async => Right(
    QuizPlanPage(
      plans: [
        _plan('a', QuizPlanStatus.planned, name: 'Evening Practice'),
        _plan('b', QuizPlanStatus.inProgress),
        _plan('c', QuizPlanStatus.abandoned, name: 'Old Plan'),
        _plan('d', QuizPlanStatus.unknown, name: 'Future Status Plan'),
      ],
      meta: const PaginationMeta(page: 1, limit: 10, total: 4, totalPage: 1),
    ),
  );

  @override
  Future<Either<Failure, QuizPlan>> getPlan(String planId) async =>
      Right(_plan(planId, QuizPlanStatus.inProgress));

  @override
  Future<Either<Failure, PlannedQuestionPage>> getQuestions({
    required String planId,
    String? portionId,
    String? categoryId,
    int page = 1,
    int limit = 10,
  }) async => Right(
    PlannedQuestionPage(
      questions: [_question(1)],
      meta: const PaginationMeta(page: 1, limit: 10, total: 1, totalPage: 1),
    ),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Remembers the plan it was asked to create.
class _CapturingPlans extends _FakePlans {
  QuizPlanDraft? created;

  @override
  Future<Either<Failure, QuizPlan>> createPlan(QuizPlanDraft draft) async {
    created = draft;
    return Right(_plan('new', QuizPlanStatus.planned, name: draft.name));
  }
}

class _FakeCategories implements QuizRepository {
  @override
  Future<Either<Failure, List<QuizCategory>>> getCategories() async =>
      const Right([
        QuizCategory(
          id: 'cat1',
          name: _name,
          description: LocalizedText.empty,
          iconUrl: null,
          displayOrder: 1,
          totalQuestions: LocalizedCount(
            value: 17,
            text: LocalizedText(bn: '১৭', en: '17'),
          ),
          isActive: true,
        ),
      ]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  bool bangla = false,
  RouteFactory? onGenerateRoute,
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
        child: MaterialApp(home: screen, onGenerateRoute: onGenerateRoute),
      ),
    ),
  );
  for (var i = 0; i < 100; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
  }
}

void main() {
  final plans = _FakePlans();

  setUpAll(() async {
    // A signed-in session, as the Planner shows a login prompt to guests.
    final dir = await Directory.systemTemp.createTemp('quiz_plan_test');
    Hive.init(dir.path);
    await Hive.openBox<dynamic>(HiveService.authBox);
    await Hive.box<dynamic>(HiveService.authBox).put('auth_token', 'tkn');
  });

  QuizPlanDetailBloc detailBloc() => QuizPlanDetailBloc(
    planId: 'b',
    getPlan: GetQuizPlan(plans),
    startPlan: StartQuizPlan(plans),
    updatePlan: UpdateQuizPlan(plans),
    abandonPlan: AbandonQuizPlan(plans),
  );

  testWidgets('Create Plan opens on the app void routes and adds the plan', (
    tester,
  ) async {
    await _pump(
      tester,
      BlocProvider(
        create: (_) => PlannerBloc(
          getPlans: GetQuizPlans(plans),
          updatePlan: UpdateQuizPlan(plans),
          abandonPlan: AbandonQuizPlan(plans),
        ),
        child: const PlannerScreen(),
      ),
      // Built exactly like the app's routes: MaterialPageRoute<void>.
      onGenerateRoute: (settings) => MaterialPageRoute<void>(
        settings: settings,
        builder: (context) => Scaffold(
          body: settings.name == RouteNames.createPlan
              ? TextButton(
                  onPressed: () => Navigator.of(context).pop(
                    _plan('new', QuizPlanStatus.planned, name: 'Brand New'),
                  ),
                  child: const Text('pop with plan'),
                )
              : const SizedBox(),
        ),
      ),
    );
    await tester.tap(find.text('Create Plan'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('pop with plan'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Brand New'), findsOneWidget);
    expect(find.text('Plan created'), findsOneWidget);
  });

  group('Create Plan sends the quiz on the form', () {
    Future<_CapturingPlans> open(WidgetTester tester) async {
      final capturing = _CapturingPlans();
      await _pump(
        tester,
        BlocProvider(
          create: (_) => CreateQuizPlanBloc(
            getCategories: GetQuizCategories(_FakeCategories()),
            createPlan: CreateQuizPlan(capturing),
          )..add(const LoadQuizPlanCategories()),
          child: const CreatePlanScreen(),
        ),
      );
      await tester.enterText(find.byType(TextField), 'Evening practice');
      await tester.tap(find.text('Eg : Quranic science'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hadith & Sunnah (17)'));
      await tester.pumpAndSettle();
      return capturing;
    }

    testWidgets('a category alone, then Create, without Add', (tester) async {
      final capturing = await open(tester);
      // Picking the category filled in sensible counts.
      expect(find.text('1'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();
      expect(find.text('Add at least one quiz.'), findsNothing);
      final portions = capturing.created?.portions;
      expect(portions, hasLength(1));
      expect(portions!.single.categoryId, 'cat1');
      expect(portions.single.quizCount, 1);
      expect(portions.single.questionCount, 10);
    });

    testWidgets('Add, then Create, sends it once', (tester) async {
      final capturing = await open(tester);
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();
      expect(capturing.created?.portions, hasLength(1));
    });

    testWidgets('nothing picked: asks for a quiz', (tester) async {
      final capturing = _CapturingPlans();
      await _pump(
        tester,
        BlocProvider(
          create: (_) => CreateQuizPlanBloc(
            getCategories: GetQuizCategories(_FakeCategories()),
            createPlan: CreateQuizPlan(capturing),
          )..add(const LoadQuizPlanCategories()),
          child: const CreatePlanScreen(),
        ),
      );
      await tester.enterText(find.byType(TextField), 'Evening practice');
      await tester.tap(find.text('Create'));
      await tester.pump();
      expect(find.text('Add at least one quiz.'), findsOneWidget);
      expect(capturing.created, isNull);
    });
  });

  for (final bangla in [false, true]) {
    final lang = bangla ? 'Bangla' : 'English';

    testWidgets('plans list: actions by status, tabs ($lang)', (tester) async {
      await _pump(
        tester,
        BlocProvider(
          create: (_) => PlannerBloc(
            getPlans: GetQuizPlans(plans),
            updatePlan: UpdateQuizPlan(plans),
            abandonPlan: AbandonQuizPlan(plans),
          ),
          child: const PlannerScreen(),
        ),
        bangla: bangla,
      );
      expect(tester.takeException(), isNull);
      if (!bangla) {
        expect(find.text('Evening Practice'), findsOneWidget);
        expect(find.text('Start'), findsOneWidget);
        expect(find.text('Continue'), findsOneWidget);
        // An unknown status is shown as sent, with no action.
        expect(find.text('paused'), findsOneWidget);
        expect(find.text('Old Plan'), findsNothing);
        await tester.tap(find.text('Complete Plan'));
        await tester.pump();
        await tester.pump();
        expect(find.text('Old Plan'), findsOneWidget);
        expect(find.text('Abandoned'), findsOneWidget);
        expect(find.text('Start'), findsNothing);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('plan details: portions and scores ($lang)', (tester) async {
      await _pump(
        tester,
        BlocProvider(
          create: (_) => detailBloc()..add(const LoadQuizPlanDetail()),
          child: const PlannerDetailScreen(initialTitle: ''),
        ),
        bangla: bangla,
      );
      expect(tester.takeException(), isNull);
      if (!bangla) {
        expect(find.textContaining('Score: 92%'), findsOneWidget);
        expect(find.text('Not completed'), findsOneWidget);
        expect(find.text('Continue'), findsOneWidget);
        expect(find.text('Quizzes'), findsNothing);
        expect(find.text('Remaining'), findsNothing);
      }
    });

    testWidgets('planned quiz renders its question ($lang)', (tester) async {
      final plan = _plan('b', QuizPlanStatus.inProgress);
      await _pump(
        tester,
        BlocProvider(
          create: (_) => PlannedQuizBloc(
            plan: plan,
            portion: plan.portions.last,
            getQuestions: GetPlannedQuestions(plans),
            submit: SubmitPlannedQuiz(plans),
            tickInterval: const Duration(hours: 1),
          )..add(const LoadPlannedQuestions()),
          child: const PlannedQuizScreen(),
        ),
        bangla: bangla,
      );
      expect(tester.takeException(), isNull);
      // Question text is shown exactly as the server wrote it.
      expect(find.text(bangla ? 'প্রশ্ন 1' : 'Question 1'), findsOneWidget);
      if (!bangla) expect(find.text('Submit'), findsOneWidget);
    });

    testWidgets('planned result shows the server score ($lang)', (
      tester,
    ) async {
      final plan = _plan('b', QuizPlanStatus.inProgress);
      await _pump(
        tester,
        BlocProvider(
          create: (_) => detailBloc()..add(const LoadQuizPlanDetail()),
          child: PlannedQuizResultScreen(
            args: PlannedQuizResultArgs(
              plan: plan,
              portion: plan.portions.first,
              questions: [_question(1), _question(2)],
              result: PlannedQuizResult(
                id: 'att1',
                planId: 'b',
                portionId: 'p1',
                attemptType: QuizAttemptType.plan,
                answeredQuestions: 1,
                unansweredQuestions: 1,
                wrongAnswers: 0,
                answeredPercentage: 50,
                correctPercentage: 50,
                accuracyPercentage: 100,
                totalQuestions: 2,
                correctAnswers: 1,
                incorrectAnswers: 1,
                scorePercentage: 50,
                pointsEarned: 0,
                maxPoints: 2.5,
                amol: null,
                timeSpentSeconds: 42,
                completedAt: DateTime(2026, 9, 26),
                answers: const [
                  PlannedAnswerResult(
                    questionId: 'q1',
                    checkedBy: 'A',
                    correctAnswerKey: 'A',
                    isCorrect: true,
                  ),
                  PlannedAnswerResult(
                    questionId: 'q2',
                    checkedBy: null,
                    correctAnswerKey: 'B',
                    isCorrect: false,
                  ),
                ],
              ),
            ),
          ),
        ),
        bangla: bangla,
      );
      expect(tester.takeException(), isNull);
      if (!bangla) {
        expect(find.text('Next Quiz'), findsOneWidget);
        expect(find.text('Not answered'), findsOneWidget);
        // Plan quizzes earn no points: none shown.
        expect(find.text('Points'), findsNothing);
      }
    });

    testWidgets('create plan form ($lang)', (tester) async {
      await _pump(
        tester,
        BlocProvider(
          create: (_) => CreateQuizPlanBloc(
            getCategories: GetQuizCategories(_FakeCategories()),
            createPlan: CreateQuizPlan(plans),
          )..add(const LoadQuizPlanCategories()),
          child: const CreatePlanScreen(),
        ),
        bangla: bangla,
      );
      expect(tester.takeException(), isNull);
      if (!bangla) {
        await tester.tap(find.text('Eg : Quranic science'));
        await tester.pumpAndSettle();
        expect(find.text('Hadith & Sunnah (17)'), findsOneWidget);
      }
    });

    testWidgets('create plan header back button is aligned to the left ($lang)', (
      tester,
    ) async {
      await _pump(
        tester,
        Navigator(
          onGenerateRoute: (_) => MaterialPageRoute(
            builder: (_) => BlocProvider(
              create: (_) => CreateQuizPlanBloc(
                getCategories: GetQuizCategories(_FakeCategories()),
                createPlan: CreateQuizPlan(plans),
              )..add(const LoadQuizPlanCategories()),
              child: const CreatePlanScreen(),
            ),
          ),
        ),
        bangla: bangla,
      );
      await tester.pumpAndSettle();

      final iconButton = find.byType(IconButton);
      expect(iconButton, findsOneWidget);
      final buttonTopLeft = tester.getTopLeft(iconButton);
      final buttonTopRight = tester.getTopRight(iconButton);
      expect(buttonTopLeft.dx, lessThan(40));

      final title = find.text(bangla ? 'পরিকল্পনা তৈরি করুন' : 'Create Plan');
      expect(title, findsOneWidget);
      final titleTopLeft = tester.getTopLeft(title);
      expect(titleTopLeft.dx, greaterThanOrEqualTo(buttonTopRight.dx));

      await tester.tap(iconButton);
      await tester.pumpAndSettle();
    });
  }
}

