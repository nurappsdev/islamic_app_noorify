import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';

/// A centered error message + "Try Again" button, shown when a Dua screen's
/// API load fails.
class DuaErrorRetry extends StatelessWidget {
  const DuaErrorRetry({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                color: context.inkColor(Color(0xFF5D6B44)),
              ),
            ),
            TextButton(onPressed: onRetry, child: Text(appText.tryAgain)),
          ],
        ),
      ),
    );
  }
}
