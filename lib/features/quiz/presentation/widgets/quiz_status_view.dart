import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/utils/app_text.dart';

/// A centred message for the quiz screens' error and empty states, with a
/// Try Again button when [onRetry] is given.
class QuizStatusView extends StatelessWidget {
  const QuizStatusView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              SizedBox(height: 12.h),
              OutlinedButton(
                onPressed: onRetry,
                child: Text(AppText.of(context).tryAgain),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
