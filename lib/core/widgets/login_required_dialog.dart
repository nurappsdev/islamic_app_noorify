import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/auth/auth_feature.dart';
import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/app_color.dart';
import 'package:tuhfatul_muslim/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';

/// Whether a login token is stored (the user is signed in, not a guest).
bool get isUserSignedIn => AuthLocalDataSourceImpl().hasToken;

/// Gate for features whose API needs an access token. Returns `true` when the
/// user is signed in. For a guest it shows a sign-in prompt written for
/// [feature] (see [AuthFeatures]) - "Not now" stays where they are, "Sign in"
/// opens Sign In - and returns `false`.
///
/// ```dart
/// if (!await requireLogin(context, feature: AuthFeatures.quiz)) return;
/// ```
Future<bool> requireLogin(
  BuildContext context, {
  String feature = AuthFeatures.general,
}) async {
  if (isUserSignedIn) return true;
  await showLoginRequiredDialog(context, feature: feature);
  return false;
}

/// Shows the sign-in prompt for [feature] and, when the user picks "Sign in",
/// opens Sign In. Returns whether they picked it.
Future<bool> showLoginRequiredDialog(
  BuildContext context, {
  String feature = AuthFeatures.general,
}) async {
  final language = context.read<LanguageBloc>().state.language;
  final config = AuthFeatures.of(feature);
  final notNow = AuthPromptTexts.notNow.resolve(language);
  final navigator = Navigator.of(context);
  final login = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: notNow,
    barrierColor: Colors.black.withValues(alpha: .55),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (_, _, _) => const SizedBox.shrink(),
    transitionBuilder: (dialogContext, animation, _, _) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeIn,
      );
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: .85, end: 1).animate(curved),
          child: _LoginRequiredCard(
            title: config.featureName.resolve(language),
            message: config.messageFor(language),
            noLabel: notNow,
            loginLabel: AuthPromptTexts.signIn.resolve(language),
          ),
        ),
      );
    },
  );
  if (login != true) return false;
  navigator.pushNamed(RouteNames.signIn);
  return true;
}

class _LoginRequiredCard extends StatelessWidget {
  const _LoginRequiredCard({
    required this.title,
    required this.message,
    required this.noLabel,
    required this.loginLabel,
  });

  final String title;
  final String message;
  final String noLabel;
  final String loginLabel;

  @override
  Widget build(BuildContext context) {
    final ink = context.inkColor(AppColor.lightTextStrong);
    return Center(
      child: Material(
        type: MaterialType.transparency,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 330.w),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Container(
                margin: EdgeInsets.only(top: 38.h, left: 24.w, right: 24.w),
                padding: EdgeInsets.fromLTRB(22.w, 54.h, 22.w, 22.h),
                decoration: BoxDecoration(
                  color: context.surfaceColor(Colors.white),
                  borderRadius: BorderRadius.circular(28.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColor.primary.withValues(alpha: .35),
                      blurRadius: 32,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (title.isNotEmpty) ...[
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColor.authLogo,
                        ),
                      ),
                      SizedBox(height: 8.h),
                    ],
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16.sp,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                        color: ink,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context, false),
                            style: OutlinedButton.styleFrom(
                              minimumSize: Size.fromHeight(48.h),
                              foregroundColor: AppColor.authLogo,
                              side: const BorderSide(
                                color: AppColor.primary,
                                width: 1.4,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                            ),
                            child: Text(
                              noLabel,
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16.r),
                              gradient: const LinearGradient(
                                colors: [Color(0xFFB7C36B), AppColor.authLogo],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColor.authLogo.withValues(
                                    alpha: .4,
                                  ),
                                  blurRadius: 12,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: FilledButton.icon(
                              onPressed: () => Navigator.pop(context, true),
                              icon: Icon(Icons.login_rounded, size: 18.sp),
                              label: Text(
                                loginLabel,
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: FilledButton.styleFrom(
                                minimumSize: Size.fromHeight(48.h),
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16.r),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 76.w,
                height: 76.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFC5D077), AppColor.authLogo],
                  ),
                  border: Border.all(
                    color: context.surfaceColor(Colors.white),
                    width: 5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColor.authLogo.withValues(alpha: .45),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.lock_person_rounded,
                  color: Colors.white,
                  size: 36.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
