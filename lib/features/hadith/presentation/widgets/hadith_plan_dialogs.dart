import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:islami_app_noorify/core/theme/theme_colors.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';

/// Asks whether to delete the plan called [name]. True on "Delete".
Future<bool> showDeletePlanDialog(
  BuildContext context, {
  required String name,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final appText = AppText.of(dialogContext);
      return AlertDialog(
        backgroundColor: dialogContext.surfaceColor(Colors.white),
        title: Text(
          appText.planDeleteQuestion,
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
        content: Text(
          name,
          style: TextStyle(
            fontSize: 13.sp,
            color: dialogContext.inkColor(const Color(0xFF5D6B44)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(appText.planCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC15B4B),
            ),
            child: Text(appText.planDelete),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}

/// Asks whether to mark the plan called [name] as complete. True on
/// "Complete".
Future<bool> showCompletePlanDialog(
  BuildContext context, {
  required String name,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final appText = AppText.of(dialogContext);
      return AlertDialog(
        backgroundColor: dialogContext.surfaceColor(Colors.white),
        title: Text(
          appText.planCompleteQuestion,
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
        content: Text(
          name,
          style: TextStyle(
            fontSize: 13.sp,
            color: dialogContext.inkColor(const Color(0xFF5D6B44)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(appText.planCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF008000),
            ),
            child: Text(appText.planComplete),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}

