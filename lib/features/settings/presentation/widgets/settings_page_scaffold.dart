import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/app_color.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';

/// The back-button-and-centred-title header the Settings sub-screens share,
/// matching the one the Settings and Profile screens already use.
class SettingsPageHeader extends StatelessWidget {
  const SettingsPageHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final appText = AppText.of(context);
    return SizedBox(
      height: 44.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              tooltip: appText.back,
              onPressed: () => Navigator.maybePop(context),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFDFDE68),
                foregroundColor: const Color(0xFF303629),
              ),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 52.w),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColor.primary,
                fontSize: 19.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (trailing != null)
            Align(alignment: Alignment.centerRight, child: trailing!),
        ],
      ),
    );
  }
}

/// The page frame for a Settings sub-screen: the app background, a safe
/// area, a [SettingsPageHeader] and [child] filling the rest.
class SettingsPageScaffold extends StatelessWidget {
  const SettingsPageScaffold({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.pageColor(Colors.white),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 0),
              child: SettingsPageHeader(title: title),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

/// The loading / failure states the Settings sub-screens share. [onRetry]
/// re-runs the request that failed.
class SettingsStateView extends StatelessWidget {
  const SettingsStateView({
    super.key,
    this.message,
    this.onRetry,
    this.isLoading = false,
  });

  final String? message;
  final VoidCallback? onRetry;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColor.primary),
      );
    }
    final appText = AppText.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message ?? appText.failureUnknown,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: context.inkColor(const Color(0xFF6B7551)),
              ),
            ),
            if (onRetry != null) ...[
              SizedBox(height: 12.h),
              TextButton(onPressed: onRetry, child: Text(appText.tryAgain)),
            ],
          ],
        ),
      ),
    );
  }
}

/// A card with the app's settings look: light surface, soft border, rounded.
class SettingsCard extends StatelessWidget {
  const SettingsCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: context.surfaceColor(Colors.white),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: context.lineColor(const Color(0xFFDDE8C1))),
      ),
      child: child,
    );
  }
}
