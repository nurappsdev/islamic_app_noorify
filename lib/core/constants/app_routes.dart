import 'package:flutter/material.dart';

import '../../features/auth/presentation/screens/email_verification_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/auth/presentation/screens/signin_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/home/presentation/screens/prayer_times_screen.dart';
import '../../features/quiz/presentation/screens/quiz_categories_screen.dart';
import '../../features/quiz/presentation/screens/quiz_question_screen.dart';
import '../../features/quiz/presentation/screens/quiz_completion_screen.dart';
import '../../features/quiz/presentation/screens/quiz_list_screen.dart';
import '../../features/learning/presentation/screens/learning_screen.dart';
import '../../features/quran/presentation/screens/quran_screen.dart';
import '../../features/splash/screens/ramadan_splash_screen.dart';
import 'route_names.dart';

class AppRoutes {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.home:
        return _page(const HomeScreen(), settings);
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
