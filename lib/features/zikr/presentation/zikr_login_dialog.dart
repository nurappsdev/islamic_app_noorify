import 'package:flutter/material.dart';

import 'package:tuhfatul_muslim/core/constants/route_names.dart';
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
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Sign in required'),
      content: const Text('Please sign in to use your Tasbih and Zikr data.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(dialogContext).pop();
            Navigator.of(context).pushNamed(RouteNames.signIn);
          },
          child: const Text('Sign in'),
        ),
      ],
    ),
  );
}
