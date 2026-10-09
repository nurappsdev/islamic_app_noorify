import 'package:flutter/material.dart';

import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/features/auth/data/datasources/auth_local_data_source.dart';

/// Returns `true` only when the current device has a stored access token.
/// Use this before navigating to an action that cannot work while signed out.
Future<bool> requireZikrSignIn(BuildContext context) async {
  final token = AuthLocalDataSourceImpl().getToken();
  if (token != null && token.trim().isNotEmpty) return true;
  await showZikrLoginRequiredDialog(context);
  return false;
}

Future<void> showZikrLoginRequiredDialog(BuildContext context) async {
  if (!context.mounted) return;
  final appText = AppText.of(context);
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(appText.login),
      content: Text(appText.loginRequiredMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(appText.zikrCancel),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(dialogContext).pop();
            Navigator.of(context).pushNamed(RouteNames.signIn);
          },
          child: Text(appText.login),
        ),
      ],
    ),
  );
}
