import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tuhfatul_muslim/core/auth/auth_feature.dart';
import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/core/theme/theme_colors.dart';
import 'package:tuhfatul_muslim/core/utils/app_color.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:tuhfatul_muslim/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:tuhfatul_muslim/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:tuhfatul_muslim/features/auth/data/repositories/account_repository_impl.dart';
import 'package:tuhfatul_muslim/features/auth/data/services/google_auth_service.dart';
import 'package:tuhfatul_muslim/features/auth/presentation/widgets/google_sign_in_button.dart';
import 'package:tuhfatul_muslim/features/auth/domain/entities/google_sign_in_params.dart';
import 'package:tuhfatul_muslim/core/storage/session_cleaner.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/features/profile/data/services/profile_service.dart';
import 'package:tuhfatul_muslim/shared/services/app_globals.dart';
import 'package:tuhfatul_muslim/shared/services/firebase/firebase_token_service.dart';
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
  // Signing in with Google happens inside the dialog, so the gated feature
  // can go ahead straight away rather than making the user tap again.
  return isUserSignedIn;
}

/// What the user picked in the sign-in prompt.
enum _LoginChoice { notNow, signIn, googleSignedIn }

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
  final choice = await showGeneralDialog<_LoginChoice>(
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
            googleLabel: AuthPromptTexts.continueWithGoogle.resolve(language),
            language: language,
          ),
        ),
      );
    },
  );
  // Already signed in via Google inside the dialog — nothing left to open.
  if (choice == _LoginChoice.googleSignedIn) return true;
  if (choice != _LoginChoice.signIn) return false;
  navigator.pushNamed(RouteNames.signIn);
  return true;
}

class _LoginRequiredCard extends StatefulWidget {
  const _LoginRequiredCard({
    required this.title,
    required this.message,
    required this.noLabel,
    required this.loginLabel,
    required this.googleLabel,
    required this.language,
  });

  final String title;
  final String message;
  final String noLabel;
  final String loginLabel;
  final String googleLabel;
  final AppLanguage language;

  @override
  State<_LoginRequiredCard> createState() => _LoginRequiredCardState();
}

class _LoginRequiredCardState extends State<_LoginRequiredCard> {
  bool _googleBusy = false;

  /// Shown inside the card: a snackbar would be drawn behind the dialog's
  /// own barrier, where the user could not read it.
  String? _googleError;

  /// Signs in with Google without leaving the prompt. On success the dialog
  /// closes reporting [_LoginChoice.googleSignedIn], so the feature the user
  /// originally tapped can continue.
  Future<void> _signInWithGoogle() async {
    if (_googleBusy) return;
    setState(() {
      _googleBusy = true;
      _googleError = null;
    });
    final navigator = Navigator.of(context);
    final appText = AppText.forLanguage(widget.language);

    try {
      final google = await GoogleAuthService.instance.signIn();
      final fcmToken = await FirebaseTokenService.instance.getToken();
      final outcome = await AccountRepositoryImpl(AuthRemoteDataSourceImpl())
          .googleSignIn(
            GoogleSignInParams(
              idToken: google.idToken,
              email: google.email,
              displayName: google.displayName,
              photoUrl: google.photoUrl,
              fcmToken: fcmToken,
            ),
          );

      final failure = outcome.fold((f) => f, (_) => null);
      if (failure != null) {
        _show(failure.message);
        return;
      }

      // Match what the sign-in screen does on a successful login.
      await SessionCleaner.clearGuestAlarms();
      skipAuthGateNotifier.value = true;
      unawaited(saveAppPreferences());
      unawaited(ProfileService.instance.refresh());
      navigator.pop(_LoginChoice.googleSignedIn);
      return;
    } on GoogleSignInException catch (e) {
      _show(GoogleAuthService.messageFor(e, appText));
    } catch (_) {
      _show(appText.googleAuthErrorGeneric);
    } finally {
      if (mounted) setState(() => _googleBusy = false);
    }
  }

  /// A blank message means the user simply cancelled; nothing is shown.
  void _show(String message) {
    if (!mounted || message.trim().isEmpty) return;
    setState(() => _googleError = message);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.title;
    final message = widget.message;
    final noLabel = widget.noLabel;
    final loginLabel = widget.loginLabel;
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
                      blurRadius: 32.r,
                      offset: Offset(0, 14.h),
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
                            onPressed: _googleBusy
                                ? null
                                : () => Navigator.pop(
                                    context,
                                    _LoginChoice.notNow,
                                  ),
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
                                  blurRadius: 12.r,
                                  offset: Offset(0, 5.h),
                                ),
                              ],
                            ),
                            child: FilledButton.icon(
                              onPressed: _googleBusy
                                  ? null
                                  : () => Navigator.pop(
                                      context,
                                      _LoginChoice.signIn,
                                    ),
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
                    if (_googleError != null) ...[
                      SizedBox(height: 12.h),
                      Text(
                        _googleError!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFD93025),
                        ),
                      ),
                    ],
                    SizedBox(height: 12.h),
                    GoogleSignInButton(
                      key: const Key('login_required_google_button'),
                      label: widget.googleLabel,
                      isLoading: _googleBusy,
                      height: 48.h,
                      onPressed: _signInWithGoogle,
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
                    width: 5.r,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColor.authLogo.withValues(alpha: .45),
                      blurRadius: 18.r,
                      offset: Offset(0, 8.h),
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
