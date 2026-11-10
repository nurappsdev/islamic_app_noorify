import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/features/quiz/domain/entities/daily_quiz_status.dart';
import 'package:tuhfatul_muslim/features/quiz/domain/entities/quiz_category.dart';
import 'package:tuhfatul_muslim/features/quiz/domain/repositories/quiz_repository.dart';
import 'package:tuhfatul_muslim/features/quiz/domain/usecases/get_daily_quiz_status.dart';
import 'package:tuhfatul_muslim/features/quiz/domain/usecases/get_quiz_categories.dart';
import 'package:tuhfatul_muslim/features/quiz/presentation/bloc/quiz_categories_bloc.dart';
import 'package:tuhfatul_muslim/features/quiz/presentation/cubit/daily_quiz_status_cubit.dart';
import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/features/quiz/data/models/quiz_attempt_model.dart';
import 'package:tuhfatul_muslim/features/quiz/domain/entities/quiz.dart';
import 'package:tuhfatul_muslim/features/quiz/domain/entities/quiz_enums.dart';
import 'package:tuhfatul_muslim/features/quiz/presentation/quiz_route_args.dart';
import 'package:tuhfatul_muslim/features/quiz/presentation/screens/quiz_completion_screen.dart';
import 'package:tuhfatul_muslim/features/quiz/presentation/screens/quiz_categories_screen.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';

class _FakeQuizRepository implements QuizRepository {
  _FakeQuizRepository({this.status});

  final DailyQuizStatus? status;

  @override
  Future<Either<Failure, List<QuizCategory>>> getCategories() async =>
      const Right([
        QuizCategory(
          id: 'cat1',
          name: LocalizedText(bn: 'হাদিস', en: 'Hadith'),
          description: LocalizedText.empty,
          iconUrl: null,
          displayOrder: 1,
          totalQuestions: LocalizedCount(
            value: 10,
            text: LocalizedText(bn: '১০', en: '10'),
          ),
          isActive: true,
        ),
      ]);

  @override
  Future<Either<Failure, DailyQuizStatus>> getDailyQuizStatus() async =>
      Right(status ?? const DailyQuizStatus(date: '2026-09-26'));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pump(
  WidgetTester tester, {
  required QuizRepository repository,
  bool bangla = false,
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
        child: MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) =>
                    QuizCategoriesBloc(GetQuizCategories(repository))
                      ..add(const LoadQuizCategories()),
              ),
              BlocProvider(
                create: (_) =>
                    DailyQuizStatusCubit(GetDailyQuizStatus(repository))
                      ..load(),
              ),
            ],
            child: const QuizCategoriesScreen(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'QuizCategoriesScreen shows challenge banner when not completed',
    (tester) async {
      final repo = _FakeQuizRepository(
        status: const DailyQuizStatus(
          date: '2026-09-26',
          isAvailable: true,
          isCompleted: false,
        ),
      );
      await _pump(tester, repository: repo);

      expect(find.textContaining('challenge'), findsOneWidget);
      expect(find.textContaining('Start'), findsOneWidget);
    },
  );

  testWidgets(
    'QuizCategoriesScreen shows completed banner with points when completed',
    (tester) async {
      final repo = _FakeQuizRepository(
        status: const DailyQuizStatus(
          date: '2026-09-26',
          isAvailable: true,
          isCompleted: true,
          pointsEarned: 2.5,
        ),
      );
      await _pump(tester, repository: repo);

      expect(find.textContaining('You completed your'), findsOneWidget);
      expect(find.textContaining('2.5'), findsOneWidget);
      expect(find.textContaining('Start'), findsNothing);
    },
  );

  testWidgets('one of two daily quizzes done: progress and the next quiz', (
    tester,
  ) async {
    final repo = _FakeQuizRepository(
      status: const DailyQuizStatus(
        date: '2026-09-26',
        isAvailable: true,
        quizzesPerDay: 2,
        completedQuizzes: 1,
        nextSequence: 2,
        pointsEarned: 1.5,
      ),
    );
    await _pump(tester, repository: repo);

    expect(find.textContaining('challenge'), findsOneWidget);
    expect(find.text('1 of 2 quizzes done'), findsOneWidget);
    expect(find.text('Start quiz 2'), findsOneWidget);
    expect(find.textContaining('You completed your'), findsNothing);
  });

  testWidgets('a result with another daily quiz to come offers it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _FakeQuizRepository();
    Object? opened;
    Widget result(DailyQuizProgress daily) => ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, child) => BlocProvider(
        create: (_) => LanguageBloc(initialLanguage: AppLanguage.english),
        child: MaterialApp(
          onGenerateRoute: (settings) {
            if (settings.name == RouteNames.quizQuestion) {
              opened = settings.arguments;
              return MaterialPageRoute<void>(
                builder: (_) => const Text('Quiz screen'),
              );
            }
            return null;
          },
          home: BlocProvider(
            create: (_) =>
                QuizCategoriesBloc(GetQuizCategories(repository))
                  ..add(const LoadQuizCategories()),
            child: QuizCompletionScreen(
              args: QuizCompletionArgs(
                result: QuizAttemptResultModel.fromJson(const {
                  'id': 'att1',
                  'attemptType': 'daily',
                  'totalQuestions': 12,
                  'correctAnswers': 9,
                  'scorePercentage': 75,
                  'pointsEarned': 1.5,
                }),
                launch: const QuizLaunchArgs.daily(),
                daily: daily,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpWidget(
      result(
        const DailyQuizProgress(
          sequence: 1,
          quizzesPerDay: 2,
          completedQuizzes: 0,
          dayCompleted: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('You completed\nquiz 1 of 2'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('quiz-next-daily')));
    await tester.pumpAndSettle();
    expect(find.text('Quiz screen'), findsOneWidget);
    expect((opened as QuizLaunchArgs?)?.attemptType, QuizAttemptType.daily);

    // The day's last quiz: the usual "completed today's challenge".
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      result(
        const DailyQuizProgress(
          sequence: 2,
          quizzesPerDay: 2,
          completedQuizzes: 1,
          dayCompleted: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('You completed your'), findsOneWidget);
    expect(find.byKey(const ValueKey('quiz-next-daily')), findsNothing);
  });
}
