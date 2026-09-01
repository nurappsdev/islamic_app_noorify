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
import '../../features/hadith/presentation/screens/hadith_intro_screen.dart';
import '../../features/hadith/presentation/screens/hadith_library_list_screen.dart';
import '../../features/hadith/presentation/screens/hadith_create_plan_screen.dart';
import '../../features/hadith/presentation/screens/hadith_dashboard_screen.dart';
import '../../features/hadith/presentation/screens/hadith_planner_screen.dart';
import '../../features/hadith/presentation/screens/hadith_reading_history_screen.dart';
import '../../features/hadith/presentation/screens/hadith_saved_screen.dart';
import '../../features/hadith/presentation/screens/hadith_library_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/home/presentation/screens/prayer_times_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/settings_screen.dart';
import '../../features/profile/presentation/screens/app_language_screen.dart';
import '../../features/profile/presentation/screens/family_members_screen.dart';
import '../../features/quiz/presentation/screens/quiz_categories_screen.dart';
import '../../features/quiz/presentation/screens/quiz_question_screen.dart';
import '../../features/quiz/presentation/screens/quiz_completion_screen.dart';
import '../../features/quiz/presentation/screens/quiz_list_screen.dart';
import '../../features/quiz/presentation/screens/completed_history_screen.dart';
import '../../features/quiz/data/datasources/quiz_local_data_source.dart';
import '../../features/quiz/data/repositories/quiz_repository_impl.dart';
import '../../features/quiz/domain/usecases/get_completed_quiz_history.dart';
import '../../features/quiz/presentation/bloc/quiz_bloc.dart';
import '../../features/learning/presentation/screens/learning_screen.dart';
import '../../features/planner/presentation/screens/planner_screen.dart';
import '../../features/planner/presentation/screens/planner_detail_screen.dart';
import '../../features/planner/presentation/screens/create_plan_screen.dart';
import '../../features/dashboard/presentation/screens/quiz_dashboard_screen.dart';
import '../../features/planner/presentation/models/planner_plan.dart';
import '../../features/learning/presentation/screens/articles_screen.dart';
import '../../features/learning/presentation/screens/article_details_screen.dart';
import '../../features/learning/presentation/screens/learning_test_screen.dart';
import '../../features/learning/presentation/screens/learning_test_result_screen.dart';
import '../../features/quran/presentation/quran_route_args.dart';
import '../../features/quran/presentation/screens/quran_screen.dart';
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
import '../../features/zikr/presentation/zikr_route_args.dart';
import 'route_names.dart';

