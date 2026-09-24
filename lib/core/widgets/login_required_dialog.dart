import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/auth/data/datasources/auth_local_data_source.dart';

/// Whether a login token is stored (the user is signed in, not a guest).
bool get hadithIsSignedIn => AuthLocalDataSourceImpl().hasToken;

/// Gate for Hadith features whose API needs an access token. Returns `true`
/// when the user is signed in. For a guest it shows the login dialog (No stays
/// on the screen, Login opens Sign In) and returns `false`.
Future<bool> ensureHadithLogin(BuildContext context) async {
  if (hadithIsSignedIn) return true;
  await showHadithLoginRequiredDialog(context);
  return false;
}

Future<void> showHadithLoginRequiredDialog(BuildContext context) async {
  final appText = AppText.readOf(context);
  final navigator = Navigator.of(context);
  final login = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      content: Text(
        appText.loginRequiredMessage,
        style: TextStyle(fontSize: 14.sp),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(appText.no),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(appText.login),
        ),
      ],
    ),
  );
  if (login == true) navigator.pushNamed(RouteNames.signIn);
}
