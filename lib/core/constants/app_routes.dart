import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/presentation/screens/email_verification_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/auth/presentation/screens/signin_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
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
import '../../features/quiz/presentation/cubit/quiz_cubit.dart';
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
import '../../features/quran/presentation/screens/quran_screen.dart';
import '../../features/splash/screens/ramadan_splash_screen.dart';
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
            create: (_) => QuizCubit(
              GetCompletedQuizHistory(
                QuizRepositoryImpl(const QuizLocalDataSourceImpl()),
              ),
            )..loadCompletedQuizHistory(),
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
      case RouteNames.prayerTimes:
        return _page(const PrayerTimesScreen(), settings);
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
