import 'package:flutter/material.dart';

import 'package:tuhfatul_muslim/core/constants/route_names.dart';

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
