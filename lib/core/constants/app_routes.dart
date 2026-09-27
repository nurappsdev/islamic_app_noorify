import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/presentation/screens/email_verification_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/auth/presentation/screens/signin_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/hadith/data/hadith_book_catalog.dart';
import '../../features/hadith/presentation/bloc/hadith_book/hadith_book_bloc.dart';
import '../../features/hadith/presentation/screens/hadith_book_reader_screen.dart';
import '../../features/hadith/presentation/screens/hadith_category_screen.dart';
import '../../features/hadith/presentation/screens/hadith_entry_screen.dart';
import '../../features/hadith/presentation/screens/hadith_ebook_list_screen.dart';
import '../../features/hadith/presentation/screens/hadith_library_list_screen.dart';
import '../../features/hadith/presentation/screens/hadith_create_plan_screen.dart';
import '../../features/hadith/presentation/screens/hadith_edit_plan_screen.dart';
import '../../features/hadith/presentation/screens/hadith_dashboard_screen.dart';
import '../../features/hadith/presentation/screens/hadith_detail_screen.dart';
import '../../features/hadith/presentation/screens/hadith_planner_screen.dart';
import '../../features/hadith/presentation/screens/hadith_reading_history_screen.dart';
import '../../features/hadith/presentation/screens/hadith_saved_screen.dart';
import '../../features/hadith/presentation/screens/hadith_sub_category_screen.dart';
import '../../features/hadith/presentation/screens/hadith_library_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/leaderboard/presentation/screens/leaderboard_screen.dart';
import '../../features/home/presentation/screens/prayer_times_screen.dart';
import '../../features/qiblah_compass/presentation/screens/qiblah_compass_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/profile_edit_screen.dart';
import '../../features/profile/presentation/screens/settings_screen.dart';
import '../../features/profile/presentation/screens/app_language_screen.dart';
import '../../features/profile/presentation/screens/family_members_screen.dart';
import '../../features/quiz/presentation/screens/quiz_categories_screen.dart';
import '../../features/quiz/presentation/screens/quiz_question_screen.dart';
import '../../features/quiz/presentation/screens/quiz_completion_screen.dart';
import '../../features/quiz/presentation/screens/quiz_list_screen.dart';
import '../../features/quiz/presentation/screens/completed_history_screen.dart';
import '../../features/quiz/presentation/screens/quiz_attempt_review_screen.dart';
import '../../features/quiz/presentation/screens/quiz_shell.dart';
import '../../features/quiz/data/datasources/quiz_remote_data_source.dart';
import '../../features/quiz/data/repositories/quiz_repository_impl.dart';
import '../../features/quiz/domain/repositories/quiz_repository.dart';
import '../../features/quiz/domain/usecases/get_category_quiz.dart';
import '../../features/quiz/domain/usecases/get_daily_quiz.dart';
import '../../features/quiz/domain/usecases/get_daily_quiz_status.dart';
import '../../features/quiz/domain/usecases/get_quiz_attempt_review.dart';
import '../../features/quiz/domain/usecases/get_quiz_attempts.dart';
import '../../features/quiz/domain/usecases/get_quiz_dashboard.dart';
import '../../features/quiz/domain/usecases/get_quiz_dashboard_comparison.dart';
// import '../../features/quiz/domain/usecases/get_quiz_dashboard_history_comparison.dart';
import '../../features/dashboard/presentation/bloc/quiz_dashboard_bloc.dart';
// import '../../features/quiz/presentation/bloc/quiz_comparison_bloc.dart';
import '../../features/quiz/domain/usecases/get_quiz_categories.dart';
import '../../features/quiz/domain/usecases/submit_quiz_attempt.dart';
import '../../features/quiz/presentation/bloc/quiz_attempt_review_bloc.dart';
import '../../features/quiz/presentation/bloc/quiz_bloc.dart';
import '../../features/quiz/presentation/bloc/quiz_categories_bloc.dart';
import '../../features/quiz/presentation/bloc/quiz_question_bloc.dart';
import '../../features/quiz/presentation/cubit/daily_quiz_status_cubit.dart';
import '../../features/quiz/presentation/quiz_route_args.dart';
import '../../features/learning/data/datasources/learning_remote_data_source.dart';
import '../../features/learning/data/repositories/learning_repository_impl.dart';
import '../../features/learning/domain/entities/article.dart';
import '../../features/learning/domain/repositories/learning_repository.dart';
import '../../features/learning/domain/usecases/get_article.dart';
import '../../features/learning/domain/usecases/get_article_categories.dart';
import '../../features/learning/domain/usecases/get_articles.dart';
import '../../features/learning/presentation/bloc/article_categories_bloc.dart';
import '../../features/learning/presentation/bloc/article_detail_bloc.dart';
import '../../features/learning/presentation/bloc/articles_bloc.dart';
import '../../features/learning/presentation/screens/learning_screen.dart';
import '../../features/planner/presentation/screens/planner_screen.dart';
import '../../features/planner/presentation/screens/planner_detail_screen.dart';
import '../../features/planner/presentation/screens/create_plan_screen.dart';
import '../../features/dashboard/presentation/screens/quiz_dashboard_screen.dart';
import '../../features/planner/data/datasources/quiz_plan_remote_data_source.dart';
import '../../features/planner/data/repositories/quiz_plan_repository_impl.dart';
import '../../features/planner/domain/entities/quiz_plan.dart';
import '../../features/planner/domain/repositories/quiz_plan_repository.dart';
import '../../features/planner/domain/usecases/abandon_quiz_plan.dart';
import '../../features/planner/domain/usecases/create_quiz_plan.dart';
import '../../features/planner/domain/usecases/get_planned_questions.dart';
import '../../features/planner/domain/usecases/get_quiz_plan.dart';
import '../../features/planner/domain/usecases/get_quiz_plans.dart';
import '../../features/planner/domain/usecases/start_quiz_plan.dart';
import '../../features/planner/domain/usecases/submit_planned_quiz.dart';
import '../../features/planner/domain/usecases/update_quiz_plan.dart';
import '../../features/planner/presentation/bloc/create_quiz_plan_bloc.dart';
import '../../features/planner/presentation/bloc/planned_quiz_bloc.dart';
import '../../features/planner/presentation/bloc/planner_bloc.dart';
import '../../features/planner/presentation/bloc/quiz_plan_detail_bloc.dart';
import '../../features/planner/presentation/screens/planned_quiz_result_screen.dart';
import '../../features/planner/presentation/screens/planned_quiz_screen.dart';
import '../../features/planner/presentation/widgets/quiz_plan_widgets.dart';
import '../../features/learning/presentation/screens/articles_screen.dart';
import '../../features/learning/presentation/screens/article_details_screen.dart';
import '../../features/learning/presentation/screens/learning_test_screen.dart';
import '../../features/learning/presentation/screens/learning_test_result_screen.dart';
import '../../features/quran/presentation/quran_route_args.dart';
import '../../features/quran/presentation/screens/quran_entry_screen.dart';
import '../../features/quran/presentation/screens/surah_list_screen.dart';
import '../../features/quran/presentation/screens/surah_detail_screen.dart';
import '../../features/quran/presentation/screens/full_surah_screen.dart';
import '../../features/quran/presentation/screens/verse_reader_screen.dart';
import '../../features/quran/presentation/screens/bookmarks_screen.dart';
import '../../features/quran/presentation/screens/reading_history_screen.dart';
import '../../features/quran/presentation/bloc/surah_detail/surah_detail_bloc.dart';
import '../../features/quran/presentation/bloc/verse_reader/verse_reader_bloc.dart';
import '../../features/quran/presentation/bloc/last_read/last_read_bloc.dart';
import '../../features/quran/presentation/bloc/bookmarks/bookmarks_bloc.dart';
import '../../features/quran/presentation/bloc/reading_history/reading_history_bloc.dart';
import '../../features/quran/presentation/bloc/reciter/reciter_bloc.dart';
import '../../features/quran/presentation/bloc/ayah_audio/ayah_audio_bloc.dart';
import '../../features/quran/presentation/bloc/surah_playback/surah_playback_bloc.dart';
import '../../features/quran/presentation/bloc/offline_quran/offline_quran_bloc.dart';
import '../../features/quran/presentation/bloc/surah_audio_download/surah_audio_download_bloc.dart';
import '../../features/quran/data/services/quran_audio_downloader.dart';
import '../../features/asma_husna/data/datasources/asma_husna_local_data_source.dart';
import '../../features/asma_husna/data/datasources/asma_husna_remote_data_source.dart';
import '../../features/asma_husna/data/repositories/asma_husna_repository_impl.dart';
import '../../features/asma_husna/domain/usecases/get_asma_names.dart';
import '../../features/asma_husna/presentation/bloc/asma_husna_bloc.dart';
import '../../features/asma_husna/presentation/screens/asma_husna_intro_screen.dart';
import '../../features/asma_husna/presentation/screens/asma_husna_list_screen.dart';
import '../../features/dua/data/dua_catalog.dart';
import '../../features/dua/presentation/screens/dua_all_category_screen.dart';
import '../../features/dua/presentation/screens/dua_all_dua_screen.dart';
import '../../features/dua/presentation/screens/dua_dashboard_screen.dart';
import '../../features/dua/presentation/screens/dua_featured_screen.dart';
import '../../features/dua/presentation/screens/dua_group_screen.dart';
import '../../features/dua/presentation/screens/dua_intro_screen.dart';
import '../../features/dua/presentation/screens/dua_reader_screen.dart';
import '../../features/dua/presentation/screens/dua_saved_screen.dart';
import '../../features/dua/presentation/dua_route_args.dart';
import '../../features/splash/screens/ramadan_splash_screen.dart';
import '../../features/zikr/presentation/screens/zikr_all_screen.dart';
import '../../features/zikr/data/zikr_catalog.dart';
import '../../features/zikr/presentation/screens/zikr_counter_screen.dart';
import '../../features/zikr/presentation/screens/zikr_create_screen.dart';
import '../../features/zikr/presentation/screens/zikr_dashboard_screen.dart';
import '../../features/zikr/presentation/screens/zikr_intro_screen.dart';
import '../../features/zikr/presentation/screens/zikr_plan_create_screen.dart';
import '../../features/zikr/presentation/screens/zikr_planner_screen.dart';
import '../../features/zikr/presentation/screens/zikr_set_screen.dart';
import '../../features/zikr/presentation/screens/zikr_stats_screen.dart';
import '../../features/zikr/presentation/zikr_route_args.dart';
import 'route_names.dart';

