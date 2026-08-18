import 'package:flutter/material.dart';

import '../../../../core/constants/route_names.dart';
import 'email_verification_screen.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return EmailVerificationScreen(
      onOtpVerified: () {
        Navigator.of(context).pushNamed(RouteNames.resetPassword);
      },
    );
  }
}
