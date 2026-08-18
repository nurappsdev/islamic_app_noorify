import 'package:flutter/material.dart';

import '../../features/auth/presentation/screens/email_verification_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/auth/presentation/screens/signin_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import 'route_names.dart';

class AppRoutes {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.home:
      case RouteNames.splash:
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