class AppRoutes {
  /// Shared by every quiz screen; created on first use.
  static final QuizRepository _quizRepository = QuizRepositoryImpl(
    QuizRemoteDataSourceImpl(),
  );

  /// Shared by the quiz plan screens; created on first use.
  static final QuizPlanRepository _quizPlanRepository = QuizPlanRepositoryImpl(
    QuizPlanRemoteDataSourceImpl(),
  );

  /// Shared by the Learning screens; keeps the articles read this session.
  static final LearningRepository _learningRepository = LearningRepositoryImpl(
    LearningRemoteDataSourceImpl(),
  );

  static QuizPlanDetailBloc _quizPlanDetailBloc(String planId) =>
      QuizPlanDetailBloc(
        planId: planId,
        getPlan: GetQuizPlan(_quizPlanRepository),
        startPlan: StartQuizPlan(_quizPlanRepository),
        updatePlan: UpdateQuizPlan(_quizPlanRepository),
        abandonPlan: AbandonQuizPlan(_quizPlanRepository),
      );

  /// Gives [child] the quiz categories and daily quiz status, fetched as it opens.
  static Widget _withQuizCategories(Widget child) => MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (_) =>
            QuizCategoriesBloc(GetQuizCategories(_quizRepository))
              ..add(const LoadQuizCategories()),
      ),
      BlocProvider(
        create: (_) =>
            DailyQuizStatusCubit(GetDailyQuizStatus(_quizRepository))..load(),
      ),
    ],
    child: child,
  );

  /// The Quiz & Learn section, opened on [tab], with its sticky nav bar.
  static Widget _quizShell(int tab) => QuizShell(
    initialTab: tab,
    tabs: [
      (_) => _withQuizCategories(const QuizCategoriesScreen()),
      (_) => MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) =>
                ArticleCategoriesBloc(GetArticleCategories(_learningRepository))
                  ..add(const LoadArticleCategories()),
          ),
          BlocProvider(
            // Only the latest few are previewed; See All opens the rest.
            create: (_) => ArticlesBloc(
              GetArticles(_learningRepository),
              scope: const ArticleListScope.all(),
              pageSize: 3,
            )..add(const LoadArticles()),
          ),
        ],
        child: const LearningScreen(),
      ),
      (_) => BlocProvider(
        // Loads its plans itself, once it knows the user is signed in.
        create: (_) => PlannerBloc(
          getPlans: GetQuizPlans(_quizPlanRepository),
          updatePlan: UpdateQuizPlan(_quizPlanRepository),
          abandonPlan: AbandonQuizPlan(_quizPlanRepository),
        ),
        child: const PlannerScreen(),
      ),
      (_) => MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => QuizDashboardBloc(
              getDashboard: GetQuizDashboard(_quizRepository),
              getComparison: GetQuizDashboardComparison(_quizRepository),
            )..add(const LoadQuizDashboard()),
          ),
          BlocProvider(
            // Only the latest few attempts are previewed here.
            create: (_) =>
                QuizBloc(GetQuizAttempts(_quizRepository), pageSize: 5)
                  ..add(const LoadCompletedQuizHistory()),
          ),
        ],
        child: const QuizDashboardScreen(),
      ),
    ],
  );

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.home:
        return _instantPage(const HomeScreen(), settings);
      case RouteNames.leaderboard:
        return _instantPage(const LeaderboardScreen(), settings);
      case RouteNames.profile:
        return _page(const ProfileScreen(), settings);
      case RouteNames.editProfile:
        return _page(const ProfileEditScreen(), settings);
      case RouteNames.settings:
        return _page(const SettingsScreen(), settings);
      case RouteNames.appLanguage:
        return _page(const AppLanguageScreen(), settings);
      case RouteNames.familyMembers:
        return _page(const FamilyMembersScreen(), settings);
      case RouteNames.winQuiz:
        return _page(_quizShell(0), settings);
      case RouteNames.quizQuestion:
        final launch = settings.arguments is QuizLaunchArgs
            ? settings.arguments as QuizLaunchArgs
            : const QuizLaunchArgs.daily();
        return _page(
          BlocProvider(
            create: (_) => QuizQuestionBloc(
              launch: launch,
              getDailyQuiz: GetDailyQuiz(_quizRepository),
              getCategoryQuiz: GetCategoryQuiz(_quizRepository),
              submitAttempt: SubmitQuizAttempt(_quizRepository),
            )..add(const LoadQuiz()),
            child: const QuizQuestionScreen(),
          ),
          settings,
        );
      case RouteNames.quizComplete:
        final args = settings.arguments;
        return _page(
          _withQuizCategories(
            QuizCompletionScreen(
              args: args is QuizCompletionArgs ? args : null,
            ),
          ),
          settings,
        );
      case RouteNames.quizList:
        return _page(_withQuizCategories(const QuizListScreen()), settings);
      case RouteNames.quizAttemptReview:
        final attemptId = settings.arguments as String? ?? '';
        return _page(
          BlocProvider(
            create: (_) => QuizAttemptReviewBloc(
              GetQuizAttemptReview(_quizRepository),
              attemptId: attemptId,
            )..add(const LoadQuizAttemptReview()),
            child: const QuizAttemptReviewScreen(),
          ),
          settings,
        );
      case RouteNames.learning:
        return _page(_quizShell(1), settings);
      case RouteNames.planner:
        return _page(_quizShell(2), settings);
      case RouteNames.plannerDetails:
        // A plan from the list, or just its id.
        final args = settings.arguments;
        final plan = args is QuizPlan ? args : null;
        final planId = plan?.id ?? (args is String ? args : '');
        return _page(
          BlocProvider(
            create: (_) =>
                _quizPlanDetailBloc(planId)..add(const LoadQuizPlanDetail()),
            child: PlannerDetailScreen(initialTitle: plan?.name ?? ''),
          ),
          settings,
        );
      case RouteNames.plannedQuiz:
        final args = settings.arguments as PlannedQuizArgs;
        return _page(
          BlocProvider(
            create: (_) => PlannedQuizBloc(
              plan: args.plan,
              portion: args.portion,
              getQuestions: GetPlannedQuestions(_quizPlanRepository),
              submit: SubmitPlannedQuiz(_quizPlanRepository),
            )..add(const LoadPlannedQuestions()),
            child: const PlannedQuizScreen(),
          ),
          settings,
        );
      case RouteNames.plannedQuizResult:
        final args = settings.arguments as PlannedQuizResultArgs;
        return _page(
          BlocProvider(
            // The plan's progress after this quiz, from the server.
            create: (_) =>
                _quizPlanDetailBloc(args.plan.id)
                  ..add(const LoadQuizPlanDetail()),
            child: PlannedQuizResultScreen(args: args),
          ),
          settings,
        );
      case RouteNames.createPlan:
        return _page(
          BlocProvider(
            create: (_) => CreateQuizPlanBloc(
              getCategories: GetQuizCategories(_quizRepository),
              createPlan: CreateQuizPlan(_quizPlanRepository),
            )..add(const LoadQuizPlanCategories()),
            child: const CreatePlanScreen(),
          ),
          settings,
        );
      case RouteNames.quizDashboard:
        return _page(_quizShell(3), settings);
      case RouteNames.completedHistory:
        return _page(
          MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) =>
                    QuizBloc(GetQuizAttempts(_quizRepository))
                      ..add(const LoadCompletedQuizHistory()),
              ),
              // The history comparison card is hidden for now; restore this
              // provider together with it.
              // BlocProvider(
              //   // The last seven days against the leaderboard leader.
              //   create: (_) => QuizComparisonBloc(
              //     GetQuizDashboardHistoryComparison(_quizRepository).call,
              //   )..add(const LoadQuizComparison()),
              // ),
            ],
            child: const CompletedHistoryScreen(),
          ),
          settings,
        );
      case RouteNames.learningArticles:
        // A category's articles, or all of them.
        final scope = settings.arguments is ArticleListScope
            ? settings.arguments as ArticleListScope
            : const ArticleListScope.all();
        return _page(
          BlocProvider(
            create: (_) =>
                ArticlesBloc(GetArticles(_learningRepository), scope: scope)
                  ..add(const LoadArticles()),
            child: const ArticlesScreen(),
          ),
          settings,
        );
      case RouteNames.learningArticleDetails:
        // Only the id travels; the full article is fetched here.
        final articleId = settings.arguments as String? ?? '';
        return _page(
          BlocProvider(
            create: (_) => ArticleDetailBloc(
              GetArticle(_learningRepository),
              articleId: articleId,
            )..add(const LoadArticle()),
            child: const ArticleDetailsScreen(),
          ),
          settings,
        );
      case RouteNames.learningTest:
        return _page(const LearningTestScreen(), settings);
      case RouteNames.learningTestResult:
        return _page(const LearningTestResultScreen(), settings);
      case RouteNames.quran:
        return _page(
          QuranEntryScreen(surahListBuilder: (_) => _surahListWithBlocs()),
          settings,
        );
      case RouteNames.quranSurahs:
        return _instantPage(_surahListWithBlocs(), settings);
      case RouteNames.quranSurahDetail:
        final args = settings.arguments;
        final surahNo = args is SurahRouteArgs
            ? args.surahNo
            : (args as int? ?? 1);
        final surahName = args is SurahRouteArgs ? args.surahName : '';
        final detailAudioDownloader = QuranAudioDownloader();
        return _page(
          MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) => SurahDetailBloc()..add(LoadSurahDetail(surahNo)),
              ),
              BlocProvider(
                create: (_) => ReciterBloc()..add(const LoadReciters()),
              ),
              BlocProvider(
                create: (_) => AyahAudioBloc(downloader: detailAudioDownloader),
              ),
              BlocProvider(
                create: (_) =>
                    SurahAudioDownloadBloc(downloader: detailAudioDownloader),
              ),
            ],
            child: SurahDetailScreen(surahNo: surahNo, surahName: surahName),
          ),
          settings,
        );
      case RouteNames.quranFullSurah:
        final surahNo = settings.arguments as int? ?? 1;
        final fullSurahAudioDownloader = QuranAudioDownloader();
        return _page(
          MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) => SurahDetailBloc()..add(LoadSurahDetail(surahNo)),
              ),
              BlocProvider(
                create: (_) => ReciterBloc()..add(const LoadReciters()),
              ),
              BlocProvider(
                create: (_) =>
                    SurahPlaybackBloc(downloader: fullSurahAudioDownloader),
              ),
              BlocProvider(
                create: (_) => SurahAudioDownloadBloc(
                  downloader: fullSurahAudioDownloader,
                ),
              ),
            ],
            child: FullSurahScreen(surahNo: surahNo),
          ),
          settings,
        );
      case RouteNames.quranJuzReader:
        final juzNumber = settings.arguments as int? ?? 1;
        return _page(
          BlocProvider(
            create: (_) => VerseReaderBloc()..add(LoadJuzVerses(juzNumber)),
            child: VerseReaderScreen(juzNumber: juzNumber),
          ),
          settings,
        );
      case RouteNames.quranBookmarks:
        return _page(
          BlocProvider(
            create: (_) => BookmarksBloc()..add(const LoadBookmarks()),
            child: const BookmarksScreen(),
          ),
          settings,
        );
      case RouteNames.quranReadingHistory:
        return _page(
          BlocProvider(
            create: (_) =>
                ReadingHistoryBloc()..add(const LoadReadingHistory()),
            child: const ReadingHistoryScreen(),
          ),
          settings,
        );
      case RouteNames.prayerTimes:
        return _page(const PrayerTimesScreen(), settings);
      case RouteNames.prayerCompass:
        final qiblahAngle = settings.arguments as double? ?? 270;
        return _page(QiblahCompassScreen(qiblahAngle: qiblahAngle), settings);
      case RouteNames.asma:
        return _page(
          BlocProvider(
            create: (_) => AsmaHusnaBloc(
              GetAsmaNames(
                AsmaHusnaRepositoryImpl(
                  AsmaHusnaRemoteDataSourceImpl(),
                  AsmaHusnaLocalDataSourceImpl(),
                ),
              ),
            )..add(const LoadAsmaNames()),
            child: const AsmaHusnaIntroScreen(),
          ),
          settings,
        );
      case RouteNames.asmaAll:
        return _page(
          BlocProvider(
            create: (_) => AsmaHusnaBloc(
              GetAsmaNames(
                AsmaHusnaRepositoryImpl(
                  AsmaHusnaRemoteDataSourceImpl(),
                  AsmaHusnaLocalDataSourceImpl(),
                ),
              ),
            )..add(const LoadAsmaNames()),
            child: const AsmaHusnaListScreen(),
          ),
          settings,
        );
      case RouteNames.hadith:
        // The intro only the first time; the library from then on.
        return _page(const HadithEntryScreen(), settings);
      case RouteNames.hadithLibrary:
        // No page transition: these four are the Hadith flow's bottom-nav
        // tabs, switched via HadithBottomNav — an animated slide/fade would
        // drag the (identically positioned) nav bar along with it, making it
        // look like it jumps instead of staying put.
        return _instantPage(const HadithLibraryScreen(), settings);
      case RouteNames.hadithLibraryList:
        return _page(const HadithLibraryListScreen(), settings);
      case RouteNames.hadithEbookList:
        return _page(const HadithEbookListScreen(), settings);
      case RouteNames.hadithPlanner:
        return _instantPage(const HadithPlannerScreen(), settings);
      case RouteNames.hadithCreatePlan:
        return MaterialPageRoute<String>(
          builder: (_) => const HadithCreatePlanScreen(),
          settings: settings,
        );
      case RouteNames.hadithEditPlan:
        final editArgs = settings.arguments;
        return MaterialPageRoute<bool>(
          builder: (_) => editArgs is HadithEditPlanArgs
              ? HadithEditPlanScreen(args: editArgs)
              : const HadithPlannerScreen(),
          settings: settings,
        );
      case RouteNames.hadithSaved:
        return _instantPage(const HadithSavedScreen(), settings);
      case RouteNames.hadithDashboard:
        return _instantPage(const HadithDashboardScreen(), settings);
      case RouteNames.hadithReadingHistory:
        return _page(const HadithReadingHistoryScreen(), settings);
      case RouteNames.hadithCategory:
        final args = settings.arguments;
        return _page(
          args is HadithCategoryArgs
              ? HadithCategoryScreen(
                  bookId: args.bookId,
                  collectionName: args.title,
                )
              : const HadithLibraryListScreen(),
          settings,
        );
      case RouteNames.hadithSubCategory:
        final subArgs = settings.arguments;
        return _page(
          subArgs is HadithSubCategoryArgs
              ? HadithSubCategoryScreen(
                  categoryId: subArgs.categoryId,
                  categoryName: subArgs.title,
                )
              : const HadithLibraryListScreen(),
          settings,
        );
      case RouteNames.hadithDetail:
        final detailArgs = settings.arguments;
        return _page(
          detailArgs is HadithDetailArgs
              ? HadithDetailScreen(
                  subCategoryId: detailArgs.subCategoryId,
                  bookId: detailArgs.bookId,
                  categoryId: detailArgs.categoryId,
                  planId: detailArgs.planId,
                  title: detailArgs.title,
                  initialHadithId: detailArgs.initialHadithId,
                  initialHadithNumber: detailArgs.initialHadithNumber,
                )
              : const HadithLibraryListScreen(),
          settings,
        );
      case RouteNames.hadithBookReader:
        final readerArgs = settings.arguments;
        final slug = readerArgs is HadithReaderArgs
            ? readerArgs.slug
            : readerArgs is String
            ? readerArgs
            : HadithBookCatalog.nawawi40.slug;
        final book =
            HadithBookCatalog.bySlug(slug) ?? HadithBookCatalog.nawawi40;
        return _page(
          BlocProvider(
            create: (_) =>
                HadithBookBloc(book: book)..add(const CheckHadithBook()),
            child: HadithBookReaderScreen(
              book: book,
              initialHadithNo: readerArgs is HadithReaderArgs
                  ? readerArgs.hadithNo
                  : null,
            ),
          ),
          settings,
        );
      case RouteNames.dua:
        return _page(const DuaIntroScreen(), settings);
      case RouteNames.duaDashboard:
        return _page(const DuaDashboardScreen(), settings);
      case RouteNames.duaAllCategory:
        return _page(const DuaAllCategoryScreen(), settings);
      case RouteNames.duaFeatured:
        return _page(const DuaFeaturedScreen(), settings);
      case RouteNames.duaGroup:
        final featured =
            settings.arguments as DuaFeatured? ?? DuaCatalog.featured.first;
        return _page(DuaGroupScreen(featured: featured), settings);
      case RouteNames.duaGroupAllDua:
        final featured =
            settings.arguments as DuaFeatured? ?? DuaCatalog.featured.first;
        return _page(DuaAllDuaScreen(featured: featured), settings);
      case RouteNames.duaReader:
        final args =
            settings.arguments as DuaReaderArgs? ?? DuaReaderArgs.fallback;
        return _page(DuaReaderScreen(args: args), settings);
      case RouteNames.duaSaved:
        return _page(const DuaSavedScreen(), settings);
      case RouteNames.zikr:
        return _page(const ZikrIntroScreen(), settings);
      case RouteNames.zikrDashboard:
        return _page(const ZikrDashboardScreen(), settings);
      case RouteNames.zikrCreate:
        return _page(const ZikrCreateScreen(), settings);
      case RouteNames.zikrSet:
        final items = settings.arguments;
        return _page(
          ZikrSetScreen(items: items is List<ZikrItem> ? items : const []),
          settings,
        );
      case RouteNames.zikrPlanner:
        return _page(const ZikrPlannerScreen(), settings);
      case RouteNames.zikrPlanCreate:
        return _page(const ZikrPlanCreateScreen(), settings);
      case RouteNames.zikrAll:
        return _page(const ZikrAllScreen(), settings);
      case RouteNames.zikrStats:
        return _page(const ZikrStatsScreen(), settings);
      case RouteNames.zikrCounter:
        final args =
            settings.arguments as ZikrCounterArgs? ?? ZikrCounterArgs.fallback;
        return _page(ZikrCounterScreen(args: args), settings);
      case RouteNames.splash:
        return _page(const RamadanSplashScreen(), settings);
      case RouteNames.signIn:
        return _page(const SignInScreen(), settings);
      case RouteNames.signUp:
        return _page(const SignupScreen(), settings);
      case RouteNames.forgotPassword:
        return _page(ForgotPasswordScreen(), settings);
      case RouteNames.emailVerification:
        return _page(const EmailVerificationScreen(), settings);
      case RouteNames.resetPassword:
        return _page(const ResetPasswordScreen(), settings);
      default:
        return _page(const SignInScreen(), settings);
    }
  }

  static Widget _surahListWithBlocs() {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => LastReadBloc()..add(const LoadLastRead())),
        BlocProvider(
          create: (_) => OfflineQuranBloc()..add(const CheckOfflineQuran()),
        ),
      ],
      child: const SurahListScreen(),
    );
  }

  static MaterialPageRoute<dynamic> _page(
    Widget child,
    RouteSettings settings,
  ) {
    return MaterialPageRoute<void>(builder: (_) => child, settings: settings);
  }

  /// Like [_page], but swaps in [child] immediately instead of animating —
  /// for routes that replace one another in place (e.g. a bottom-nav tab bar
  /// that must not appear to move).
  static PageRouteBuilder<dynamic> _instantPage(
    Widget child,
    RouteSettings settings,
  ) {
    return PageRouteBuilder<void>(
      settings: settings,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (_, _, _) => child,
    );
  }
}