class AppRoutes {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.home:
        return _page(const HomeScreen(), settings);
      case RouteNames.profile:
        return _page(const ProfileScreen(), settings);
      case RouteNames.settings:
        return _page(const SettingsScreen(), settings);
      case RouteNames.appLanguage:
        return _page(const AppLanguageScreen(), settings);
      case RouteNames.familyMembers:
        return _page(const FamilyMembersScreen(), settings);
      case RouteNames.winQuiz:
        return _page(const QuizCategoriesScreen(), settings);
      case RouteNames.quizQuestion:
        return _page(const QuizQuestionScreen(), settings);
      case RouteNames.quizComplete:
        return _page(const QuizCompletionScreen(), settings);
      case RouteNames.quizList:
        return _page(const QuizListScreen(), settings);
      case RouteNames.learning:
        return _page(const LearningScreen(), settings);
      case RouteNames.planner:
        return _page(const PlannerScreen(), settings);
      case RouteNames.plannerDetails:
        final plan =
            settings.arguments as PlannerPlan? ??
            const PlannerPlan(
              title: 'Plan 1',
              quizCount: 10,
              detailQuizCount: 4,
            );
        return _page(PlannerDetailScreen(plan: plan), settings);
      case RouteNames.createPlan:
        return _page(const CreatePlanScreen(), settings);
      case RouteNames.quizDashboard:
        return _page(const QuizDashboardScreen(), settings);
      case RouteNames.completedHistory:
        return _page(
          BlocProvider(
            create: (_) => QuizBloc(
              GetCompletedQuizHistory(
                QuizRepositoryImpl(const QuizLocalDataSourceImpl()),
              ),
            )..add(const LoadCompletedQuizHistory()),
            child: const CompletedHistoryScreen(),
          ),
          settings,
        );
      case RouteNames.learningArticles:
        return _page(const ArticlesScreen(), settings);
      case RouteNames.learningArticleDetails:
        return _page(const ArticleDetailsScreen(), settings);
      case RouteNames.learningTest:
        return _page(const LearningTestScreen(), settings);
      case RouteNames.learningTestResult:
        return _page(const LearningTestResultScreen(), settings);
      case RouteNames.quran:
        return _page(const QuranScreen(), settings);
      case RouteNames.quranSurahs:
        return _page(
          MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) => LastReadBloc()..add(const LoadLastRead()),
              ),
              BlocProvider(
                create: (_) =>
                    OfflineQuranBloc()..add(const CheckOfflineQuran()),
              ),
            ],
            child: const SurahListScreen(),
          ),
          settings,
        );
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
      case RouteNames.hadith:
        return _page(const HadithIntroScreen(), settings);
      case RouteNames.hadithLibrary:
        return _page(const HadithLibraryScreen(), settings);
      case RouteNames.hadithLibraryList:
        return _page(const HadithLibraryListScreen(), settings);
      case RouteNames.hadithPlanner:
        return _page(const HadithPlannerScreen(), settings);
      case RouteNames.hadithCreatePlan:
        return MaterialPageRoute<String>(
          builder: (_) => const HadithCreatePlanScreen(),
          settings: settings,
        );
      case RouteNames.hadithSaved:
        return _page(const HadithSavedScreen(), settings);
      case RouteNames.hadithDashboard:
        return _page(const HadithDashboardScreen(), settings);
      case RouteNames.hadithReadingHistory:
        return _page(const HadithReadingHistoryScreen(), settings);
      case RouteNames.hadithCategory:
        final title = settings.arguments is String
            ? settings.arguments as String
            : null;
        return _page(HadithCategoryScreen(collectionName: title), settings);
      case RouteNames.hadithBookReader:
        final slug = settings.arguments is String
            ? settings.arguments as String
            : HadithBookCatalog.nawawi40.slug;
        final book =
            HadithBookCatalog.bySlug(slug) ?? HadithBookCatalog.nawawi40;
        return _page(
          BlocProvider(
            create: (_) =>
                HadithBookBloc(book: book)..add(const CheckHadithBook()),
            child: HadithBookReaderScreen(book: book),
          ),
          settings,
        );
      case RouteNames.zikr:
        return _page(const ZikrIntroScreen(), settings);
      case RouteNames.zikrDashboard:
        return _page(const ZikrDashboardScreen(), settings);
      case RouteNames.zikrCreate:
        return _page(const ZikrCreateScreen(), settings);
      case RouteNames.zikrSet:
        final items = settings.arguments;
        return _page(
          ZikrSetScreen(
            items: items is List<ZikrItem> ? items : const [],
          ),
          settings,
        );
      case RouteNames.zikrPlanner:
        return _page(const ZikrPlannerScreen(), settings);
      case RouteNames.zikrPlanCreate:
        return _page(const ZikrPlanCreateScreen(), settings);
      case RouteNames.zikrAll:
        return _page(const ZikrAllScreen(), settings);
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
        return _page(const ForgotPasswordScreen(), settings);
      case RouteNames.emailVerification:
        return _page(const EmailVerificationScreen(), settings);
      case RouteNames.resetPassword:
        return _page(const ResetPasswordScreen(), settings);
      default:
        return _page(const SignInScreen(), settings);
    }
  }

  static MaterialPageRoute<dynamic> _page(
    Widget child,
    RouteSettings settings,
  ) {
    return MaterialPageRoute<void>(builder: (_) => child, settings: settings);
  }
}
